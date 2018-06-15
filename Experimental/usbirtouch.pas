{
Ultibo USB HID IR Touch Screen Driver.

Copyright (C) 2018 - SoftOz Pty Ltd.

Arch
====

 <All>

Boards
======

 <All>

Licence
=======

 LGPLv2.1 with static linking exception (See COPYING.modifiedLGPL.txt)
 
Credits
=======

 Information for this unit was obtained from:

References
==========

 USB HID Device Class Definition 1_11.pdf
 
   http://www.usb.org/developers/hidpage/HID1_11.pdf

 USB HID Usage Tables 1_12v2.pdf

   http://www.usb.org/developers/hidpage/Hut1_12v2.pdf
 
USB HID IR Touch Screen
========================

 This unit provides an experimental USB HID mouse driver for device AAEC:0922 Infrared Multi Touch Screen Product.

 The device also supports a multi touch interface which is not processed by this driver.
 
}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}

unit USBIRTouch;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,USB,Mouse,SysUtils;

{--$DEFINE USBIRTOUCH_DEBUG}

{==============================================================================}
const
 {USB IR Touch specific constants}
 USBIRTOUCH_DRIVER_NAME = 'USB IR Touch Driver'; {Name of USB IR Touch driver}

 USBIRTOUCH_MOUSE_DESCRIPTION = 'USB IR Touch'; {Description of USB IR Touch device}
 
 USBIRTOUCH_MAX_X = $7FFF;
 USBIRTOUCH_MAX_Y = $7FFF;
 
 USBIRTOUCH_BUTTON1 = (1 shl 0); {Button 1 Primary/trigger, Value = 0 to 1 (MOUSE_LEFT_BUTTON)}
 USBIRTOUCH_BUTTON2 = (1 shl 1); {Button 2 Secondary, Value = 0 to 1 (MOUSE_RIGHT_BUTTON)}
 USBIRTOUCH_BUTTON3 = (1 shl 2); {Button 3 Tertiary, Value = 0 to 1 (MOUSE_MIDDLE_BUTTON)}
 
 USBIRTOUCH_DEVICE_ID_COUNT = 1; {Number of supported Device IDs}
 
 USBIRTOUCH_DEVICE_ID:array[0..USBIRTOUCH_DEVICE_ID_COUNT - 1] of TUSBDeviceId = (
  (idVendor:$AAEC;idProduct:$0922)); 
 
 USBIRTOUCH_REPORT_ID = $03;
 
{==============================================================================}
type
 {USB IR Touch specific types}
 PUSBIRTouchInputReport = ^TUSBIRTouchInputReport;
 TUSBIRTouchInputReport = record
  ReportId:Byte;              {Report ID = 0x03 (3)}
  MousePointerButtons:Byte;   {Primary/trigger, Value = 0 to 1 / Secondary, Value = 0 to 1 / Tertiary, Value = 0 to 1}
  MousePointerX:Word;         {X, Value = 0 to 32767}
  MousePointerY:Word;         {Y, Value = 0 to 32767}
 end;
 
 PUSBIRTouchDevice = ^TUSBIRTouchDevice;
 TUSBIRTouchDevice = record
  {Mouse Properties}
  Mouse:TMouseDevice;
  {USB Properties}
  HIDInterface:PUSBInterface;            {USB IR Touch Interface}
  ReportRequest:PUSBRequest;             {USB request for mouse report data}
  ReportEndpoint:PUSBEndpointDescriptor; {USB Mouse Interrupt IN Endpoint}
  PendingCount:LongWord;                 {Number of USB requests pending for this mouse}
  WaiterThread:TThreadId;                {Thread waiting for pending requests to complete (for mouse detachment)}
 end;
  
{==============================================================================}
{var}
 {USB IR Touch specific variables}
 
{==============================================================================}
{Initialization Functions}
procedure USBIRTouchInit;

{==============================================================================}
{USB IR Touch Functions}
function USBIRTouchDeviceRead(Mouse:PMouseDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
function USBIRTouchDeviceControl(Mouse:PMouseDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;

function USBIRTouchDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
function USBIRTouchDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

procedure USBIRTouchReportWorker(Request:PUSBRequest); 
procedure USBIRTouchReportComplete(Request:PUSBRequest); 

{==============================================================================}
{USB IR Touch Helper Functions}
function USBIRTouchCheckDevice(Device:PUSBDevice):LongWord;

function USBIRTouchDeviceSetProtocol(Mouse:PUSBIRTouchDevice;Protocol:Byte):LongWord;

{==============================================================================}
{==============================================================================}

implementation
 
{==============================================================================}
{==============================================================================}
var
 {USB IR Touch specific variables}
 USBIRTouchInitialized:Boolean;
 
 USBIRTouchDriver:PUSBDriver;  {USB IR Touch Driver interface (Set by USBIRTouchInit)}

{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure USBIRTouchInit;
{Initialize the USB IR Touch driver}

{Note: Called only during system startup}
var
 Status:LongWord;
begin
 {}
 {Check Initialized}
 if USBIRTouchInitialized then Exit;

 {Create USB IR Touch Driver}
 USBIRTouchDriver:=USBDriverCreate;
 if USBIRTouchDriver <> nil then
  begin
   {Update USB IR Touch Driver}
   {Driver}
   USBIRTouchDriver.Driver.DriverName:=USBIRTOUCH_DRIVER_NAME; 
   {USB}
   USBIRTouchDriver.DriverBind:=USBIRTouchDriverBind;
   USBIRTouchDriver.DriverUnbind:=USBIRTouchDriverUnbind;
   
   {Register USB IR Touch Driver}
   Status:=USBDriverRegister(USBIRTouchDriver); 
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'USB IR Touch: Failed to register USB IR Touch driver: ' + USBStatusToString(Status));
    end;
  end
 else
  begin
   if MOUSE_LOG_ENABLED then MouseLogError(nil,'Failed to create USB IR Touch driver');
  end;

 USBIRTouchInitialized:=True;
end;

{==============================================================================}
{==============================================================================}
{USB IR Touch Functions}
function USBIRTouchDeviceRead(Mouse:PMouseDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord; 
{Implementation of MouseDeviceRead API for USB IR Touch}
{Note: Not intended to be called directly by applications, use MouseDeviceRead instead}
var
 Offset:PtrUInt;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;
 
 {Check Mouse}
 if Mouse = nil then Exit;
 if Mouse.Device.Signature <> DEVICE_SIGNATURE then Exit;
 
 {Check Buffer}
 if Buffer = nil then Exit;
 
 {Check Size}
 if Size < SizeOf(TMouseData) then Exit;
 
 {Check Mouse Attached}
 if Mouse.MouseState <> MOUSE_STATE_ATTACHED then Exit;
 
 {$IFDEF USBIRTOUCH_DEBUG}
 if MOUSE_LOG_ENABLED then MouseLogDebug(Mouse,'Attempting to read ' + IntToStr(Size) + ' bytes from mouse');
 {$ENDIF}
 
 {Read to Buffer}
 Count:=0;
 Offset:=0;
 while Size >= SizeOf(TMouseData) do
  begin
   {Check Non Blocking}
   if ((Mouse.Device.DeviceFlags and MOUSE_FLAG_NON_BLOCK) <> 0) and (Mouse.Buffer.Count = 0) then
    begin
     if Count = 0 then Result:=ERROR_NO_MORE_ITEMS;
     Break;
    end;

   {Wait for Mouse Data}
   if SemaphoreWait(Mouse.Buffer.Wait) = ERROR_SUCCESS then
    begin
     {Acquire the Lock}
     if MutexLock(Mouse.Lock) = ERROR_SUCCESS then
      begin
       try
        {Copy Data}
        PMouseData(PtrUInt(Buffer) + Offset)^:=Mouse.Buffer.Buffer[Mouse.Buffer.Start];
          
        {Update Start}
        Mouse.Buffer.Start:=(Mouse.Buffer.Start + 1) mod MOUSE_BUFFER_SIZE;
        
        {Update Count}
        Dec(Mouse.Buffer.Count);
  
        {Update Count}
        Inc(Count);
          
        {Update Size and Offset}
        Dec(Size,SizeOf(TMouseData));
        Inc(Offset,SizeOf(TMouseData));
       finally
        {Release the Lock}
        MutexUnlock(Mouse.Lock);
       end;
      end
     else
      begin
       Result:=ERROR_CAN_NOT_COMPLETE;
       Exit;
      end;
    end  
   else
    begin
     Result:=ERROR_CAN_NOT_COMPLETE;
     Exit;
    end;
   
   {Return Result}
   Result:=ERROR_SUCCESS;
  end;
  
 {$IFDEF USBIRTOUCH_DEBUG}
 if MOUSE_LOG_ENABLED then MouseLogDebug(Mouse,'Return count=' + IntToStr(Count));
 {$ENDIF}
end;
 
{==============================================================================}

function USBIRTouchDeviceControl(Mouse:PMouseDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;
{Implementation of MouseDeviceControl API for USB IR Touch}
{Note: Not intended to be called directly by applications, use MouseDeviceControl instead}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;
 
 {Check Mouse}
 if Mouse = nil then Exit;
 if Mouse.Device.Signature <> DEVICE_SIGNATURE then Exit; 
 
 {Check Mouse Attached}
 if Mouse.MouseState <> MOUSE_STATE_ATTACHED then Exit;
 
 {Acquire the Lock}
 if MutexLock(Mouse.Lock) = ERROR_SUCCESS then
  begin
   try
    case Request of
     MOUSE_CONTROL_GET_FLAG:begin
       {Get Flag}
       LongBool(Argument2):=False;
       if (Mouse.Device.DeviceFlags and Argument1) <> 0 then
        begin
         LongBool(Argument2):=True;
         
         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     MOUSE_CONTROL_SET_FLAG:begin 
       {Set Flag}
       if (Argument1 and not(MOUSE_FLAG_MASK)) = 0 then
        begin
         Mouse.Device.DeviceFlags:=(Mouse.Device.DeviceFlags or Argument1);
       
         {Return Result}
         Result:=ERROR_SUCCESS;
        end; 
      end;
     MOUSE_CONTROL_CLEAR_FLAG:begin 
       {Clear Flag}
       if (Argument1 and not(MOUSE_FLAG_MASK)) = 0 then
        begin
         Mouse.Device.DeviceFlags:=(Mouse.Device.DeviceFlags and not(Argument1));
       
         {Return Result}
         Result:=ERROR_SUCCESS;
        end; 
      end;
     MOUSE_CONTROL_FLUSH_BUFFER:begin
       {Flush Buffer}
       while Mouse.Buffer.Count > 0 do 
        begin
         {Wait for Data (Should not Block)}
         if SemaphoreWait(Mouse.Buffer.Wait) = ERROR_SUCCESS then
          begin
           {Update Start}
           Mouse.Buffer.Start:=(Mouse.Buffer.Start + 1) mod MOUSE_BUFFER_SIZE;
           
           {Update Count}
           Dec(Mouse.Buffer.Count);
          end
         else
          begin
           Result:=ERROR_CAN_NOT_COMPLETE;
           Exit;
          end;
        end;
        
       {Return Result} 
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_SAMPLE_RATE:begin
       {Get Sample Rate}
       Argument2:=Mouse.MouseRate;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;
     MOUSE_CONTROL_SET_SAMPLE_RATE:begin
       {Set Sample Rate}
       Mouse.MouseRate:=Argument1;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_MAX_X:begin
       {Get Maximum X}
       Argument2:=USBIRTOUCH_MAX_X;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_MAX_Y:begin
       {Get Maximum Y}
       Argument2:=USBIRTOUCH_MAX_Y;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_MAX_WHEEL:begin
       {Get Maximum Wheel}
       Argument2:=0;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_MAX_BUTTONS:begin
       {Get Maximum Buttons mask}
       Argument2:=MOUSE_LEFT_BUTTON or MOUSE_RIGHT_BUTTON or MOUSE_MIDDLE_BUTTON or MOUSE_ABSOLUTE_X or MOUSE_ABSOLUTE_Y;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
    end;
   finally
    {Release the Lock}
    MutexUnlock(Mouse.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
   Exit;
  end;
end;
 
{==============================================================================}
 
function USBIRTouchDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Bind the USB IR Touch driver to a USB device if it is suitable}
{Device: The USB device to attempt to bind to}
{Interrface: The USB interface to attempt to bind to (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed, USB_STATUS_DEVICE_UNSUPPORTED if unsupported or another error code on failure}
var
 Status:LongWord;
 Interval:LongWord;
 Mouse:PUSBIRTouchDevice;
 ReportEndpoint:PUSBEndpointDescriptor;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;
                        
 {$IFDEF USBIRTOUCH_DEBUG}                       
 if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Attempting to bind USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}
 
 {Check Interface (Bind to interface only)}
 if Interrface = nil then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Check for Mouse (Must be interface specific)}
 if Device.Descriptor.bDeviceClass <> USB_CLASS_CODE_INTERFACE_SPECIFIC then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;   
  end;
  
 {Check Interface (Must be HID class)}
 if Interrface.Descriptor.bInterfaceClass <> USB_CLASS_CODE_HID then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;   
  end;
 
 {Check Endpoint (Must be IN interrupt)}
 ReportEndpoint:=USBDeviceFindEndpointByType(Device,Interrface,USB_DIRECTION_IN,USB_TRANSFER_TYPE_INTERRUPT);
 if ReportEndpoint = nil then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Check USB IR Touch Device}
 if USBIRTouchCheckDevice(Device) <> USB_STATUS_SUCCESS then
  begin
   {$IFDEF USBIRTOUCH_DEBUG}                       
   if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Device not found in supported device list');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Create Mouse}
 Mouse:=PUSBIRTouchDevice(MouseDeviceCreateEx(SizeOf(TUSBIRTouchDevice)));
 if Mouse = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'USB IR Touch: Failed to create new mouse device');
   
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Update Mouse} 
 {Device}
 Mouse.Mouse.Device.DeviceBus:=DEVICE_BUS_USB;
 Mouse.Mouse.Device.DeviceType:=MOUSE_TYPE_USB;
 Mouse.Mouse.Device.DeviceFlags:=Mouse.Mouse.Device.DeviceFlags; {Don't override defaults (was MOUSE_FLAG_NONE)}
 Mouse.Mouse.Device.DeviceData:=Device;
 Mouse.Mouse.Device.DeviceDescription:=USBIRTOUCH_MOUSE_DESCRIPTION;
 {Mouse}
 Mouse.Mouse.MouseState:=MOUSE_STATE_ATTACHING;
 Mouse.Mouse.DeviceRead:=USBIRTouchDeviceRead;
 Mouse.Mouse.DeviceControl:=USBIRTouchDeviceControl;
 {Driver}
 {USB}
 Mouse.HIDInterface:=Interrface;
 Mouse.ReportEndpoint:=ReportEndpoint;
 Mouse.WaiterThread:=INVALID_HANDLE_VALUE;
 
 {Allocate Report Request}
 Mouse.ReportRequest:=USBRequestAllocate(Device,ReportEndpoint,USBIRTouchReportComplete,ReportEndpoint.wMaxPacketSize,Mouse);
 if Mouse.ReportRequest = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'USB IR Touch: Failed to allocate USB report request for mouse');

   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Register Mouse} 
 if MouseDeviceRegister(@Mouse.Mouse) <> ERROR_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'USB IR Touch: Failed to register new mouse device');
   
   {Release Report Request}
   USBRequestRelease(Mouse.ReportRequest);
   
   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);
   
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {$IFDEF USBIRTOUCH_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Enabling HID report protocol');
 {$ENDIF}

 {Set Report Protocol}
 Status:=USBIRTouchDeviceSetProtocol(Mouse,USB_HID_PROTOCOL_REPORT);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'USB IR Touch: Failed to enable HID report protocol: ' + USBStatusToString(Status));

   {Release Report Request}
   USBRequestRelease(Mouse.ReportRequest);
   
   {Deregister Mouse}
   MouseDeviceDeregister(@Mouse.Mouse);
   
   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);
   
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Check Endpoint Interval}
 if USB_MOUSE_POLLING_INTERVAL > 0 then
  begin
   {Check Device Speed}
   if Device.Speed = USB_SPEED_HIGH then
    begin
     {Get Interval}
     Interval:=FirstBitSet(USB_MOUSE_POLLING_INTERVAL * USB_UFRAMES_PER_MS) + 1;
     
     {Ensure no less than Interval} {Milliseconds = (1 shl (bInterval - 1)) div USB_UFRAMES_PER_MS}
     if ReportEndpoint.bInterval < Interval then ReportEndpoint.bInterval:=Interval;
    end
   else
    begin
     {Ensure no less than USB_MOUSE_POLLING_INTERVAL} {Milliseconds = bInterval div USB_FRAMES_PER_MS}
     if ReportEndpoint.bInterval < USB_MOUSE_POLLING_INTERVAL then ReportEndpoint.bInterval:=USB_MOUSE_POLLING_INTERVAL;
    end;  
  end;  
  
 {Update Interface}
 Interrface.DriverData:=Mouse;
 
 {Update Pending}
 Inc(Mouse.PendingCount);
 
 {$IFDEF USBIRTOUCH_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Submitting report request');
 {$ENDIF}
 
 {Submit Request}
 Status:=USBRequestSubmit(Mouse.ReportRequest);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'USB IR Touch: Failed to submit report request: ' + USBStatusToString(Status));
   
   {Update Pending}
   Dec(Mouse.PendingCount);
   
   {Release Report Request}
   USBRequestRelease(Mouse.ReportRequest);
   
   {Deregister Mouse}
   MouseDeviceDeregister(@Mouse.Mouse);
   
   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);
   
   {Return Result}
   Result:=Status;
   Exit;
  end;  
 
 {Set State to Attached}
 if MouseDeviceSetState(@Mouse.Mouse,MOUSE_STATE_ATTACHED) <> ERROR_SUCCESS then Exit;
 
 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;
 
{==============================================================================}
 
function USBIRTouchDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Unbind the USB IR Touch driver from a USB device}
{Device: The USB device to unbind from}
{Interrface: The USB interface to unbind from (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Message:TMessage;
 Mouse:PUSBIRTouchDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface = nil then Exit;
 
 {Check Driver}
 if Interrface.Driver <> USBIRTouchDriver then Exit;
 
 {$IFDEF USBIRTOUCH_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Unbinding USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}
 
 {Get Mouse}
 Mouse:=PUSBIRTouchDevice(Interrface.DriverData);
 if Mouse = nil then Exit;
 if Mouse.Mouse.Device.Signature <> DEVICE_SIGNATURE then Exit;
 
 {Set State to Detaching}
 Result:=USB_STATUS_OPERATION_FAILED;
 if MouseDeviceSetState(@Mouse.Mouse,MOUSE_STATE_DETACHING) <> ERROR_SUCCESS then Exit;

 {Acquire the Lock}
 if MutexLock(Mouse.Mouse.Lock) <> ERROR_SUCCESS then Exit;
 
 {Cancel Report Request}
 USBRequestCancel(Mouse.ReportRequest);
 
 {Check Pending}
 if Mouse.PendingCount <> 0 then
  begin
   {$IFDEF USBIRTOUCH_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'USB IR Touch: Waiting for ' + IntToStr(Mouse.PendingCount) + ' pending requests to complete');
   {$ENDIF}
  
   {Wait for Pending}
   
   {Setup Waiter}
   Mouse.WaiterThread:=GetCurrentThreadId; 
   
   {Release the Lock}
   MutexUnlock(Mouse.Mouse.Lock);
   
   {Wait for Message}
   ThreadReceiveMessage(Message); 
  end
 else
  begin
   {Release the Lock}
   MutexUnlock(Mouse.Mouse.Lock);
  end;  
 
 {Set State to Detached}
 if MouseDeviceSetState(@Mouse.Mouse,MOUSE_STATE_DETACHED) <> ERROR_SUCCESS then Exit;
 
 {Update Interface}
 Interrface.DriverData:=nil; 

 {Release Report Request}
 USBRequestRelease(Mouse.ReportRequest);

 {Deregister Mouse}
 if MouseDeviceDeregister(@Mouse.Mouse) <> ERROR_SUCCESS then Exit;
 
 {Destroy Mouse}
 MouseDeviceDestroy(@Mouse.Mouse);
 
 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;
 
{==============================================================================}

procedure USBIRTouchReportWorker(Request:PUSBRequest); 
{Called (by a Worker thread) to process a completed USB request from the USB IR Touch IN interrupt endpoint}
{Request: The USB request which has completed}
var
 Data:TMouseData;
 Status:LongWord;
 Message:TMessage;
 Mouse:PUSBIRTouchDevice;
 Report:PUSBIRTouchInputReport;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Mouse}
 Mouse:=PUSBIRTouchDevice(Request.DriverData);
 if Mouse <> nil then
  begin
   {Acquire the Lock}
   if MutexLock(Mouse.Mouse.Lock) = ERROR_SUCCESS then
    begin
     try
      {Update Statistics}
      Inc(Mouse.Mouse.ReceiveCount); 
      
      {Check State}
      if Mouse.Mouse.MouseState = MOUSE_STATE_DETACHING then
       begin
        {$IFDEF USBIRTOUCH_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'USB IR Touch: Detachment pending, setting report request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}
        
        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;
 
      {Check Result}
      if Request.Status = USB_STATUS_SUCCESS then  
       begin
        {A report was received from the USB mouse}
        Report:=Request.Data;

        {$IFDEF USBIRTOUCH_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'USB IR Touch: Report received (ReportId=' + IntToStr(Report.ReportId) + ')'); 
        {$ENDIF}
        
        {Check Report}
        if Report.ReportId = USBIRTOUCH_REPORT_ID then
         begin
          {Check Size}
          if Request.ActualSize >= SizeOf(TUSBIRTouchInputReport) then
           begin
            {Get Buttons}
            Data.Buttons:=MOUSE_ABSOLUTE_X or MOUSE_ABSOLUTE_Y;
            
            {Check Button1}
            if (Report.MousePointerButtons and USBIRTOUCH_BUTTON1) <> 0 then
             begin
              {Check Flags}
              if (Mouse.Mouse.Device.DeviceFlags and MOUSE_FLAG_SWAP_BUTTONS) = 0 then
               begin
                Data.Buttons:=Data.Buttons or MOUSE_LEFT_BUTTON;
               end
              else
               begin
                Data.Buttons:=Data.Buttons or MOUSE_RIGHT_BUTTON;
               end;
             end;
            
            {Check Button2} 
            if (Report.MousePointerButtons and USBIRTOUCH_BUTTON2) <> 0 then
             begin
              {Check Flags}
              if (Mouse.Mouse.Device.DeviceFlags and MOUSE_FLAG_SWAP_BUTTONS) = 0 then
               begin
                Data.Buttons:=Data.Buttons or MOUSE_RIGHT_BUTTON;
               end
              else
               begin
                Data.Buttons:=Data.Buttons or MOUSE_LEFT_BUTTON;
               end;
             end; 
            
            {Check Button3} 
            if (Report.MousePointerButtons and USBIRTOUCH_BUTTON3) <> 0 then Data.Buttons:=Data.Buttons or MOUSE_MIDDLE_BUTTON;
            
            {Get X offset}
            Data.OffsetX:=Report.MousePointerX;
    
            {Get Y offset}
            Data.OffsetY:=Report.MousePointerY;
    
            {Get Wheel offset}
            Data.OffsetWheel:=0;
            
            {Maximum X, Y and Wheel}
            Data.MaximumX:=USBIRTOUCH_MAX_X;
            Data.MaximumY:=USBIRTOUCH_MAX_Y;
            Data.MaximumWheel:=0;
            
            {Insert Data}
            MouseInsertData(@Mouse.Mouse,@Data,True);
           end
          else
           begin
            if USB_LOG_ENABLED then USBLogError(Request.Device,'USB IR Touch: Report invalid (ActualSize=' + IntToStr(Request.ActualSize) + ')'); 
            
            {Update Statistics}
            Inc(Mouse.Mouse.ReceiveErrors); 
           end;
         end;
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'USB IR Touch: Failed report request (Status=' + USBStatusToString(Request.Status) + ')'); 
        
        {Update Statistics}
        Inc(Mouse.Mouse.ReceiveErrors); 
       end;       

      {Update Pending}
      Dec(Mouse.PendingCount); 
       
      {Check State}
      if Mouse.Mouse.MouseState = MOUSE_STATE_DETACHING then
       begin
        {Check Pending}
        if Mouse.PendingCount = 0 then
         begin
          {Check Waiter}
          if Mouse.WaiterThread <> INVALID_HANDLE_VALUE then
           begin
            {$IFDEF USBIRTOUCH_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'USB IR Touch: Detachment pending, sending message to waiter thread (Thread=' + IntToHex(Mouse.WaiterThread,8) + ')');
            {$ENDIF}
            
            {Send Message}
            FillChar(Message,SizeOf(TMessage),0);
            ThreadSendMessage(Mouse.WaiterThread,Message);
            Mouse.WaiterThread:=INVALID_HANDLE_VALUE;
           end; 
         end;
       end
      else
       begin      
        {Update Pending}
        Inc(Mouse.PendingCount);
      
        {$IFDEF USBIRTOUCH_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'USB IR Touch: Resubmitting report request');
        {$ENDIF}

        {Resubmit Request}
        Status:=USBRequestSubmit(Request);
        if Status <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'USB IR Touch: Failed to resubmit report request: ' + USBStatusToString(Status));
   
          {Update Pending}
          Dec(Mouse.PendingCount);
         end;
       end;  
     finally
      {Release the Lock}
      MutexUnlock(Mouse.Mouse.Lock);
     end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(Request.Device,'USB IR Touch: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'USB IR Touch: Report request invalid');
  end;    
end;
 
{==============================================================================}
 
procedure USBIRTouchReportComplete(Request:PUSBRequest);
{Called when a USB request from the USB IR Touch IN interrupt endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;
 
 WorkerSchedule(0,TWorkerTask(USBIRTouchReportWorker),Request,nil)
end;
 
{==============================================================================}
{==============================================================================}
{USB IR Touch Helper Functions}
function USBIRTouchCheckDevice(Device:PUSBDevice):LongWord;
{Check the Vendor and Device ID against the supported devices}
{Device: USB device to check}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}      
var
 Count:Integer;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;
 
 {Check Device ID and Interface}
 for Count:=0 to USBIRTOUCH_DEVICE_ID_COUNT - 1 do
  begin
   if (USBIRTOUCH_DEVICE_ID[Count].idVendor = Device.Descriptor.idVendor) and (USBIRTOUCH_DEVICE_ID[Count].idProduct = Device.Descriptor.idProduct) then
    begin
     Result:=USB_STATUS_SUCCESS;
     Exit;
    end;
  end;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function USBIRTouchDeviceSetProtocol(Mouse:PUSBIRTouchDevice;Protocol:Byte):LongWord;
{Set the report protocol for the USB IR Touch device}
{Mouse: The USB IR Touch device to set the report protocol for}
{Protocol: The report protocol to set (eg USB_HID_PROTOCOL_BOOT)}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Mouse}
 if Mouse = nil then Exit;
 
 {Check Interface}
 if Mouse.HIDInterface = nil then Exit;
 
 {Get Device}
 Device:=PUSBDevice(Mouse.Mouse.Device.DeviceData);
 if Device = nil then Exit;
 
 {Set Protocol}
 Result:=USBControlRequest(Device,nil,USB_HID_REQUEST_SET_PROTOCOL,USB_BMREQUESTTYPE_TYPE_CLASS or USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,Protocol,Mouse.HIDInterface.Descriptor.bInterfaceNumber,nil,0);
end;

{==============================================================================}
{==============================================================================}

initialization
 USBIRTouchInit;

{==============================================================================}
 
finalization
 {Nothing}
 
{==============================================================================}
{==============================================================================}

end.
