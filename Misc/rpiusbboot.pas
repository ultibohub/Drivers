{
Raspberry Pi USB Boot Driver.

Copyright (C) 2021 - SoftOz Pty Ltd.

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

  Raspberry Pi - https://github.com/raspberrypi/usbboot/blob/master/main.c

References
==========


Raspberry Pi USB Boot
=====================

 USB Boot driver for Raspberry Pi, allows sending boot files and kernel to
 a Raspberry Pi A/A+/Zero/CM/CM3 over USB OTG.

 //To Do
 //RPIUSBBOOT_FILE_PATH
 //RPIUSBBOOT_WAIT_TIME

 Fo rmore information see: https://github.com/raspberrypi/usbboot

}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}

unit RPiUSBBoot;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,USB,SysUtils;

{==============================================================================}
{Local definitions}
{$DEFINE RPIUSBBOOT_DEBUG}

{==============================================================================}
const
 {RPiUSBBoot specific constants}
 RPIUSBBOOT_DRIVER_NAME = 'Raspberry Pi USB Boot Driver'; {Name of RPiUSBBoot driver}

 RPIUSBBOOT_THREAD_STACK_SIZE = SIZE_128K;                {Stack size of USB boot thread}
 RPIUSBBOOT_THREAD_PRIORITY = THREAD_PRIORITY_NORMAL;     {Priority of  USB boot thread}
 RPIUSBBOOT_THREAD_NAME = 'Raspberry Pi USB Boot';        {Name of USB boot thread}

 RPIUSBBOOT_SECOND_STAGE  = 'bootcode.bin';               {The name of the second stage boot file}
 RPIUSBBOOT_SECOND_STAGE4 = 'bootcode4.bin';              {The name of the Pi 4 second stage boot file}

 {RPiUSBBoot Vendor ID constants}
 RPIUSBBOOT_BROADCOM_VENDOR_ID = $0a5c;

 {RPiUSBBoot Device ID constants}
 RPIUSBBOOT_DEVICE_ID_COUNT = 3; {Number of supported Device IDs}

 RPIUSBBOOT_DEVICE_ID:array[0..RPIUSBBOOT_DEVICE_ID_COUNT - 1] of TUSBDeviceId = (
  (idVendor:RPIUSBBOOT_BROADCOM_VENDOR_ID;idProduct:$2763),
  (idVendor:RPIUSBBOOT_BROADCOM_VENDOR_ID;idProduct:$2764),
  (idVendor:RPIUSBBOOT_BROADCOM_VENDOR_ID;idProduct:$2711));

 {RPiUSBBoot File Server Commands}
 RPIUSBBOOT_COMMAND_FILESIZE  = 0; {Get File Size}
 RPIUSBBOOT_COMMAND_READFILE  = 1; {Read File}
 RPIUSBBOOT_COMMAND_COMPLETED = 2; {Done, exit file server mode}

 RPIUSBBOOT_COMMAND_NAMES:array[0..2] of String = (
  'RPIUSBBOOT_COMMAND_FILESIZE',
  'RPIUSBBOOT_COMMAND_READFILE',
  'RPIUSBBOOT_COMMAND_COMPLETED');

{==============================================================================}
type
 {RPiUSBBoot specific types}
 PRPiUSBBootMessage = ^TRPiUSBBootMessage;
 TRPiUSBBootMessage = record
  Len:LongWord;                     {Size of bootcode.bin}
  Signature:array[0..19] of Char;   {Signature for signed boot}
 end;

 PRPiUSBFileMessage = ^TRPiUSBFileMessage;
 TRPiUSBFileMessage = record
  Command:LongWord;                {Command received (eg RPIUSBBOOT_COMMAND_FILESIZE)}
  Filename:array[0..255] of Char;  {Filename for command (Name only, no path)}
 end;

 PRPiUSBBootDevice = ^TRPiUSBBootDevice;
 TRPiUSBBootDevice = record
  {Device Properties}
  Lock:TMutexHandle;
  Thread:TThreadHandle;
  {USB Properties}
  Device:PUSBDevice;
  BootInterface:PUSBInterface;
  TransmitEndpoint:PUSBEndpointDescriptor;
  PendingCount:LongWord;                    {Number of USB requests pending for this device} //To Do //Not Required ?
  WaiterThread:TThreadId;                   {Thread waiting for pending requests to complete (for device detachment)} //To Do //Not Required ?
 end;

{==============================================================================}
var
 {RPiUSBBoot specific variables}
 RPIUSBBOOT_FILE_PATH:String = 'C:\MSD';    {The path to the files to be served}
 RPIUSBBOOT_WAIT_TIME:LongWord = 5;         {Number of seconds to wait for file to be available}

{==============================================================================}
{Initialization Functions}
procedure RPiUSBBootInit;

{==============================================================================}
{RPiUSBBoot USB Functions}
function RPiUSBBootDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
function RPiUSBBootDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

{==============================================================================}
{RPiUSBBoot Helper Functions}
function RPiUSBBootCheckDevice(Device:PUSBDevice):LongWord;

function RPiUSBBootSecondStageExecute(BootDevice:PRPiUSBBootDevice):PtrInt;
function RPiUSBBootFileServerExecute(BootDevice:PRPiUSBBootDevice):PtrInt;

function RPiUSBBootRead(BootDevice:PRPiUSBBootDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
function RPiUSBBootWriteSize(BootDevice:PRPiUSBBootDevice;Size:LongWord):LongWord;
function RPiUSBBootWriteData(BootDevice:PRPiUSBBootDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;

{==============================================================================}
{==============================================================================}

implementation

{==============================================================================}
{==============================================================================}
var
 {RPiUSBBoot specific variables}
 RPiUSBBootInitialized:Boolean;

 RPiUSBBootDriver:PUSBDriver;  {RPiUSBBoot Driver interface (Set by RPiUSBBootInit)}

{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure RPiUSBBootInit;
var
 Status:LongWord;
 WorkInt:LongWord;
 WorkBuffer:String;
begin
 {}
 {Check Initialized}
 if RPiUSBBootInitialized then Exit;

 {Create RPiUSBBoot Driver}
 RPiUSBBootDriver:=USBDriverCreate;
 if RPiUSBBootDriver <> nil then
  begin
   {Update RPiUSBBoot Driver}
   {Driver}
   RPiUSBBootDriver.Driver.DriverName:=RPIUSBBOOT_DRIVER_NAME;
   {USB}
   RPiUSBBootDriver.DriverBind:=RPiUSBBootDriverBind;
   RPiUSBBootDriver.DriverUnbind:=RPiUSBBootDriverUnbind;

   {Register RPiUSBBoot Driver}
   Status:=USBDriverRegister(RPiUSBBootDriver);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'RPiUSBBoot: Failed to register RPiUSBBoot driver: ' + USBStatusToString(Status));
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'RPiUSBBoot: Failed to create RPiUSBBoot driver');
  end;

 {Check Environment Variables}
 {RPIUSBBOOT_FILE_PATH}
 WorkBuffer:=SysUtils.GetEnvironmentVariable('RPIUSBBOOT_FILE_PATH');
 if Length(WorkBuffer) <> 0 then RPIUSBBOOT_FILE_PATH:=WorkBuffer;

 {RPIUSBBOOT_WAIT_TIME}
 WorkInt:=StrToIntDef(SysUtils.GetEnvironmentVariable('RPIUSBBOOT_WAIT_TIME'),0);
 if WorkInt <> 0 then RPIUSBBOOT_WAIT_TIME:=WorkInt;

 RPiUSBBootInitialized:=True;
end;

{==============================================================================}
{==============================================================================}
{RPiUSBBoot USB Functions}
function RPiUSBBootDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Bind the RPiUSBBoot driver to a USB device if it is suitable}
{Device: The USB device to attempt to bind to}
{Interrface: The USB interface to attempt to bind to (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed, USB_STATUS_DEVICE_UNSUPPORTED if unsupported or another error code on failure}
var
 Status:LongWord;
 Message:TMessage;
 ThreadName:String;
 InterfaceIndex:Byte;
 EndpointIndex:Byte;
 BootDevice:PRPiUSBBootDevice;
 BootInterface:PUSBInterface;
 TransmitEndpoint:PUSBEndpointDescriptor;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Attempting to bind USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Check Interface (Bind to device only)}
 if Interrface <> nil then
  begin
   {$IFDEF RPIUSBBOOT_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Interface bind not supported by driver');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check RPiUSBBoot Device}
 if RPiUSBBootCheckDevice(Device) <> USB_STATUS_SUCCESS then
  begin
   {$IFDEF RPIUSBBOOT_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Device not found in supported device list');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check Interface Count}
 if Device.Configuration.Descriptor.bNumInterfaces = 1 then
  begin
   {Original source says: "Handle 2837 where it can start with two interfaces, the first is
                           mass storage the second is the vendor interface for programming"}
   InterfaceIndex:=0;
   EndpointIndex:=0; {Address 1}
  end
 else
  begin
   InterfaceIndex:=1;
   EndpointIndex:=0; {Address 3}
  end;

 {Check Interface}
 BootInterface:=USBDeviceFindInterfaceByIndex(Device,InterfaceIndex);
 if BootInterface = nil then
  begin
   {$IFDEF RPIUSBBOOT_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Device has no available interface');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 {$IFDEF RPIUSBBOOT_DEBUG}
  if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Interface.bInterfaceNumber=' + IntToStr(BootInterface.Descriptor.bInterfaceNumber));
 {$ENDIF}

 {Check Bulk OUT Endpoint}
 TransmitEndpoint:=USBDeviceFindEndpointByIndex(Device,BootInterface,EndpointIndex);
 if TransmitEndpoint = nil then
  begin
   {$IFDEF RPIUSBBOOT_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Device has no BULK OUT endpoint');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;
 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: BULK OUT Endpoint Count=' + IntToStr(USBDeviceCountEndpointsByType(Device,BootInterface,USB_DIRECTION_OUT,USB_TRANSFER_TYPE_BULK)));
 {$ENDIF}

 {Check Configuration}
 if Device.ConfigurationValue = 0 then
  begin
   {$IFDEF RPIUSBBOOT_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'Assigning configuration ' + IntToStr(Device.Configuration.Descriptor.bConfigurationValue) + ' (' + IntToStr(Device.Configuration.Descriptor.bNumInterfaces) + ' interfaces available)');
   {$ENDIF}

   {Set Configuration}
   Status:=USBDeviceSetConfiguration(Device,Device.Configuration.Descriptor.bConfigurationValue);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(Device,'Failed to set device configuration: ' + USBStatusToString(Status));

     {Return Result}
     Result:=Status;
     Exit;
    end;
  end;

 {Create Boot Device}
 BootDevice:=AllocMem(SizeOf(TRPiUSBBootDevice));
 if BootDevice = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'RPiUSBBoot: Failed to allocate new USB boot device');

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Update Boot Device}
 BootDevice.Lock:=INVALID_HANDLE_VALUE;
 BootDevice.Thread:=INVALID_HANDLE_VALUE;
 BootDevice.Device:=Device;
 BootDevice.BootInterface:=BootInterface;
 BootDevice.TransmitEndpoint:=TransmitEndpoint;
 BootDevice.WaiterThread:=INVALID_HANDLE_VALUE; //To Do //Not Required ?

 {Allocate Lock}
 BootDevice.Lock:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
 if BootDevice.Lock = INVALID_HANDLE_VALUE then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'RPiUSBBoot: Failed to create USB boot device lock');

   {Free Boot Device}
   FreeMem(BootDevice);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {$IFDEF RPIUSBBOOT_DEBUG}
  if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Descriptor.iSerialNumber=' + IntToStr(Device.Descriptor.iSerialNumber));
 {$ENDIF}

 {Check Serial Number}
 if (Device.Descriptor.iSerialNumber = 0) or (Device.Descriptor.iSerialNumber = 3) then
  begin
   {Second Stage Boot}
   {Create Thread}
   BootDevice.Thread:=BeginThread(TThreadStart(RPiUSBBootSecondStageExecute),BootDevice,BootDevice.Thread,RPIUSBBOOT_THREAD_STACK_SIZE);

   {Setup Name}
   ThreadName:=RPIUSBBOOT_THREAD_NAME + ' (Second Stage)';
  end
 else
  begin
   {File Server}
   {Create Thread}
   BootDevice.Thread:=BeginThread(TThreadStart(RPiUSBBootFileServerExecute),BootDevice,BootDevice.Thread,RPIUSBBOOT_THREAD_STACK_SIZE);

   {Setup Name}
   ThreadName:=RPIUSBBOOT_THREAD_NAME + ' (File Server)';
  end;

 {Check Thread}
 if BootDevice.Thread = INVALID_HANDLE_VALUE then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'RPiUSBBoot: Failed to create USB boot device thread');

   {Destroy Lock}
   MutexDestroy(BootDevice.Lock);

   {Free Boot Device}
   FreeMem(BootDevice);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end
 else
  begin
   ThreadSetPriority(BootDevice.Thread,RPIUSBBOOT_THREAD_PRIORITY);
   ThreadSetName(BootDevice.Thread,ThreadName);
  end;

 {Update Device}
 Device.DriverData:=BootDevice;

 {Signal the Thread}
 FillChar(Message,SizeOf(TMessage),0);
 ThreadSendMessage(BootDevice.Thread,Message);

 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

function RPiUSBBootDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Unbind the RPiUSBBoot driver from a USB device}
{Device: The USB device to unbind from}
{Interrface: The USB interface to unbind from (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Thread:TThreadHandle;
 BootDevice:PRPiUSBBootDevice;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface <> nil then Exit;

 {Check Driver}
 if Device.Driver <> RPiUSBBootDriver then Exit;

 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'RPiUSBBoot: Unbinding USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Get Boot Device}
 BootDevice:=PRPiUSBBootDevice(Device.DriverData);
 if BootDevice = nil then Exit;

 {Acquire the Lock}
 if MutexLock(BootDevice.Lock) <> ERROR_SUCCESS then Exit;

 {Check Thread}
 Thread:=BootDevice.Thread;
 if Thread <> INVALID_HANDLE_VALUE then
  begin
   {Wait for Thread}
   ThreadWaitTerminate(Thread,INFINITE);
   BootDevice.Thread:=INVALID_HANDLE_VALUE;
  end;

 {Release the Lock}
 MutexUnlock(BootDevice.Lock);
 BootDevice.Lock:=INVALID_HANDLE_VALUE;

 {Destroy Lock}
 MutexDestroy(BootDevice.Lock);

 {Update Device}
 Device.DriverData:=nil;

 {Free Boot Device}
 FreeMem(BootDevice);

 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}
{==============================================================================}
{RPiUSBBoot Helper Functions}
function RPiUSBBootCheckDevice(Device:PUSBDevice):LongWord;
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

 {Check Device IDs}
 for Count:=0 to RPIUSBBOOT_DEVICE_ID_COUNT - 1 do
  begin
   if (RPIUSBBOOT_DEVICE_ID[Count].idVendor = Device.Descriptor.idVendor) and (RPIUSBBOOT_DEVICE_ID[Count].idProduct = Device.Descriptor.idProduct) then
    begin
     Result:=USB_STATUS_SUCCESS;
     Exit;
    end;
  end;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function RPiUSBBootSecondStageExecute(BootDevice:PRPiUSBBootDevice):PtrInt;
{Second Stage Boot handler thread for the RPiUSBBoot device}

{Note: Not intended to be called directly by applications}
var
 Buffer:Pointer;
 Handle:THandle;
 Count:LongWord;
 Status:LongWord;
 PathName:String;
 FileName:String;
 Timeout:LongWord;
 Message:TMessage;
 BootMessage:TRPiUSBBootMessage;
begin
 {}
 Result:=0;
 try
  {Check Boot Device}
  if BootDevice = nil then Exit;
  try
   {$IFDEF RPIUSBBOOT_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Second Stage Boot Thread (ThreadID = ' + IntToHex(ThreadID,8) + ')');
   {$ENDIF}

   {Wait for Signal}
   FillChar(Message,SizeOf(TMessage),0);
   if ThreadReceiveMessage(Message) <> ERROR_SUCCESS then Exit;

   {Get Path}
   PathName:=RPIUSBBOOT_FILE_PATH;
   if Length(PathName) <> 0 then
    begin
     {Check Path}
     if PathName[Length(PathName)] <> DirectorySeparator then
      begin
       PathName:=PathName + DirectorySeparator;
      end;

     {Get File}
     FileName:=RPIUSBBOOT_SECOND_STAGE;
     if BootDevice.Device.Descriptor.idProduct = $2711 then FileName:=RPIUSBBOOT_SECOND_STAGE4;

     {Wait File}
     Timeout:=RPIUSBBOOT_WAIT_TIME;
     while not FileExists(PathName + FileName) do
      begin
       Sleep(1000);

       Dec(Timeout);
       if Timeout < 1 then Break;
      end;

     {Check File}
     if FileExists(PathName + FileName) then
      begin
       {$IFDEF RPIUSBBOOT_DEBUG}
       if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Opening file "' + PathName + FileName + '"');
       {$ENDIF}

       {Open File}
       Handle:=FileOpen(PathName + FileName,fmOpenRead or fmShareDenyNone);
       if Handle <> INVALID_HANDLE_VALUE then
        begin
         try
          {Prepare Message}
          FillChar(BootMessage,SizeOf(TRPiUSBBootMessage),0);

          {Get Length}
          BootMessage.Len:=FileSeek(Handle,0,fsFromEnd);
          FileSeek(Handle,0,fsFromBeginning);

          {$IFDEF RPIUSBBOOT_DEBUG}
          if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Allocating buffer of ' + IntToStr(BootMessage.Len) + ' bytes');
          {$ENDIF}

          {Allocate Buffer}
          Buffer:=USBBufferAllocate(BootDevice.Device,BootMessage.Len);
          if Buffer <> nil then
           begin
            try
             {$IFDEF RPIUSBBOOT_DEBUG}
             if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Reading ' + IntToStr(BootMessage.Len) + ' bytes from file');
             {$ENDIF}

             {Read File}
             if FileRead(Handle,Buffer^,BootMessage.Len) = BootMessage.Len then
              begin
               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Writing ' + IntToStr(SizeOf(TRPiUSBBootMessage)) + ' bytes from boot message');
               {$ENDIF}

               {Write Boot Message}
               Count:=0;
               if RPiUSBBootWriteData(BootDevice,@BootMessage,SizeOf(TRPiUSBBootMessage),Count) <> USB_STATUS_SUCCESS then
                begin
                 if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to write boot message to device');
                 Exit;
                end;
               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Wrote ' + IntToStr(Count) + ' bytes from boot message');
               {$ENDIF}

               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Writing ' + IntToStr(BootMessage.Len) + ' bytes from file');
               {$ENDIF}

               {Write File}
               Count:=0;
               if RPiUSBBootWriteData(BootDevice,Buffer,BootMessage.Len,Count) <> USB_STATUS_SUCCESS then
                begin
                 if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to write boot file to device');
                 Exit;
                end;
               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Wrote ' + IntToStr(Count) + ' bytes from file');
               {$ENDIF}

               {Wait 1 second}
               Sleep(1000);

               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Reading ' + IntToStr(SizeOf(LongWord)) + ' bytes from device');
               {$ENDIF}

               {Read Result}
               Count:=0;
               if RPiUSBBootRead(BootDevice,@Status,SizeOf(LongWord),Count) <> USB_STATUS_SUCCESS then
                begin
                 if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to read status from device');
                 Exit;
                end;
               {$IFDEF RPIUSBBOOT_DEBUG}
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Read ' + IntToStr(Count) + ' bytes from device');
               if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Status = 0x' + IntToHex(Status,8));
               {$ENDIF}

               {Check Status}
               if Status <> 0 then
                begin
                 if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Boot device reported failure: Status = 0x' + IntToHex(Status,8));
                 Exit;
                end;

               {Wait 1 second}
               Sleep(1000);
              end
             else
              begin
               if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to read ' + IntToStr(BootMessage.Len) + ' bytes from file');
              end;
            finally
             {Release Buffer}
             USBBufferRelease(Buffer);
            end;
           end
          else
           begin
            if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to allocate buffer of ' + IntToStr(BootMessage.Len) + ' bytes');
           end;
         finally
          {Close File}
          FileClose(Handle);
         end;
        end
       else
        begin
         if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to open file "' + FileName + '"');
        end;
      end
     else
      begin
       if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: File "' + FileName + '" not found in path "' + PathName + '"');
      end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Path "' + PathName + '" not found');
    end;

  finally
   {Reset Thread Handle}
   BootDevice.Thread:=INVALID_HANDLE_VALUE;
  end;
 except
  on E: Exception do
   begin
    if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Second Stage Boot Thread: Exception: ' + E.Message + ' at ' + IntToHex(LongWord(ExceptAddr),8));
   end;
 end;
end;

{==============================================================================}

function RPiUSBBootFileServerExecute(BootDevice:PRPiUSBBootDevice):PtrInt;
{File Server handler thread for the RPiUSBBoot device}

{Note: Not intended to be called directly by applications}
var
 Buffer:Pointer;
 Handle:THandle;
 Size:LongWord;
 Count:LongWord;
 Status:LongWord;
 Message:TMessage;
 Filename:String;
 WorkBuffer:String;
 FileMessage:TRPiUSBFileMessage;
begin
 {}
 Result:=0;
 try
  {Check Boot Device}
  if BootDevice = nil then Exit;

  {Setup Defaults}
  Handle:=INVALID_HANDLE_VALUE;
  try
   {$IFDEF RPIUSBBOOT_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: File Server Thread (ThreadID = ' + IntToHex(ThreadID,8) + ')');
   {$ENDIF}

   {Wait for Signal}
   FillChar(Message,SizeOf(TMessage),0);
   if ThreadReceiveMessage(Message) <> ERROR_SUCCESS then Exit;

   {Get Path}
   WorkBuffer:=RPIUSBBOOT_FILE_PATH;
   if Length(WorkBuffer) <> 0 then
    begin
     {Check Path}
     if WorkBuffer[Length(WorkBuffer)] <> DirectorySeparator then
      begin
       WorkBuffer:=WorkBuffer + DirectorySeparator;
      end;

     while True do
      begin
       {$IFDEF RPIUSBBOOT_DEBUG}
       if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Reading ' + IntToStr(SizeOf(TRPiUSBFileMessage)) + ' byte message from device');
       {$ENDIF}

       {Wait for message}
       Count:=0;
       Status:=RPiUSBBootRead(BootDevice,@FileMessage,SizeOf(TRPiUSBFileMessage),Count);
       if (Status <> USB_STATUS_SUCCESS) and (Status <> USB_STATUS_TIMEOUT) then
        begin
         {Error}
         if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to read message from device');
         Exit;
        end;
       if Status = USB_STATUS_SUCCESS then
        begin
         {Success}
         {$IFDEF RPIUSBBOOT_DEBUG}
         if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Read ' + IntToStr(Count) + ' bytes from device');
         {$ENDIF}

         {Check Filename}
         if StrLen(FileMessage.Filename) = 0 then
          begin
           {Null filename means completed}
           Count:=0;
           RPiUSBBootWriteData(BootDevice,nil,0,Count);

           {Break (Completed)}
           Break;
          end;

         {Get Filename}
         Filename:=FileMessage.Filename;

         {Check Command}
         case FileMessage.Command of
          RPIUSBBOOT_COMMAND_FILESIZE:begin
            {Get File Size}
            {Check Handle}
            if Handle <> INVALID_HANDLE_VALUE then
             begin
              {Close File}
              FileClose(Handle);
             end;

            {Check File}
            if FileExists(WorkBuffer + Filename) then
             begin
              {Open File}
              Handle:=FileOpen(WorkBuffer + Filename,fmOpenRead or fmShareDenyNone);
              if Handle <> INVALID_HANDLE_VALUE then
               begin
                {Get Size}
                Size:=FileSeek(Handle,0,fsFromEnd);
                FileSeek(Handle,0,fsFromBeginning);

                {$IFDEF RPIUSBBOOT_DEBUG}
                if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Size of ' + Filename + ' is ' + IntToStr(Size) + ' bytes');
                {$ENDIF}

                {Write Size}
                Count:=0;
                if RPiUSBBootWriteSize(BootDevice,Size) <> USB_STATUS_SUCCESS then
                 begin
                  if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to write size to device');
                  Exit;
                 end;
               end
              else
               begin
                {$IFDEF RPIUSBBOOT_DEBUG}
                if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Failed to open file ' + Filename);
                {$ENDIF}

                {Failed to open file}
                Count:=0;
                RPiUSBBootWriteData(BootDevice,nil,0,Count);
               end;
             end
            else
             begin
              {$IFDEF RPIUSBBOOT_DEBUG}
              if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: File ' + Filename + ' not found');
              {$ENDIF}

              {File not found}
              Count:=0;
              RPiUSBBootWriteData(BootDevice,nil,0,Count);
             end;
           end;
          RPIUSBBOOT_COMMAND_READFILE:begin
            {Read File}
            {Check Handle}
            if Handle <> INVALID_HANDLE_VALUE then
             begin
              {$IFDEF RPIUSBBOOT_DEBUG}
              if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Read from ' + Filename);
              {$ENDIF}

              {Get Size}
              Size:=FileSeek(Handle,0,fsFromEnd);
              FileSeek(Handle,0,fsFromBeginning);

              {Allocate Buffer}
              Buffer:=USBBufferAllocate(BootDevice.Device,Size);
              if Buffer <> nil then
               begin
                try
                 {Read File}
                 if FileRead(Handle,Buffer^,Size) = Size then
                  begin
                   {$IFDEF RPIUSBBOOT_DEBUG}
                   if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Writing ' + IntToStr(Size) + ' bytes from file');
                   {$ENDIF}

                   {Write File}
                   Count:=0;
                   if RPiUSBBootWriteData(BootDevice,Buffer,Size,Count) <> USB_STATUS_SUCCESS then
                    begin
                     if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to write file to device');
                     Exit;
                    end;
                   {$IFDEF RPIUSBBOOT_DEBUG}
                   if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Wrote ' + IntToStr(Count) + ' bytes from file');
                   {$ENDIF}

                   {Close File}
                   FileClose(Handle);
                   Handle:=INVALID_HANDLE_VALUE;
                  end
                 else
                  begin
                   {Failed to read file}
                   if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to read file ' + Filename);

                   Count:=0;
                   RPiUSBBootWriteData(BootDevice,nil,0,Count);

                   {Exit (Failed)}
                   Exit;
                  end;
                finally
                 {Release Buffer}
                 USBBufferRelease(Buffer);
                end;
               end
              else
               begin
                {Failed to allocate buffer}
                if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Failed to allocate buffer for file ' + Filename);

                Count:=0;
                RPiUSBBootWriteData(BootDevice,nil,0,Count);

                {Exit (Failed)}
                Exit;
               end;
             end
            else
             begin
              {$IFDEF RPIUSBBOOT_DEBUG}
              if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: File ' + Filename + ' not found');
              {$ENDIF}

              {File not found}
              Count:=0;
              RPiUSBBootWriteData(BootDevice,nil,0,Count);
             end;
           end;
          RPIUSBBOOT_COMMAND_COMPLETED:begin
            {Completed}
            {Break (Completed)}
            Break;
           end;
         end;
        end
       else
        begin
         {Timeout}
         Sleep(1000);
        end;
      end;
    end;

  finally
   {Check Handle}
   if Handle <> INVALID_HANDLE_VALUE then
    begin
     {Close File}
     FileClose(Handle);
    end;

   {Reset Thread Handle}
   BootDevice.Thread:=INVALID_HANDLE_VALUE;
  end;
 except
  on E: Exception do
   begin
    if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: File Server Thread: Exception: ' + E.Message + ' at ' + IntToHex(LongWord(ExceptAddr),8));
   end;
 end;
end;

{==============================================================================}

function RPiUSBBootRead(BootDevice:PRPiUSBBootDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
{Perform a USB IN transfer (Control) from the RPi USB Boot device}
{BootDevice: The USB Boot Device structure representing the device to read from}
{Buffer: Pointer to a buffer to receive the data}
{Size: The size of the data to receive}
{Count: On return holds the count of bytes received}
{Return: USB_STATUS_SUCCESS on completion or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Defaults}
 Count:=0;

 {Check Boot Device}
 if BootDevice = nil then Exit;

 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Read ' + IntToStr(Size) + ' bytes');
 {$ENDIF}

 {Acquire the Lock}
 if MutexLock(BootDevice.Lock) <> ERROR_SUCCESS then Exit;
 try
  {Send Control Transfer}
  Result:=USBControlTransfer(BootDevice.Device,nil,0,USB_BMREQUESTTYPE_DIR_IN or USB_BMREQUESTTYPE_TYPE_VENDOR or USB_BMREQUESTTYPE_RECIPIENT_DEVICE,Size and $FFFF,Size shr 16,Buffer,Size,Count,3000); {3 second timeout}
  if Result <> USB_STATUS_SUCCESS then
   begin
    if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Read control transfer failed: Result = ' + USBStatusToString(Result));
    Exit;
   end;
 finally
  {Release the Lock}
  MutexUnlock(BootDevice.Lock);
 end;
end;

{==============================================================================}

function RPiUSBBootWriteSize(BootDevice:PRPiUSBBootDevice;Size:LongWord):LongWord;
{Perform a USB OUT transfer (Control) to the RPi USB Boot device}
{BootDevice: The USB Boot Device structure representing the device to read from}
{Size: The size of the data to receive}
{Return: USB_STATUS_SUCCESS on completion or another error code on failure}
var
 Count:LongWord;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Defaults}
 Count:=0;

 {Check Boot Device}
 if BootDevice = nil then Exit;

 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Write Size ' + IntToStr(Size) + ' bytes');
 {$ENDIF}

 {Acquire the Lock}
 if MutexLock(BootDevice.Lock) <> ERROR_SUCCESS then Exit;
 try
  {Send Control Transfer}
  Result:=USBControlTransfer(BootDevice.Device,nil,0,USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_TYPE_VENDOR or USB_BMREQUESTTYPE_RECIPIENT_DEVICE,Size and $FFFF,Size shr 16,nil,0,Count,2000); {2 second timeout}
  if Result <> USB_STATUS_SUCCESS then
   begin
    if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Write control transfer failed: Result = ' + USBStatusToString(Result));
    Exit;
   end;
 finally
  {Release the Lock}
  MutexUnlock(BootDevice.Lock);
 end;
end;

{==============================================================================}

function RPiUSBBootWriteData(BootDevice:PRPiUSBBootDevice;Buffer:Pointer;Size:LongWord;var Count:LongWord):LongWord;
{Perform a USB OUT transfer (Control / Bulk) to the RPi USB Boot device}
{BootDevice: The USB Boot Device structure representing the device to read from}
{Buffer: Pointer to the data buffer to send}
{Size: The size of the data to send}
{Count: On return holds the count of bytes sent}
{Return: USB_STATUS_SUCCESS on completion or another error code on failure}
var
 Block:LongWord;
 Offset:PtrUInt;
 Remain:LongWord;
 Counter:LongWord;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Defaults}
 Count:=0;

 {Check Boot Device}
 if BootDevice = nil then Exit;

 {$IFDEF RPIUSBBOOT_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Write Data ' + IntToStr(Size) + ' bytes');
 {$ENDIF}

 {Acquire the Lock}
 if MutexLock(BootDevice.Lock) <> ERROR_SUCCESS then Exit;
 try

  {Send Control Transfer}
  Result:=USBControlTransfer(BootDevice.Device,nil,0,USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_TYPE_VENDOR or USB_BMREQUESTTYPE_RECIPIENT_DEVICE,Size and $FFFF,Size shr 16,nil,0,Count,2000); {2 second timeout}
  if Result <> USB_STATUS_SUCCESS then
   begin
    if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Write control transfer failed: Result = ' + USBStatusToString(Result));
    Exit;
   end;

  {Reset Defaults}
  Count:=0;

  {Check Size}
  if Size > 0 then
   begin
    {Send Bulk Request}
    Block:=16384; //To do //BootDevice.Device.Host.MaxTransfer; //BootDevice.TransmitEndpoint.wMaxPacketSize; //USB_MAX_PACKET_SIZE
    {$IFDEF RPIUSBBOOT_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(BootDevice.Device,'RPiUSBBoot: Bulk transfer Block = ' + IntToStr(Block));
    {$ENDIF}
    Offset:=0;
    Remain:=Size;
    while Remain > 0 do
     begin
      if Remain > Block then
       begin
        Counter:=0;
        Result:=USBBulkTransfer(BootDevice.Device,BootDevice.TransmitEndpoint,Buffer + Offset,Block,Counter,100000); {100 second timeout}
        if Result <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Write bulk transfer failed: Result = ' + USBStatusToString(Result));
          Exit;
         end;

        Inc(Offset,Block);
        Dec(Remain,Block);
       end
      else
       begin
        Counter:=0;
        Result:=USBBulkTransfer(BootDevice.Device,BootDevice.TransmitEndpoint,Buffer + Offset,Remain,Counter,100000); {100 second timeout}
        if Result <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(BootDevice.Device,'RPiUSBBoot: Write bulk transfer failed: Result = ' + USBStatusToString(Result));
          Exit;
         end;

        Inc(Offset,Remain);
        Dec(Remain,Remain);
       end;

      Inc(Count,Counter);
     end;
   end;
 finally
  {Release the Lock}
  MutexUnlock(BootDevice.Lock);
 end;
end;

{==============================================================================}
{==============================================================================}

initialization
 RPiUSBBootInit;

{==============================================================================}

finalization
 {Nothing}

{==============================================================================}
{==============================================================================}

end.
