{
Ultibo HID PS/2 to USB Converter Mouse Driver.

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
 
HID USB to PS/2 Converter Mouse
===============================

 This unit provides a USB HID mouse driver for device 13BA:0017 interface 1 USB Mouse (PCPlay)
 
}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}

unit USBPS2Converter;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,USB,Mouse,SysUtils;

{==============================================================================}
const
 {HID Mouse specific constants}
 HIDMOUSE_DRIVER_NAME = 'HID PS/2 to USB Mouse Driver'; {Name of HID driver}

 HIDMOUSE_MOUSE_DESCRIPTION = 'PCPlay HID PS/2 Mouse'; {Description of HID mouse device}
 
 HIDMOUSE_BUTTON1 = (1 shl 0); {Button 1 Primary/trigger, Value = 0 to 1 (MOUSE_LEFT_BUTTON)}
 HIDMOUSE_BUTTON2 = (1 shl 1); {Button 2 Secondary, Value = 0 to 1 (MOUSE_RIGHT_BUTTON)}
 HIDMOUSE_BUTTON3 = (1 shl 2); {Button 3 Tertiary, Value = 0 to 1 (MOUSE_MIDDLE_BUTTON)}
 
 HIDMOUSE_DEVICE_ID_COUNT = 1; {Number of supported Device IDs}
 
 HIDMOUSE_DEVICE_ID:array[0..HIDMOUSE_DEVICE_ID_COUNT - 1] of TUSBDeviceAndInterfaceNo = (
  (idVendor:$13BA;idProduct:$0017;bInterfaceNumber:1)); 
 
 HIDMOUSE_REPORT_ID = 1;
 
{==============================================================================}
type
 {HID Mouse specific types}
 PHIDMouseInputReport = ^THIDMouseInputReport;
 THIDMouseInputReport = record
  ReportId:Byte;              {Report ID = 0x01 (1)}
  MousePointerButtons:Byte;   {Primary/trigger, Value = 0 to 1 / Secondary, Value = 0 to 1 / Tertiary, Value = 0 to 1}
  MousePointerX:Shortint;     {X, Value = -127 to 127}
  MousePointerY:Shortint;     {Y, Value = -127 to 127}
  MousePointerWheel:Shortint; {Wheel, Value = -127 to 127}
 end;
 
 PHIDMouseDevice = ^THIDMouseDevice;
 THIDMouseDevice = record
  {Mouse Properties}
  Mouse:TMouseDevice;
  {USB Properties}
  HIDInterface:PUSBInterface;            {USB HID Mouse Interface}
  ReportRequest:PUSBRequest;             {USB request for mouse report data}
  ReportEndpoint:PUSBEndpointDescriptor; {USB Mouse Interrupt IN Endpoint}
  PendingCount:LongWord;                 {Number of USB requests pending for this mouse}
  WaiterThread:TThreadId;                {Thread waiting for pending requests to complete (for mouse detachment)}
 end;
  
{==============================================================================}
{var}
 {HID Mouse specific variables}
 
{==============================================================================}
{Initialization Functions}
procedure HIDMouseInit;

{==============================================================================}
{HID Mouse Functions}
function HIDMouseDeviceRead(Mouse:PMouseDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord; 
function HIDMouseDeviceControl(Mouse:PMouseDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;

function HIDMouseDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
function HIDMouseDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

procedure HIDMouseReportWorker(Request:PUSBRequest); 
procedure HIDMouseReportComplete(Request:PUSBRequest); 

{==============================================================================}
{HID Mouse Helper Functions}
function HIDMouseCheckDeviceAndInterface(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

function HIDMouseDeviceSetProtocol(Mouse:PHIDMouseDevice;Protocol:Byte):LongWord;

{==============================================================================}
{==============================================================================}

implementation
 
{==============================================================================}
{==============================================================================}
var
 {HID Mouse specific variables}
 HIDMouseInitialized:Boolean;
 
 HIDMouseDriver:PUSBDriver;  {HID Mouse Driver interface (Set by HIDMouseInit)}

{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure HIDMouseInit;
{Initialize the mouse unit, device table and USB mouse driver}

{Note: Called only during system startup}
var
 Status:LongWord;
begin
 {}
 {Check Initialized}
 if HIDMouseInitialized then Exit;

 {Create HID Mouse Driver}
 HIDMouseDriver:=USBDriverCreate;
 if HIDMouseDriver <> nil then
  begin
   {Update HID Mouse Driver}
   {Driver}
   HIDMouseDriver.Driver.DriverName:=HIDMOUSE_DRIVER_NAME; 
   {USB}
   HIDMouseDriver.DriverBind:=HIDMouseDriverBind;
   HIDMouseDriver.DriverUnbind:=HIDMouseDriverUnbind;
   
   {Register HID Mouse Driver}
   Status:=USBDriverRegister(HIDMouseDriver); 
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'HID Mouse: Failed to register HID mouse driver: ' + USBStatusToString(Status));
    end;
  end
 else
  begin
   if MOUSE_LOG_ENABLED then MouseLogError(nil,'Failed to create HID mouse driver');
  end;

 HIDMouseInitialized:=True;
end;

{==============================================================================}
{==============================================================================}
{HID Mouse Functions}
function HIDMouseDeviceRead(Mouse:PMouseDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord; 
{Implementation of MouseDeviceRead API for HID Mouse}
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
 
 {$IFDEF MOUSE_DEBUG}
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
  
 {$IFDEF MOUSE_DEBUG}
 if MOUSE_LOG_ENABLED then MouseLogDebug(Mouse,'Return count=' + IntToStr(Count));
 {$ENDIF}
end;
 
{==============================================================================}

function HIDMouseDeviceControl(Mouse:PMouseDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;
{Implementation of MouseDeviceControl API for HID Mouse}
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
       Argument2:=0;
       
       {Return Result}
       Result:=ERROR_SUCCESS;
      end;       
     MOUSE_CONTROL_GET_MAX_Y:begin
       {Get Maximum Y}
       Argument2:=0;
       
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
       Argument2:=MOUSE_LEFT_BUTTON or MOUSE_RIGHT_BUTTON or MOUSE_MIDDLE_BUTTON;
       
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
 
function HIDMouseDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Bind the Mouse driver to a USB device if it is suitable}
{Device: The USB device to attempt to bind to}
{Interrface: The USB interface to attempt to bind to (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed, USB_STATUS_DEVICE_UNSUPPORTED if unsupported or another error code on failure}
var
 Status:LongWord;
 Interval:LongWord;
 Mouse:PHIDMouseDevice;
 ReportEndpoint:PUSBEndpointDescriptor;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;
                        
 {$IFDEF USB_DEBUG}                       
 if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Attempting to bind USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}
 
 {Check Interface (Bind to interface only)}
 if Interrface = nil then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {Check HID Mouse Device}
 if HIDMouseCheckDeviceAndInterface(Device,Interrface) <> USB_STATUS_SUCCESS then
  begin
   {$IFDEF USB_DEBUG}                       
   if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Device not found in supported device list');
   {$ENDIF}
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
 
 {Create Mouse}
 Mouse:=PHIDMouseDevice(MouseDeviceCreateEx(SizeOf(THIDMouseDevice)));
 if Mouse = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'HID Mouse: Failed to create new mouse device');
   
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
 Mouse.Mouse.Device.DeviceDescription:=HIDMOUSE_MOUSE_DESCRIPTION;
 {Mouse}
 Mouse.Mouse.MouseState:=MOUSE_STATE_ATTACHING;
 Mouse.Mouse.DeviceRead:=HIDMouseDeviceRead;
 Mouse.Mouse.DeviceControl:=HIDMouseDeviceControl;
 {Driver}
 {USB}
 Mouse.HIDInterface:=Interrface;
 Mouse.ReportEndpoint:=ReportEndpoint;
 Mouse.WaiterThread:=INVALID_HANDLE_VALUE;
 
 {Allocate Report Request}
 Mouse.ReportRequest:=USBRequestAllocate(Device,ReportEndpoint,HIDMouseReportComplete,SizeOf(THIDMouseInputReport),Mouse);
 if Mouse.ReportRequest = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'HID Mouse: Failed to allocate USB report request for mouse');

   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Register Mouse} 
 if MouseDeviceRegister(@Mouse.Mouse) <> ERROR_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'HID Mouse: Failed to register new mouse device');
   
   {Release Report Request}
   USBRequestRelease(Mouse.ReportRequest);
   
   {Destroy Mouse}
   MouseDeviceDestroy(@Mouse.Mouse);
   
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 
 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Enabling HID report protocol');
 {$ENDIF}

 {Set Report Protocol}
 Status:=HIDMouseDeviceSetProtocol(Mouse,USB_HID_PROTOCOL_REPORT);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'HID Mouse: Failed to enable HID report protocol: ' + USBStatusToString(Status));

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
 
 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Submitting report request');
 {$ENDIF}
 
 {Submit Request}
 Status:=USBRequestSubmit(Mouse.ReportRequest);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'HID Mouse: Failed to submit report request: ' + USBStatusToString(Status));
   
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
 
function HIDMouseDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Unbind the Mouse driver from a USB device}
{Device: The USB device to unbind from}
{Interrface: The USB interface to unbind from (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Message:TMessage;
 Mouse:PHIDMouseDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface = nil then Exit;
 
 {Check Driver}
 if Interrface.Driver <> HIDMouseDriver then Exit;
 
 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Unbinding USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}
 
 {Get Mouse}
 Mouse:=PHIDMouseDevice(Interrface.DriverData);
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
   {$IFDEF USB_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'HID Mouse: Waiting for ' + IntToStr(Mouse.PendingCount) + ' pending requests to complete');
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

procedure HIDMouseReportWorker(Request:PUSBRequest); 
{Called (by a Worker thread) to process a completed USB request from a USB mouse IN interrupt endpoint}
{Request: The USB request which has completed}
var
 Data:TMouseData;
 Status:LongWord;
 Message:TMessage;
 Mouse:PHIDMouseDevice;
 Report:PHIDMouseInputReport;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Mouse}
 Mouse:=PHIDMouseDevice(Request.DriverData);
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
        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'HID Mouse: Detachment pending, setting report request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}
        
        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;
 
      {Check Result}
      if Request.Status = USB_STATUS_SUCCESS then  
       begin
        {A report was received from the USB mouse}
        Report:=Request.Data;
        
        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'HID Mouse: Report received (ReportId=' + IntToStr(Report.ReportId) + ')'); 
        {$ENDIF}
     
        {Check Report}
        if Report.ReportId = HIDMOUSE_REPORT_ID then
         begin
          {Check Size}
          if Request.ActualSize >= SizeOf(THIDMouseInputReport) then
           begin
            {Get Buttons}
            Data.Buttons:=0;
            
            {Check Button1}
            if (Report.MousePointerButtons and HIDMOUSE_BUTTON1) <> 0 then
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
            if (Report.MousePointerButtons and HIDMOUSE_BUTTON2) <> 0 then
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
            if (Report.MousePointerButtons and HIDMOUSE_BUTTON3) <> 0 then Data.Buttons:=Data.Buttons or MOUSE_MIDDLE_BUTTON;
            
            {Get X offset}
            Data.OffsetX:=Report.MousePointerX;
    
            {Get Y offset}
            Data.OffsetY:=Report.MousePointerY;
    
            {Get Wheel offset}
            Data.OffsetWheel:=Report.MousePointerWheel;
            
            {Maximum X, Y and Wheel}
            Data.MaximumX:=0;
            Data.MaximumY:=0;
            Data.MaximumWheel:=0;
            
            {Insert Data}
            MouseInsertData(@Mouse.Mouse,@Data,True);
           end
          else
           begin
            if USB_LOG_ENABLED then USBLogError(Request.Device,'HID Mouse: Report invalid (ActualSize=' + IntToStr(Request.ActualSize) + ')'); 
            
            {Update Statistics}
            Inc(Mouse.Mouse.ReceiveErrors); 
           end;
         end;
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'HID Mouse: Failed report request (Status=' + USBStatusToString(Request.Status) + ')'); 
        
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
            {$IFDEF USB_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'HID Mouse: Detachment pending, sending message to waiter thread (Thread=' + IntToHex(Mouse.WaiterThread,8) + ')');
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
      
        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'HID Mouse: Resubmitting report request');
        {$ENDIF}

        {Resubmit Request}
        Status:=USBRequestSubmit(Request);
        if Status <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'HID Mouse: Failed to resubmit report request: ' + USBStatusToString(Status));
   
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
     if USB_LOG_ENABLED then USBLogError(Request.Device,'HID Mouse: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'HID Mouse: Report request invalid');
  end;    
end;
 
{==============================================================================}
 
procedure HIDMouseReportComplete(Request:PUSBRequest);
{Called when a USB request from a USB mouse IN interrupt endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;
 
 WorkerSchedule(0,TWorkerTask(HIDMouseReportWorker),Request,nil)
end;
 
{==============================================================================}
{==============================================================================}
{HID Mouse Helper Functions}
function HIDMouseCheckDeviceAndInterface(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Check the Vendor, Device ID and Interface against the supported devices}
{Device: USB device to check}
{Interrface: USB inerface to check}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}      
var
 Count:Integer;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;
 
 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface = nil then Exit;
 
 {Check Device IDs}
 for Count:=0 to HIDMOUSE_DEVICE_ID_COUNT - 1 do
  begin
   if (HIDMOUSE_DEVICE_ID[Count].idVendor = Device.Descriptor.idVendor) and (HIDMOUSE_DEVICE_ID[Count].idProduct = Device.Descriptor.idProduct) and (HIDMOUSE_DEVICE_ID[Count].bInterfaceNumber = Interrface.Descriptor.bInterfaceNumber) then
    begin
     Result:=USB_STATUS_SUCCESS;
     Exit;
    end;
  end;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function HIDMouseDeviceSetProtocol(Mouse:PHIDMouseDevice;Protocol:Byte):LongWord;
{Set the report protocol for a USB mouse device}
{Mouse: The HID mouse device to set the report protocol for}
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
 HIDMouseInit;

{==============================================================================}
 
finalization
 {Nothing}
 
{==============================================================================}
{==============================================================================}

end.
