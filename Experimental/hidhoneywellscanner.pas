{
Ultibo HID Honeywell Scanner Driver.

Copyright (C) 2020 - SoftOz Pty Ltd.

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

HID USB Keyboard
================

 This unit provides a USB HID keyboard driver for device 0C2E:1001 USB Scanner (Honeywell).

}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}

unit HIDHoneywellScanner;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,USB,Keyboard,Keymap,SysUtils;

{==============================================================================}
const
 {HID Keyboard specific constants}
 HIDKEYBOARD_DRIVER_NAME = 'HID Honeywell Scanner Driver'; {Name of HID driver}

 HIDKEYBOARD_KEYBOARD_DESCRIPTION = 'Honeywell HID Scanner'; {Description of HID keyboard device}

 {HID Keyboard Modifier bits}
 HIDKEYBOARD_LEFT_CTRL   = (1 shl 0);
 HIDKEYBOARD_LEFT_SHIFT  = (1 shl 1);
 HIDKEYBOARD_LEFT_ALT    = (1 shl 2);
 HIDKEYBOARD_LEFT_GUI    = (1 shl 3);
 HIDKEYBOARD_RIGHT_CTRL  = (1 shl 4);
 HIDKEYBOARD_RIGHT_SHIFT = (1 shl 5);
 HIDKEYBOARD_RIGHT_ALT   = (1 shl 6);
 HIDKEYBOARD_RIGHT_GUI   = (1 shl 7);

 {HID Keyboard Report data}
 HIDKEYBOARD_REPORT_SIZE = 8;

 {HID Keyboard Output bits}
 HIDKEYBOARD_NUMLOCK_LED     = (1 shl 0);
 HIDKEYBOARD_CAPSLOCK_LED    = (1 shl 1);
 HIDKEYBOARD_SCROLLLOCK_LED  = (1 shl 2);
 HIDKEYBOARD_COMPOSE_LED     = (1 shl 3);
 HIDKEYBOARD_KANA_LED        = (1 shl 4);

 HIDKEYBOARD_LEDMASK = HIDKEYBOARD_NUMLOCK_LED or HIDKEYBOARD_CAPSLOCK_LED or HIDKEYBOARD_SCROLLLOCK_LED or HIDKEYBOARD_COMPOSE_LED or HIDKEYBOARD_KANA_LED;

 {HID Keyboard Report IDs}
 HIDKEYBOARD_REPORTID_NONE = 0;

 {HID Keyboard Output data}
 HIDKEYBOARD_OUTPUT_SIZE = 1;

 HIDKEYBOARD_DEVICE_ID_COUNT = 1; {Number of supported Device IDs}

 HIDKEYBOARD_DEVICE_ID:array[0..HIDKEYBOARD_DEVICE_ID_COUNT - 1] of TUSBDeviceAndInterfaceNo = (
  (idVendor:$0C2E;idProduct:$1001;bInterfaceNumber:0));

{==============================================================================}
type
 {HID Keyboard specific types}
 PHIDKeyboardInputReport = ^THIDKeyboardInputReport;
 THIDKeyboardInputReport = record
  {No Report ID}
  Modifiers:Byte;           {Keyboard Left Control, Value = 0 to 1}
                            {Keyboard Left Shift, Value = 0 to 1}
                            {Keyboard Left Alt, Value = 0 to 1}
                            {Keyboard Left GUI, Value = 0 to 1}
                            {Keyboard Right Control, Value = 0 to 1}
                            {Keyboard Right Shift, Value = 0 to 1}
                            {Keyboard Right Alt, Value = 0 to 1}
                            {Keyboard Right GUI, Value = 0 to 1}
  Pad:Byte;                 {Pad}
  Keys:array[0..5] of Byte; {Value = 0 to 255}
 end;

 PHIDKeyboardOutputReport = ^THIDKeyboardInputReport;
 THIDKeyboardOutputReport = record
  {No Report ID}
  LEDs:Byte; {Num Lock, Value = 0 to 1}
             {Caps Lock, Value = 0 to 1}
             {Scroll Lock, Value = 0 to 1}
             {Compose, Value = 0 to 1}
             {Kana, Value = 0 to 1}
             {Pad}
 end;

 PHIDKeyboardDevice = ^THIDKeyboardDevice;
 THIDKeyboardDevice = record
  {Keyboard Properties}
  Keyboard:TKeyboardDevice;
  {USB Properties}
  HIDInterface:PUSBInterface;            {USB HID Keyboard Interface}
  ReportRequest:PUSBRequest;             {USB request for keyboard report data}
  ReportEndpoint:PUSBEndpointDescriptor; {USB Keyboard Interrupt IN Endpoint}
  HIDDescriptor:PUSBHIDDescriptor;       {USB HID Descriptor for keyboard}
  ReportDescriptor:Pointer;              {USB HID Report Descriptor for keyboard}
  LastCode:Word;                         {The scan code of the last key pressed}
  LastCount:LongWord;                    {The repeat count of the last key pressed}
  LastReport:THIDKeyboardInputReport;    {The last keyboard input report received}
  PendingCount:LongWord;                 {Number of USB requests pending for this keyboard}
  WaiterThread:TThreadId;                {Thread waiting for pending requests to complete (for keyboard detachment)}
 end;

{==============================================================================}
{var}
 {HID Keyboard specific variables}

{==============================================================================}
{Initialization Functions}
procedure HIDKeyboardInit;

{==============================================================================}
{HID Keyboard Functions}
function HIDKeyboardDeviceRead(Keyboard:PKeyboardDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
function HIDKeyboardDeviceControl(Keyboard:PKeyboardDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;

function HIDKeyboardDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
function HIDKeyboardDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

procedure HIDKeyboardReportWorker(Request:PUSBRequest);
procedure HIDKeyboardReportComplete(Request:PUSBRequest);

{==============================================================================}
{HID Helper Functions}
function HIDKeyboardCheckDeviceAndInterface(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

function HIDKeyboardCheckPressed(Keyboard:PHIDKeyboardDevice;ScanCode:Byte):Boolean;
function HIDKeyboardCheckRepeated(Keyboard:PHIDKeyboardDevice;ScanCode:Byte):Boolean;
function HIDKeyboardCheckReleased(Keyboard:PHIDKeyboardDevice;Report:PHIDKeyboardInputReport;ScanCode:Byte):Boolean;

function HIDKeyboardDeviceSetLEDs(Keyboard:PHIDKeyboardDevice;LEDs,ReportId:Byte):LongWord;
function HIDKeyboardDeviceSetIdle(Keyboard:PHIDKeyboardDevice;Duration,ReportId:Byte):LongWord;
function HIDKeyboardDeviceSetProtocol(Keyboard:PHIDKeyboardDevice;Protocol:Byte):LongWord;

function HIDKeyboardDeviceGetHIDDescriptor(Keyboard:PHIDKeyboardDevice;Descriptor:PUSBHIDDescriptor):LongWord;
function HIDKeyboardDeviceGetReportDescriptor(Keyboard:PHIDKeyboardDevice;Descriptor:Pointer;Size:LongWord):LongWord;

{==============================================================================}
{==============================================================================}

implementation

{==============================================================================}
{==============================================================================}
var
 {HID Keyboard specific variables}
 HIDKeyboardInitialized:Boolean;

 HIDKeyboardDriver:PUSBDriver;  {HID Keyboard Driver interface (Set by HIDKeyboardInit)}

{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure HIDKeyboardInit;
{Initialize the HID keyboard driver}

{Note: Called only during system startup}
var
 Status:LongWord;
begin
 {Check Initialized}
 if HIDKeyboardInitialized then Exit;

 {Create HID Keyboard Driver}
 HIDKeyboardDriver:=USBDriverCreate;
 if HIDKeyboardDriver <> nil then
  begin
   {Update HID Keyboard Driver}
   {Driver}
   HIDKeyboardDriver.Driver.DriverName:=HIDKEYBOARD_DRIVER_NAME;
   {USB}
   HIDKeyboardDriver.DriverBind:=HIDKeyboardDriverBind;
   HIDKeyboardDriver.DriverUnbind:=HIDKeyboardDriverUnbind;

   {Register HID Keyboard Driver}
   Status:=USBDriverRegister(HIDKeyboardDriver);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'HID Keyboard: Failed to register HID keyboard driver: ' + USBStatusToString(Status));
    end;
  end
 else
  begin
   if KEYBOARD_LOG_ENABLED then KeyboardLogError(nil,'Failed to create HID keyboard driver');
  end;

 HIDKeyboardInitialized:=True;
end;

{==============================================================================}
{==============================================================================}
{HID Keyboard Functions}
function HIDKeyboardDeviceRead(Keyboard:PKeyboardDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
{Implementation of KeyboardDeviceRead API for HID Keyboard}
{Note: Not intended to be called directly by applications, use KeyboardDeviceRead instead}
var
 Offset:PtrUInt;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;
 if Keyboard.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Check Buffer}
 if Buffer = nil then Exit;

 {Check Size}
 if Size < SizeOf(TKeyboardData) then Exit;

 {Check Keyboard Attached}
 if Keyboard.KeyboardState <> KEYBOARD_STATE_ATTACHED then Exit;

 {$IFDEF KEYBOARD_DEBUG}
 if KEYBOARD_LOG_ENABLED then KeyboardLogDebug(Keyboard,'Attempting to read ' + IntToStr(Size) + ' bytes from keyboard');
 {$ENDIF}

 {Read to Buffer}
 Count:=0;
 Offset:=0;
 while Size >= SizeOf(TKeyboardData) do
  begin
   {Check Non Blocking}
   if ((Keyboard.Device.DeviceFlags and KEYBOARD_FLAG_NON_BLOCK) <> 0) and (Keyboard.Buffer.Count = 0) then
    begin
     if Count = 0 then Result:=ERROR_NO_MORE_ITEMS;
     Break;
    end;

   {Wait for Keyboard Data}
   if SemaphoreWait(Keyboard.Buffer.Wait) = ERROR_SUCCESS then
    begin
     {Acquire the Lock}
     if MutexLock(Keyboard.Lock) = ERROR_SUCCESS then
      begin
       try
        {Copy Data}
        PKeyboardData(PtrUInt(Buffer) + Offset)^:=Keyboard.Buffer.Buffer[Keyboard.Buffer.Start];

        {Update Start}
        Keyboard.Buffer.Start:=(Keyboard.Buffer.Start + 1) mod KEYBOARD_BUFFER_SIZE;

        {Update Count}
        Dec(Keyboard.Buffer.Count);

        {Update Count}
        Inc(Count);

        {Update Size and Offset}
        Dec(Size,SizeOf(TKeyboardData));
        Inc(Offset,SizeOf(TKeyboardData));
       finally
        {Release the Lock}
        MutexUnlock(Keyboard.Lock);
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

 {$IFDEF KEYBOARD_DEBUG}
 if KEYBOARD_LOG_ENABLED then KeyboardLogDebug(Keyboard,'Return count=' + IntToStr(Count));
 {$ENDIF}
end;

{==============================================================================}

function HIDKeyboardDeviceControl(Keyboard:PKeyboardDevice;Request:Integer;Argument1:LongWord;var Argument2:LongWord):LongWord;
{Implementation of KeyboardDeviceControl API for HID Keyboard}
{Note: Not intended to be called directly by applications, use KeyboardDeviceControl instead}
var
 Status:LongWord;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;
 if Keyboard.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Check Keyboard Attached}
 if Keyboard.KeyboardState <> KEYBOARD_STATE_ATTACHED then Exit;

 {Acquire the Lock}
 if MutexLock(Keyboard.Lock) = ERROR_SUCCESS then
  begin
   try
    case Request of
     KEYBOARD_CONTROL_GET_FLAG:begin
       {Get Flag}
       LongBool(Argument2):=False;
       if (Keyboard.Device.DeviceFlags and Argument1) <> 0 then
        begin
         LongBool(Argument2):=True;

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_SET_FLAG:begin
       {Set Flag}
       if (Argument1 and not(KEYBOARD_FLAG_MASK)) = 0 then
        begin
         Keyboard.Device.DeviceFlags:=(Keyboard.Device.DeviceFlags or Argument1);

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_CLEAR_FLAG:begin
       {Clear Flag}
       if (Argument1 and not(KEYBOARD_FLAG_MASK)) = 0 then
        begin
         Keyboard.Device.DeviceFlags:=(Keyboard.Device.DeviceFlags and not(Argument1));

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_FLUSH_BUFFER:begin
       {Flush Buffer}
       while Keyboard.Buffer.Count > 0 do
        begin
         {Wait for Data (Should not Block)}
         if SemaphoreWait(Keyboard.Buffer.Wait) = ERROR_SUCCESS then
          begin
           {Update Start}
           Keyboard.Buffer.Start:=(Keyboard.Buffer.Start + 1) mod KEYBOARD_BUFFER_SIZE;

           {Update Count}
           Dec(Keyboard.Buffer.Count);
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
     KEYBOARD_CONTROL_GET_LED:begin
       {Get LED}
       LongBool(Argument2):=False;
       if (Keyboard.KeyboardLEDs and Argument1) <> 0 then
        begin
         LongBool(Argument2):=True;

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_SET_LED:begin
       {Set LED}
       if (Argument1 and not(KEYBOARD_LED_MASK)) = 0 then
        begin
         Keyboard.KeyboardLEDs:=(Keyboard.KeyboardLEDs or Argument1);

         {Set LEDs}
         Status:=HIDKeyboardDeviceSetLEDs(PHIDKeyboardDevice(Keyboard),Keyboard.KeyboardLEDs,HIDKEYBOARD_REPORTID_NONE);
         if Status <> USB_STATUS_SUCCESS then
          begin
           Result:=ERROR_OPERATION_FAILED;
           Exit;
          end;

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_CLEAR_LED:begin
       {Clear LED}
       if (Argument1 and not(KEYBOARD_LED_MASK)) = 0 then
        begin
         Keyboard.KeyboardLEDs:=(Keyboard.KeyboardLEDs and not(Argument1));

         {Set LEDs}
         Status:=HIDKeyboardDeviceSetLEDs(PHIDKeyboardDevice(Keyboard),Keyboard.KeyboardLEDs,HIDKEYBOARD_REPORTID_NONE);
         if Status <> USB_STATUS_SUCCESS then
          begin
           Result:=ERROR_OPERATION_FAILED;
           Exit;
          end;

         {Return Result}
         Result:=ERROR_SUCCESS;
        end;
      end;
     KEYBOARD_CONTROL_GET_REPEAT_RATE:begin
       {Get Repeat Rate}
       Argument2:=Keyboard.KeyboardRate;

       {Return Result}
       Result:=ERROR_SUCCESS;
      end;
     KEYBOARD_CONTROL_SET_REPEAT_RATE:begin
       {Set Repeat Rate}
       Keyboard.KeyboardRate:=Argument1;

       {Set Idle}
       Status:=HIDKeyboardDeviceSetIdle(PHIDKeyboardDevice(Keyboard),Keyboard.KeyboardRate,HIDKEYBOARD_REPORTID_NONE);
       if Status <> USB_STATUS_SUCCESS then
        begin
         Result:=ERROR_OPERATION_FAILED;
         Exit;
        end;

       {Return Result}
       Result:=ERROR_SUCCESS;
      end;
     KEYBOARD_CONTROL_GET_REPEAT_DELAY:begin
       {Get Repeat Delay}
       Argument2:=Keyboard.KeyboardDelay;

       {Return Result}
       Result:=ERROR_SUCCESS;
      end;
     KEYBOARD_CONTROL_SET_REPEAT_DELAY:begin
       {Set Repeat Delay}
       Keyboard.KeyboardDelay:=Argument1;

       {Return Result}
       Result:=ERROR_SUCCESS;
      end;
    end;
   finally
    {Release the Lock}
    MutexUnlock(Keyboard.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
   Exit;
  end;
end;

{==============================================================================}

function HIDKeyboardDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Bind the Keyboard driver to a USB device if it is suitable}
{Device: The USB device to attempt to bind to}
{Interrface: The USB interface to attempt to bind to (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed, USB_STATUS_DEVICE_UNSUPPORTED if unsupported or another error code on failure}
var
 Status:LongWord;
 Interval:LongWord;
 Keyboard:PHIDKeyboardDevice;
 ReportEndpoint:PUSBEndpointDescriptor;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Attempting to bind USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Check Interface (Bind to interface only)}
 if Interrface = nil then
  begin
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check HID Keyboard Device}
 if HIDKeyboardCheckDeviceAndInterface(Device,Interrface) <> USB_STATUS_SUCCESS then
  begin
   {$IFDEF USB_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'HID Keyboard: Device not found in supported device list');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check for Keyboard (Must be interface specific)}
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

 {Create Keyboard}
 Keyboard:=PHIDKeyboardDevice(KeyboardDeviceCreateEx(SizeOf(THIDKeyboardDevice)));
 if Keyboard = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to create new keyboard device');

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Update Keyboard}
 {Device}
 Keyboard.Keyboard.Device.DeviceBus:=DEVICE_BUS_USB;
 Keyboard.Keyboard.Device.DeviceType:=KEYBOARD_TYPE_USB;
 Keyboard.Keyboard.Device.DeviceFlags:=Keyboard.Keyboard.Device.DeviceFlags; {Don't override defaults (was KEYBOARD_FLAG_NONE)}
 Keyboard.Keyboard.Device.DeviceData:=Device;
 Keyboard.Keyboard.Device.DeviceDescription:=HIDKEYBOARD_KEYBOARD_DESCRIPTION;
 {Keyboard}
 Keyboard.Keyboard.KeyboardState:=KEYBOARD_STATE_ATTACHING;
 Keyboard.Keyboard.DeviceRead:=HIDKeyboardDeviceRead;
 Keyboard.Keyboard.DeviceControl:=HIDKeyboardDeviceControl;
 {Driver}
 {USB}
 Keyboard.HIDInterface:=Interrface;
 Keyboard.ReportEndpoint:=ReportEndpoint;
 Keyboard.WaiterThread:=INVALID_HANDLE_VALUE;

 {Allocate Report Request}
 Keyboard.ReportRequest:=USBRequestAllocate(Device,ReportEndpoint,HIDKeyboardReportComplete,HIDKEYBOARD_REPORT_SIZE,Keyboard);
 if Keyboard.ReportRequest = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to allocate USB report request for keyboard');

   {Destroy Keyboard}
   KeyboardDeviceDestroy(@Keyboard.Keyboard);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Register Keyboard}
 if KeyboardDeviceRegister(@Keyboard.Keyboard) <> ERROR_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to register new keyboard device');

   {Release Report Request}
   USBRequestRelease(Keyboard.ReportRequest);

   {Destroy Keyboard}
   KeyboardDeviceDestroy(@Keyboard.Keyboard);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Reading HID report descriptors');
 {$ENDIF}

 {Get HID Descriptor}
 Keyboard.HIDDescriptor:=USBBufferAllocate(Device,SizeOf(TUSBHIDDescriptor));
 if Keyboard.HIDDescriptor <> nil then
  begin
   Status:=HIDKeyboardDeviceGetHIDDescriptor(Keyboard,Keyboard.HIDDescriptor);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to read HID descriptor: ' + USBStatusToString(Status));

     {Don't fail the bind}
    end
   else
    begin
     if (Keyboard.HIDDescriptor.bDescriptorType = USB_HID_DESCRIPTOR_TYPE_HID) and (Keyboard.HIDDescriptor.bHIDDescriptorType = USB_HID_DESCRIPTOR_TYPE_REPORT) then
      begin
       {Get Report Descriptor}
       Keyboard.ReportDescriptor:=USBBufferAllocate(Device,Keyboard.HIDDescriptor.wHIDDescriptorLength);
       if Keyboard.ReportDescriptor <> nil then
        begin
         Status:=HIDKeyboardDeviceGetReportDescriptor(Keyboard,Keyboard.ReportDescriptor,Keyboard.HIDDescriptor.wHIDDescriptorLength);
         if Status <> USB_STATUS_SUCCESS then
          begin
           if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to read HID report descriptor: ' + USBStatusToString(Status));

           {Don't fail the bind}
         {$IFDEF USB_DEBUG}
         else
          begin
           if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Read ' + IntToStr(Keyboard.HIDDescriptor.wHIDDescriptorLength) + ' byte HID report descriptor');
         {$ENDIF}
          end;
        end;
      end;
    end;
  end;

 {Check Interface (Only for HID boot sub class)}
 if Interrface.Descriptor.bInterfaceSubClass = USB_HID_SUBCLASS_BOOT then
  begin
   {$IFDEF USB_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Enabling HID report protocol');
   {$ENDIF}

   {Set Report Protocol}
   Status:=HIDKeyboardDeviceSetProtocol(Keyboard,USB_HID_PROTOCOL_REPORT);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to enable HID report protocol: ' + USBStatusToString(Status));

     {Release Report Request}
     USBRequestRelease(Keyboard.ReportRequest);

     {Release HID Descriptor}
     USBBufferRelease(Keyboard.HIDDescriptor);

     {Release Report Descriptor}
     USBBufferRelease(Keyboard.ReportDescriptor);

     {Deregister Keyboard}
     KeyboardDeviceDeregister(@Keyboard.Keyboard);

     {Destroy Keyboard}
     KeyboardDeviceDestroy(@Keyboard.Keyboard);

     {Return Result}
     Result:=USB_STATUS_DEVICE_UNSUPPORTED;
     Exit;
    end;
  end;

 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Setting idle rate');
 {$ENDIF}

 {Set Repeat Rate}
 Status:=HIDKeyboardDeviceSetIdle(Keyboard,Keyboard.Keyboard.KeyboardRate,HIDKEYBOARD_REPORTID_NONE);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to set idle rate: ' + USBStatusToString(Status));

   {Release Report Request}
   USBRequestRelease(Keyboard.ReportRequest);

   {Release HID Descriptor}
   USBBufferRelease(Keyboard.HIDDescriptor);

   {Release Report Descriptor}
   USBBufferRelease(Keyboard.ReportDescriptor);

   {Deregister Keyboard}
   KeyboardDeviceDeregister(@Keyboard.Keyboard);

   {Destroy Keyboard}
   KeyboardDeviceDestroy(@Keyboard.Keyboard);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Set LEDs}
 Status:=HIDKeyboardDeviceSetLEDs(Keyboard,Keyboard.Keyboard.KeyboardLEDs,HIDKEYBOARD_REPORTID_NONE);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to set LEDs: ' + USBStatusToString(Status));

   {Release Report Request}
   USBRequestRelease(Keyboard.ReportRequest);

   {Release HID Descriptor}
   USBBufferRelease(Keyboard.HIDDescriptor);

   {Release Report Descriptor}
   USBBufferRelease(Keyboard.ReportDescriptor);

   {Deregister Keyboard}
   KeyboardDeviceDeregister(@Keyboard.Keyboard);

   {Destroy Keyboard}
   KeyboardDeviceDestroy(@Keyboard.Keyboard);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check Endpoint Interval}
 if USB_KEYBOARD_POLLING_INTERVAL > 0 then
  begin
   {Check Device Speed}
   if Device.Speed = USB_SPEED_HIGH then
    begin
     {Get Interval}
     Interval:=FirstBitSet(USB_KEYBOARD_POLLING_INTERVAL * USB_UFRAMES_PER_MS) + 1;

     {Ensure no less than Interval} {Milliseconds = (1 shl (bInterval - 1)) div USB_UFRAMES_PER_MS}
     if ReportEndpoint.bInterval < Interval then ReportEndpoint.bInterval:=Interval;
    end
   else
    begin
     {Ensure no less than USB_KEYBOARD_POLLING_INTERVAL} {Milliseconds = bInterval div USB_FRAMES_PER_MS}
     if ReportEndpoint.bInterval < USB_KEYBOARD_POLLING_INTERVAL then ReportEndpoint.bInterval:=USB_KEYBOARD_POLLING_INTERVAL;
    end;
  end;

 {Update Interface}
 Interrface.DriverData:=Keyboard;

 {Update Pending}
 Inc(Keyboard.PendingCount);

 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Submitting report request');
 {$ENDIF}

 {Submit Request}
 Status:=USBRequestSubmit(Keyboard.ReportRequest);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'Keyboard: Failed to submit report request: ' + USBStatusToString(Status));

   {Update Pending}
   Dec(Keyboard.PendingCount);

   {Release Report Request}
   USBRequestRelease(Keyboard.ReportRequest);

   {Release HID Descriptor}
   USBBufferRelease(Keyboard.HIDDescriptor);

   {Release Report Descriptor}
   USBBufferRelease(Keyboard.ReportDescriptor);

   {Deregister Keyboard}
   KeyboardDeviceDeregister(@Keyboard.Keyboard);

   {Destroy Keyboard}
   KeyboardDeviceDestroy(@Keyboard.Keyboard);

   {Return Result}
   Result:=Status;
   Exit;
  end;

 {Set State to Attached}
 if KeyboardDeviceSetState(@Keyboard.Keyboard,KEYBOARD_STATE_ATTACHED) <> ERROR_SUCCESS then Exit;

 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

function HIDKeyboardDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Unbind the Keyboard driver from a USB device}
{Device: The USB device to unbind from}
{Interrface: The USB interface to unbind from (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Message:TMessage;
 Keyboard:PHIDKeyboardDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface = nil then Exit;

 {Check Driver}
 if Interrface.Driver <> HIDKeyboardDriver then Exit;

 {$IFDEF USB_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Unbinding USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Get Keyboard}
 Keyboard:=PHIDKeyboardDevice(Interrface.DriverData);
 if Keyboard = nil then Exit;
 if Keyboard.Keyboard.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Set State to Detaching}
 Result:=USB_STATUS_OPERATION_FAILED;
 if KeyboardDeviceSetState(@Keyboard.Keyboard,KEYBOARD_STATE_DETACHING) <> ERROR_SUCCESS then Exit;

 {Acquire the Lock}
 if MutexLock(Keyboard.Keyboard.Lock) <> ERROR_SUCCESS then Exit;

 {Cancel Report Request}
 USBRequestCancel(Keyboard.ReportRequest);

 {Check Pending}
 if Keyboard.PendingCount <> 0 then
  begin
   {$IFDEF USB_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'Keyboard: Waiting for ' + IntToStr(Keyboard.PendingCount) + ' pending requests to complete');
   {$ENDIF}

   {Wait for Pending}

   {Setup Waiter}
   Keyboard.WaiterThread:=GetCurrentThreadId;

   {Release the Lock}
   MutexUnlock(Keyboard.Keyboard.Lock);

   {Wait for Message}
   ThreadReceiveMessage(Message);
  end
 else
  begin
   {Release the Lock}
   MutexUnlock(Keyboard.Keyboard.Lock);
  end;

 {Set State to Detached}
 if KeyboardDeviceSetState(@Keyboard.Keyboard,KEYBOARD_STATE_DETACHED) <> ERROR_SUCCESS then Exit;

 {Update Interface}
 Interrface.DriverData:=nil;

 {Release Report Request}
 USBRequestRelease(Keyboard.ReportRequest);

 {Release HID Descriptor}
 USBBufferRelease(Keyboard.HIDDescriptor);

 {Release Report Descriptor}
 USBBufferRelease(Keyboard.ReportDescriptor);

 {Deregister Keyboard}
 if KeyboardDeviceDeregister(@Keyboard.Keyboard) <> ERROR_SUCCESS then Exit;

 {Destroy Keyboard}
 KeyboardDeviceDestroy(@Keyboard.Keyboard);

 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

procedure HIDKeyboardReportWorker(Request:PUSBRequest);
{Called (by a Worker thread) to process a completed USB request from a HID keyboard IN interrupt endpoint}
{Request: The USB request which has completed}
var
 Index:Byte;
 Saved:Byte;
 Count:Integer;
 LEDs:LongWord;
 KeyCode:Word;
 ScanCode:Byte;
 Status:LongWord;
 Message:TMessage;
 Modifiers:LongWord;
 Data:TKeyboardData;
 Keymap:TKeymapHandle;
 Keyboard:PHIDKeyboardDevice;
 Report:PHIDKeyboardInputReport;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Keyboard}
 Keyboard:=PHIDKeyboardDevice(Request.DriverData);
 if Keyboard <> nil then
  begin
   {Acquire the Lock}
   if MutexLock(Keyboard.Keyboard.Lock) = ERROR_SUCCESS then
    begin
     try
      {Update Statistics}
      Inc(Keyboard.Keyboard.ReceiveCount);

      {Check State}
      if Keyboard.Keyboard.KeyboardState = KEYBOARD_STATE_DETACHING then
       begin
        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Detachment pending, setting report request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}

        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;

      {Check Result}
      if (Request.Status = USB_STATUS_SUCCESS) and (Request.ActualSize = HIDKEYBOARD_REPORT_SIZE) then
       begin
        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Report received');
        {$ENDIF}

        {A report was received from the HID keyboard}
        Report:=Request.Data;
        Keymap:=KeymapGetDefault;
        LEDs:=Keyboard.Keyboard.KeyboardLEDs;

        {Get Modifiers}
        Modifiers:=0;

        {LED Modifiers}
        if Keyboard.Keyboard.KeyboardLEDs <> KEYBOARD_LED_NONE then
         begin
          if (Keyboard.Keyboard.KeyboardLEDs and KEYBOARD_LED_NUMLOCK) <> 0 then Modifiers:=Modifiers or KEYBOARD_NUM_LOCK;
          if (Keyboard.Keyboard.KeyboardLEDs and KEYBOARD_LED_CAPSLOCK) <> 0 then Modifiers:=Modifiers or KEYBOARD_CAPS_LOCK;
          if (Keyboard.Keyboard.KeyboardLEDs and KEYBOARD_LED_SCROLLLOCK) <> 0 then Modifiers:=Modifiers or KEYBOARD_SCROLL_LOCK;
          if (Keyboard.Keyboard.KeyboardLEDs and KEYBOARD_LED_COMPOSE) <> 0 then Modifiers:=Modifiers or KEYBOARD_COMPOSE;
          if (Keyboard.Keyboard.KeyboardLEDs and KEYBOARD_LED_KANA) <> 0 then Modifiers:=Modifiers or KEYBOARD_KANA;
         end;

        {Report Modifiers}
        if Report.Modifiers <> 0 then
         begin
          if (Report.Modifiers and HIDKEYBOARD_LEFT_CTRL) <> 0 then Modifiers:=Modifiers or KEYBOARD_LEFT_CTRL;
          if (Report.Modifiers and HIDKEYBOARD_LEFT_SHIFT) <> 0 then Modifiers:=Modifiers or KEYBOARD_LEFT_SHIFT;
          if (Report.Modifiers and HIDKEYBOARD_LEFT_ALT) <> 0 then Modifiers:=Modifiers or KEYBOARD_LEFT_ALT;
          if (Report.Modifiers and HIDKEYBOARD_LEFT_GUI) <> 0 then Modifiers:=Modifiers or KEYBOARD_LEFT_GUI;
          if (Report.Modifiers and HIDKEYBOARD_RIGHT_CTRL) <> 0 then Modifiers:=Modifiers or KEYBOARD_RIGHT_CTRL;
          if (Report.Modifiers and HIDKEYBOARD_RIGHT_SHIFT) <> 0 then Modifiers:=Modifiers or KEYBOARD_RIGHT_SHIFT;
          if (Report.Modifiers and HIDKEYBOARD_RIGHT_ALT) <> 0 then Modifiers:=Modifiers or KEYBOARD_RIGHT_ALT;
          if (Report.Modifiers and HIDKEYBOARD_RIGHT_GUI) <> 0 then Modifiers:=Modifiers or KEYBOARD_RIGHT_GUI;
         end;

        {Get Keymap Index}
        Index:=KEYMAP_INDEX_NORMAL;

        {Check for Shift}
        if (Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
         begin
          Index:=KEYMAP_INDEX_SHIFT;

          {Check Shift behavior}
          if KEYBOARD_SHIFT_IS_CAPS_LOCK_OFF then
           begin
            {Check for Caps Lock}
            if (Modifiers and (KEYBOARD_CAPS_LOCK)) <> 0 then
             begin
              {Update LEDs}
              Keyboard.Keyboard.KeyboardLEDs:=Keyboard.Keyboard.KeyboardLEDs and not(KEYBOARD_LED_CAPSLOCK);
             end;
           end;
         end;

        {Check AltGr behavior}
        if KeymapCheckFlag(Keymap,KEYMAP_FLAG_ALTGR) then
         begin
          if not(KEYBOARD_CTRL_ALT_IS_ALTGR) then
           begin
            {Check for Right Alt}
            if (Modifiers and (KEYBOARD_RIGHT_ALT)) <> 0 then
             begin
              if Index <> KEYMAP_INDEX_SHIFT then Index:=KEYMAP_INDEX_ALTGR else Index:=KEYMAP_INDEX_SHIFT_ALTGR;
             end;
           end
          else
           begin
            {Check for Ctrl and Alt}
            if ((Modifiers and (KEYBOARD_LEFT_CTRL or KEYBOARD_RIGHT_CTRL)) <> 0) and ((Modifiers and (KEYBOARD_LEFT_ALT or KEYBOARD_RIGHT_ALT)) <> 0) then
             begin
              if Index <> KEYMAP_INDEX_SHIFT then Index:=KEYMAP_INDEX_ALTGR else Index:=KEYMAP_INDEX_SHIFT_ALTGR;
             end;
           end;

          {Check Keymap Index}
          if (Index = KEYMAP_INDEX_ALTGR) or (Index = KEYMAP_INDEX_SHIFT_ALTGR) then
           begin
            Modifiers:=Modifiers or KEYBOARD_ALTGR;
           end;
         end;

        {Save Keymap Index}
        Saved:=Index;

        {Note that the keyboard sends a full report when any key is pressed or released, if a key is down in
         two consecutive reports, it should be interpreted as one keypress unless the repeat delay has elapsed}

        {Check for Keys Pressed}
        for Count:=0 to 5 do {6 bytes of Key data}
         begin
          {Load Keymap Index}
          Index:=Saved;

          {Get Scan Code}
          ScanCode:=Report.Keys[Count];

          {Ignore SCAN_CODE_NONE to SCAN_CODE_ERROR}
          if ScanCode > SCAN_CODE_ERROR then
           begin
            {Check for Caps Lock Shifted Key}
            if KeymapCheckCapskey(Keymap,ScanCode) then
             begin
              {Check for Caps Lock}
              if (Modifiers and (KEYBOARD_CAPS_LOCK)) <> 0 then
               begin
                {Modify Normal and Shift}
                if Index = KEYMAP_INDEX_NORMAL then
                 begin
                  Index:=KEYMAP_INDEX_SHIFT;
                 end
                else if Index = KEYMAP_INDEX_SHIFT then
                 begin
                  Index:=KEYMAP_INDEX_NORMAL;
                 end
                {Modify AltGr and Shift}
                else if Index = KEYMAP_INDEX_ALTGR then
                 begin
                  Index:=KEYMAP_INDEX_SHIFT_ALTGR;
                 end
                else if Index = KEYMAP_INDEX_SHIFT_ALTGR then
                 begin
                  Index:=KEYMAP_INDEX_ALTGR;
                 end;
               end;
             end;

            {Check for Numeric Keypad Key}
            if (ScanCode >= SCAN_CODE_KEYPAD_FIRST) and (ScanCode <= SCAN_CODE_KEYPAD_LAST) then
             begin
              {Check for Num Lock}
              if (Modifiers and (KEYBOARD_NUM_LOCK)) <> 0 then
               begin
                {Check for Shift}
                if (Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
                 begin
                  Index:=KEYMAP_INDEX_NORMAL;
                 end
                else
                 begin
                  Index:=KEYMAP_INDEX_SHIFT;
                 end;
               end
              else
               begin
                Index:=KEYMAP_INDEX_NORMAL;
               end;
             end;

            {Check Pressed}
            if HIDKeyboardCheckPressed(Keyboard,ScanCode) then
             begin
              {$IFDEF USB_DEBUG}
              if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Key Pressed (ScanCode=' + IntToStr(ScanCode) + ' Modifiers=' + IntToHex(Modifiers,8) + ' Index=' + IntToStr(Index) + ')');
              {$ENDIF}

              {Check for NumLock}
              if ScanCode = SCAN_CODE_NUMLOCK then
               begin
                {Update LEDs}
                Keyboard.Keyboard.KeyboardLEDs:=Keyboard.Keyboard.KeyboardLEDs xor KEYBOARD_LED_NUMLOCK;
               end
              else if ScanCode = SCAN_CODE_CAPSLOCK then
               begin
                {Update LEDs}
                Keyboard.Keyboard.KeyboardLEDs:=Keyboard.Keyboard.KeyboardLEDs xor KEYBOARD_LED_CAPSLOCK;
               end
              else if ScanCode = SCAN_CODE_SCROLLLOCK then
               begin
                {Update LEDs}
                Keyboard.Keyboard.KeyboardLEDs:=Keyboard.Keyboard.KeyboardLEDs xor KEYBOARD_LED_SCROLLLOCK;
               end
              else
               begin
                {Update Last}
                Keyboard.LastCode:=ScanCode;
                Keyboard.LastCount:=0;

                {Check for Deadkey}
                if (Keyboard.Keyboard.Code = SCAN_CODE_NONE) and KeymapCheckDeadkey(Keymap,ScanCode,Index) then
                 begin
                  {$IFDEF USB_DEBUG}
                  if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Deadkey Pressed (ScanCode=' + IntToStr(ScanCode) + ' Modifiers=' + IntToHex(Modifiers,8) + ' Index=' + IntToStr(Index) + ')');
                  {$ENDIF}

                  {Update Deadkey}
                  Keyboard.Keyboard.Code:=ScanCode;
                  Keyboard.Keyboard.Index:=Index;
                  Keyboard.Keyboard.Modifiers:=Modifiers;

                  {Get Data}
                  Data.Modifiers:=Modifiers or KEYBOARD_KEYDOWN or KEYBOARD_DEADKEY;
                  Data.ScanCode:=ScanCode;
                  Data.KeyCode:=KeymapGetKeyCode(Keymap,ScanCode,Index);
                  Data.CharCode:=KeymapGetCharCode(Keymap,Data.KeyCode);
                  Data.CharUnicode:=KeymapGetCharUnicode(Keymap,Data.KeyCode);

                  {Insert Data}
                  KeyboardInsertData(@Keyboard.Keyboard,@Data,True);
                 end
                else
                 begin
                  {Check Deadkey}
                  KeyCode:=KEY_CODE_NONE;
                  if Keyboard.Keyboard.Code <> SCAN_CODE_NONE then
                   begin
                    {Resolve Deadkey}
                    if not KeymapResolveDeadkey(Keymap,Keyboard.Keyboard.Code,ScanCode,Keyboard.Keyboard.Index,Index,KeyCode) then
                     begin
                      {Get Data}
                      Data.Modifiers:=Keyboard.Keyboard.Modifiers or KEYBOARD_KEYDOWN;
                      Data.ScanCode:=Keyboard.Keyboard.Code;
                      Data.KeyCode:=KeymapGetKeyCode(Keymap,Keyboard.Keyboard.Code,Keyboard.Keyboard.Index);
                      Data.CharCode:=KeymapGetCharCode(Keymap,Data.KeyCode);
                      Data.CharUnicode:=KeymapGetCharUnicode(Keymap,Data.KeyCode);

                      {Insert Data}
                      KeyboardInsertData(@Keyboard.Keyboard,@Data,True);
                     end;
                   end;

                  {Reset Deadkey}
                  Keyboard.Keyboard.Code:=SCAN_CODE_NONE;

                  {Get Data}
                  Data.Modifiers:=Modifiers or KEYBOARD_KEYDOWN;
                  Data.ScanCode:=ScanCode;
                  Data.KeyCode:=KeymapGetKeyCode(Keymap,ScanCode,Index);
                  if KeyCode <> KEY_CODE_NONE then Data.KeyCode:=KeyCode;
                  Data.CharCode:=KeymapGetCharCode(Keymap,Data.KeyCode);
                  Data.CharUnicode:=KeymapGetCharUnicode(Keymap,Data.KeyCode);

                  {$IFDEF USB_DEBUG}
                  if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Key Pressed (KeyCode=' + IntToHex(Data.KeyCode,4) + ' CharCode=' + IntToHex(Byte(Data.CharCode),2) + ' CharUnicode=' + IntToHex(Word(Data.CharUnicode),4) + ')');
                  {$ENDIF}

                  {Insert Data}
                  KeyboardInsertData(@Keyboard.Keyboard,@Data,True);
                 end;
               end;
             end
            else
             begin
              {Check Repeated}
              if HIDKeyboardCheckRepeated(Keyboard,ScanCode) then
               begin
                {$IFDEF USB_DEBUG}
                if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Key Repeated (ScanCode=' + IntToStr(ScanCode) + ' Modifiers=' + IntToHex(Modifiers,8) + ' Index=' + IntToStr(Index) + ')');
                {$ENDIF}

                {Get Data}
                Data.Modifiers:=Modifiers or KEYBOARD_KEYREPEAT;
                Data.ScanCode:=ScanCode;
                Data.KeyCode:=KeymapGetKeyCode(Keymap,ScanCode,Index);
                Data.CharCode:=KeymapGetCharCode(Keymap,Data.KeyCode);
                Data.CharUnicode:=KeymapGetCharUnicode(Keymap,Data.KeyCode);

                {Insert Data}
                KeyboardInsertData(@Keyboard.Keyboard,@Data,True);
               end;
             end;
           end;
         end;

        {Check for Keys Released}
        for Count:=0 to 5 do {6 bytes of Key data}
         begin
          {Load Keymap Index}
          Index:=Saved;

          {Get Scan Code}
          ScanCode:=Keyboard.LastReport.Keys[Count];

          {Ignore SCAN_CODE_NONE to SCAN_CODE_ERROR}
          if ScanCode > SCAN_CODE_ERROR then
           begin
            {Check for Caps Lock Shifted Key}
            if KeymapCheckCapskey(Keymap,ScanCode) then
             begin
              {Check for Caps Lock}
              if (Modifiers and (KEYBOARD_CAPS_LOCK)) <> 0 then
               begin
                {Modify Normal and Shift}
                if Index = KEYMAP_INDEX_NORMAL then
                 begin
                  Index:=KEYMAP_INDEX_SHIFT;
                 end
                else if Index = KEYMAP_INDEX_SHIFT then
                 begin
                  Index:=KEYMAP_INDEX_NORMAL;
                 end
                {Modify AltGr and Shift}
                else if Index = KEYMAP_INDEX_ALTGR then
                 begin
                  Index:=KEYMAP_INDEX_SHIFT_ALTGR;
                 end
                else if Index = KEYMAP_INDEX_SHIFT_ALTGR then
                 begin
                  Index:=KEYMAP_INDEX_ALTGR;
                 end;
               end;
             end;

            {Check for Numeric Keypad Key}
            if (ScanCode >= SCAN_CODE_KEYPAD_FIRST) and (ScanCode <= SCAN_CODE_KEYPAD_LAST) then
             begin
              {Check for Num Lock}
              if (Modifiers and (KEYBOARD_NUM_LOCK)) <> 0 then
               begin
                {Check for Shift}
                if (Modifiers and (KEYBOARD_LEFT_SHIFT or KEYBOARD_RIGHT_SHIFT)) <> 0 then
                 begin
                  Index:=KEYMAP_INDEX_NORMAL;
                 end
                else
                 begin
                  Index:=KEYMAP_INDEX_SHIFT;
                 end;
               end
              else
               begin
                Index:=KEYMAP_INDEX_NORMAL;
               end;
             end;

            {Check Released}
            if HIDKeyboardCheckReleased(Keyboard,Report,ScanCode) then
             begin
              {$IFDEF USB_DEBUG}
              if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Key Released (ScanCode=' + IntToStr(ScanCode) + ' Modifiers=' + IntToHex(Modifiers,8) + ' Index=' + IntToStr(Index)+ ')');
              {$ENDIF}

              {Reset Last}
              Keyboard.LastCode:=SCAN_CODE_NONE;
              Keyboard.LastCount:=0;

              {Get Data}
              Data.Modifiers:=Modifiers or KEYBOARD_KEYUP;
              Data.ScanCode:=ScanCode;
              Data.KeyCode:=KeymapGetKeyCode(Keymap,ScanCode,Index);
              Data.CharCode:=KeymapGetCharCode(Keymap,Data.KeyCode);
              Data.CharUnicode:=KeymapGetCharUnicode(Keymap,Data.KeyCode);

              {Insert Data}
              KeyboardInsertData(@Keyboard.Keyboard,@Data,True);
             end;
           end;
         end;

        {Save Last Report}
        System.Move(Report^,Keyboard.LastReport,SizeOf(THIDKeyboardInputReport));

        {Check LEDs}
        if LEDs <> Keyboard.Keyboard.KeyboardLEDs then
         begin
          {Update LEDs}
          Status:=HIDKeyboardDeviceSetLEDs(Keyboard,Keyboard.Keyboard.KeyboardLEDs,HIDKEYBOARD_REPORTID_NONE);
          if Status <> USB_STATUS_SUCCESS then
           begin
            if USB_LOG_ENABLED then USBLogError(Request.Device,'Keyboard: Failed to set LEDs: ' + USBStatusToString(Status));
           end;
         end;
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'Keyboard: Failed report request (Status=' + USBStatusToString(Request.Status) + ', ActualSize=' + IntToStr(Request.ActualSize) + ')');

        {Update Statistics}
        Inc(Keyboard.Keyboard.ReceiveErrors);
       end;

      {Update Pending}
      Dec(Keyboard.PendingCount);

      {Check State}
      if Keyboard.Keyboard.KeyboardState = KEYBOARD_STATE_DETACHING then
       begin
        {Check Pending}
        if Keyboard.PendingCount = 0 then
         begin
          {Check Waiter}
          if Keyboard.WaiterThread <> INVALID_HANDLE_VALUE then
           begin
            {$IFDEF USB_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Detachment pending, sending message to waiter thread (Thread=' + IntToHex(Keyboard.WaiterThread,8) + ')');
            {$ENDIF}

            {Send Message}
            FillChar(Message,SizeOf(TMessage),0);
            ThreadSendMessage(Keyboard.WaiterThread,Message);
            Keyboard.WaiterThread:=INVALID_HANDLE_VALUE;
           end;
         end;
       end
      else
       begin
        {Update Pending}
        Inc(Keyboard.PendingCount);

        {$IFDEF USB_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'Keyboard: Resubmitting report request');
        {$ENDIF}

        {Resubmit Request}
        Status:=USBRequestSubmit(Request);
        if Status <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'Keyboard: Failed to resubmit report request: ' + USBStatusToString(Status));

          {Update Pending}
          Dec(Keyboard.PendingCount);
         end;
       end;
     finally
      {Release the Lock}
      MutexUnlock(Keyboard.Keyboard.Lock);
     end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(Request.Device,'Keyboard: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'Keyboard: Report request invalid');
  end;
end;

{==============================================================================}

procedure HIDKeyboardReportComplete(Request:PUSBRequest);
{Called when a USB request from a HID keyboard IN interrupt endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 WorkerSchedule(0,TWorkerTask(HIDKeyboardReportWorker),Request,nil)
end;

{==============================================================================}
{==============================================================================}
{HID Keyboard Helper Functions}
function HIDKeyboardCheckDeviceAndInterface(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
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
 for Count:=0 to HIDKEYBOARD_DEVICE_ID_COUNT - 1 do
  begin
   if (HIDKEYBOARD_DEVICE_ID[Count].idVendor = Device.Descriptor.idVendor) and (HIDKEYBOARD_DEVICE_ID[Count].idProduct = Device.Descriptor.idProduct) and (HIDKEYBOARD_DEVICE_ID[Count].bInterfaceNumber = Interrface.Descriptor.bInterfaceNumber) then
    begin
     Result:=USB_STATUS_SUCCESS;
     Exit;
    end;
  end;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function HIDKeyboardCheckPressed(Keyboard:PHIDKeyboardDevice;ScanCode:Byte):Boolean;
{Check if the passed scan code has been pressed (True if not pressed in last report)}
{Keyboard: The HID keyboard device to check for}
{ScanCode: The keyboard scan code to check}

{Note: Caller must hold the keyboard lock}
var
 Count:Integer;
begin
 {}
 Result:=True;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 for Count:=0 to 5 do {6 bytes of Key data}
  begin
   if Keyboard.LastReport.Keys[Count] = ScanCode then
    begin
     Result:=False;
     Exit;
    end;
  end;
end;

{==============================================================================}

function HIDKeyboardCheckRepeated(Keyboard:PHIDKeyboardDevice;ScanCode:Byte):Boolean;
{Check if the passed scan code was the last key pressed and if the repeat delay has expired}
{Keyboard: The HID keyboard device to check for}
{ScanCode: The keyboard scan code to check}

{Note: Caller must hold the keyboard lock}
begin
 {}
 Result:=False;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 if ScanCode = Keyboard.LastCode then
  begin
   if Keyboard.LastCount < Keyboard.Keyboard.KeyboardDelay then
    begin
     Inc(Keyboard.LastCount);
    end
   else
    begin
     Result:=True;
    end;
  end;
end;

{==============================================================================}

function HIDKeyboardCheckReleased(Keyboard:PHIDKeyboardDevice;Report:PHIDKeyboardInputReport;ScanCode:Byte):Boolean;
{Check if the passed scan code has been released (True if not pressed in current report)}
{Keyboard: The HID keyboard device to check for}
{Report: The HID keyboard report to compare against (Current)}
{ScanCode: The keyboard scan code to check}

{Note: Caller must hold the keyboard lock}
var
 Count:Integer;
begin
 {}
 Result:=True;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Report}
 if Report = nil then Exit;

 for Count:=0 to 5 do {6 bytes of Key data}
  begin
   if Report.Keys[Count] = ScanCode then
    begin
     Result:=False;
     Exit;
    end;
  end;
end;

{==============================================================================}

function HIDKeyboardDeviceSetLEDs(Keyboard:PHIDKeyboardDevice;LEDs,ReportId:Byte):LongWord;
{Set the state of the LEDs for a HID keyboard device}
{Keyboard: The HID keyboard device to set the LEDs for}
{LEDs: The LED state to set (eg KEYBOARD_LED_NUMLOCK)}
{ReportId: The report Id to set the LEDs for (eg USB_HID_REPORTID_NONE)}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
 Report:THIDKeyboardOutputReport;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Interface}
 if Keyboard.HIDInterface = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Keyboard.Keyboard.Device.DeviceData);
 if Device = nil then Exit;

 {Get Report}
 Report.LEDs:=0;
 if (LEDs and KEYBOARD_LED_NUMLOCK) <> 0 then Report.LEDs:=Report.LEDs or HIDKEYBOARD_NUMLOCK_LED;
 if (LEDs and KEYBOARD_LED_CAPSLOCK) <> 0 then Report.LEDs:=Report.LEDs or HIDKEYBOARD_CAPSLOCK_LED;
 if (LEDs and KEYBOARD_LED_SCROLLLOCK) <> 0 then Report.LEDs:=Report.LEDs or HIDKEYBOARD_SCROLLLOCK_LED;
 if (LEDs and KEYBOARD_LED_COMPOSE) <> 0 then Report.LEDs:=Report.LEDs or HIDKEYBOARD_COMPOSE_LED;
 if (LEDs and KEYBOARD_LED_KANA) <> 0 then Report.LEDs:=Report.LEDs or HIDKEYBOARD_KANA_LED;

 {Set Report}
 Result:=USBControlRequest(Device,nil,USB_HID_REQUEST_SET_REPORT,USB_BMREQUESTTYPE_TYPE_CLASS or USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,(USB_HID_REPORT_OUTPUT shl 8) or ReportId,Keyboard.HIDInterface.Descriptor.bInterfaceNumber,@Report,SizeOf(THIDKeyboardOutputReport));
end;

{==============================================================================}

function HIDKeyboardDeviceSetIdle(Keyboard:PHIDKeyboardDevice;Duration,ReportId:Byte):LongWord;
{Set the idle duration (Time between reports when no changes) for a HID keyboard device}
{Keyboard: The HID keyboard device to set the idle duration for}
{Duration: The idle duration to set (Milliseconds divided by 4)}
{ReportId: The report Id to set the idle duration for (eg USB_HID_REPORTID_NONE)}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Interface}
 if Keyboard.HIDInterface = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Keyboard.Keyboard.Device.DeviceData);
 if Device = nil then Exit;

 {Get Duration}
 Duration:=(Duration div 4);

 {Set Idle}
 Result:=USBControlRequest(Device,nil,USB_HID_REQUEST_SET_IDLE,USB_BMREQUESTTYPE_TYPE_CLASS or USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,(Duration shl 8) or ReportId,Keyboard.HIDInterface.Descriptor.bInterfaceNumber,nil,0);
end;

{==============================================================================}

function HIDKeyboardDeviceSetProtocol(Keyboard:PHIDKeyboardDevice;Protocol:Byte):LongWord;
{Set the report protocol for a HID keyboard device}
{Keyboard: The HID keyboard device to set the report protocol for}
{Protocol: The report protocol to set (eg USB_HID_PROTOCOL_REPORT)}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Interface}
 if Keyboard.HIDInterface = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Keyboard.Keyboard.Device.DeviceData);
 if Device = nil then Exit;

 {Set Protocol}
 Result:=USBControlRequest(Device,nil,USB_HID_REQUEST_SET_PROTOCOL,USB_BMREQUESTTYPE_TYPE_CLASS or USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,Protocol,Keyboard.HIDInterface.Descriptor.bInterfaceNumber,nil,0);
end;

{==============================================================================}

function HIDKeyboardDeviceGetHIDDescriptor(Keyboard:PHIDKeyboardDevice;Descriptor:PUSBHIDDescriptor):LongWord;
{Get the HID Descriptor for a HID keyboard device}
{Keyboard: The HID keyboard device to get the descriptor for}
{Descriptor: Pointer to a USB HID Descriptor structure for the returned data}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Descriptor}
 if Descriptor = nil then Exit;

 {Check Interface}
 if Keyboard.HIDInterface = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Keyboard.Keyboard.Device.DeviceData);
 if Device = nil then Exit;

 {Get Descriptor}
 Result:=USBControlRequest(Device,nil,USB_DEVICE_REQUEST_GET_DESCRIPTOR,USB_BMREQUESTTYPE_TYPE_STANDARD or USB_BMREQUESTTYPE_DIR_IN or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,(USB_HID_DESCRIPTOR_TYPE_HID shl 8),Keyboard.HIDInterface.Descriptor.bInterfaceNumber,Descriptor,SizeOf(TUSBHIDDescriptor));
end;

{==============================================================================}

function HIDKeyboardDeviceGetReportDescriptor(Keyboard:PHIDKeyboardDevice;Descriptor:Pointer;Size:LongWord):LongWord;
{Get the Report Descriptor for a HID keyboard device}
{Keyboard: The HID keyboard device to get the descriptor for}
{Descriptor: Pointer to a buffer to return the USB Report Descriptor}
{Size: The size in bytes of the buffer pointed to by Descriptor}
{Return: USB_STATUS_SUCCESS if completed or another USB error code on failure}
var
 Device:PUSBDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Keyboard}
 if Keyboard = nil then Exit;

 {Check Descriptor}
 if Descriptor = nil then Exit;

 {Check Interface}
 if Keyboard.HIDInterface = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Keyboard.Keyboard.Device.DeviceData);
 if Device = nil then Exit;

 {Get Descriptor}
 Result:=USBControlRequest(Device,nil,USB_DEVICE_REQUEST_GET_DESCRIPTOR,USB_BMREQUESTTYPE_TYPE_STANDARD or USB_BMREQUESTTYPE_DIR_IN or USB_BMREQUESTTYPE_RECIPIENT_INTERFACE,(USB_HID_DESCRIPTOR_TYPE_REPORT shl 8),Keyboard.HIDInterface.Descriptor.bInterfaceNumber,Descriptor,Size);
end;

{==============================================================================}
{==============================================================================}

initialization
 HIDKeyboardInit;

{==============================================================================}

finalization
 {Nothing}

{==============================================================================}
{==============================================================================}

end.
