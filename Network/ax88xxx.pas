{
ASIX AX88XXX based USB 2.0 Ethernet Driver.

Copyright (C) 2023 - SoftOz Pty Ltd.

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

  Linux - \drivers\net\usb\asix_devices.c - Copyright (C) 2003-2006 David Hollis and others
  Linux - \drivers\net\usb\ax88172a.c - Copyright (C) 2012 OMICRON electronics GmbH

References
==========


ASIX AX88XXX
============

 This driver supports the following ASIX AX88X7X based USB 2.0 Ethernet Adapters:

  Linksys USB200M
  Netgear FA120
  DLink DUB-E100
  Intellinet, ST Lab USB Ethernet
  Hawking UF200, TrendNet TU2-ET100
  Billionton Systems, USB2AR
  Billionton Systems, GUSB2AM-1G-B
  ATEN UC210T
  Buffalo LUA-U2-KTX
  Buffalo LUA-U2-GT 10/100/1000
  Sitecom LN-029 "USB 2.0 10/100 Ethernet adapter"
  Sitecom LN-031 "USB 2.0 10/100/1000 Ethernet adapter"
  Sitecom LN-028 "USB 2.0 10/100/1000 Ethernet adapter"
  Corega FEther USB2-TX
  Surecom EP-1427X-2
  goodway corp usb gwusb2e
  JVC MP-PRX1 Port Replicator
  Lenovo U2L100P 10/100
  ASIX AX88772B 10/100
  ASIX AX88772 10/100
  ASIX AX88178 10/100/1000
  Logitec LAN-GTJ/U2A
  Linksys USB200M Rev 2
  0Q0 cable ethernet
  DLink DUB-E100 H/W Ver B1
  DLink DUB-E100 H/W Ver B1 Alternate
  DLink DUB-E100 H/W Ver C1
  Linksys USB1000
  IO-DATA ETG-US2
  Belkin F5D5055
  Apple USB Ethernet Adapter
  Cables-to-Go USB Ethernet Adapter
  ABOCOM for pci
  ASIX 88772a
  Asus USB Ethernet Adapter
  ASIX 88172a demo board
  USBLINK HG20F9 "USB 2.0 LAN"

 Additional devices are also possibly supported because they are simply one of the above that
 has been rebadged and sold under a different name, for example these two devices from Adafruit

  https://www.adafruit.com/product/2992
  https://www.adafruit.com/product/2909

 appear internally as the Cables-to-Go USB Ethernet Adapter and are supported by this driver.


 The following ASIC AX88179/178A based USB 3.0 Ethernet Adapters are not currently supported:

  //To Do

}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}
{$rangechecks off} {Disable range checking}

unit AX88XXX;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,USB,Network,SysUtils;

{==============================================================================}
{Local definitions}
{--$DEFINE AX88XXX_DEBUG}

//To Do //Multicast support //asix_set_multicast

//To Do //Additional models and Default behaviour //AX88XXXGetModelInfo/AX88172StartDevice/AX88172ResetLink
                                                  //AX88178StartDevice/AX88178ResetDevice/AX88178ResetLink

//To Do //Comments //See: ???

{==============================================================================}
const
 {AX88XXX specific constants}
 AX88XXX_NETWORK_DESCRIPTION = 'ASIX AX88XXX USB Ethernet Adapter';  {Description of AX88XXX device}

 AX88XXX_DRIVER_NAME = 'ASIX AX88XXX USB Ethernet Adapter Driver'; {Name of AX88XXX driver}

type
 {AX88XXX Device ID type}
 PAX88XXXDeviceId = ^TAX88XXXDeviceId;
 TAX88XXXDeviceId = record
  idVendor:Word;
  idProduct:Word;
  Model:LongWord;
 end;

const
 {AX88XXX Model constants}
 AX88XXX_MODEL_NONE = 0;
 AX88XXX_MODEL_AX8817X = 1;
 AX88XXX_MODEL_AX88178 = 2;
 AX88XXX_MODEL_AX88772B = 3;
 AX88XXX_MODEL_AX88772 = 4;
 AX88XXX_MODEL_AX88172A = 5;
 AX88XXX_MODEL_NETGEAR_FA120 = 6;
 AX88XXX_MODEL_DLINK_DUB_E100 = 7;
 AX88XXX_MODEL_HAWKING_UF200 = 8;
 AX88XXX_MODEL_HG20F9 = 9;

 {AX88XXX Device ID constants}
 AX88XXX_DEVICE_ID_COUNT = 37; {Number of supported Device IDs}

 AX88XXX_DEVICE_ID:array[0..AX88XXX_DEVICE_ID_COUNT - 1] of TAX88XXXDeviceId = (
  (idVendor:$077b;idProduct:$2226;Model:AX88XXX_MODEL_AX8817X),  {Linksys USB200M}
  (idVendor:$0846;idProduct:$1040;Model:AX88XXX_MODEL_NETGEAR_FA120),  {Netgear FA120}
  (idVendor:$2001;idProduct:$1a00;Model:AX88XXX_MODEL_DLINK_DUB_E100),  {DLink DUB-E100}
  (idVendor:$0b95;idProduct:$1720;Model:AX88XXX_MODEL_AX8817X),  {Intellinet, ST Lab USB Ethernet}
  (idVendor:$07b8;idProduct:$420a;Model:AX88XXX_MODEL_HAWKING_UF200),  {Hawking UF200, TrendNet TU2-ET100}
  (idVendor:$08dd;idProduct:$90ff;Model:AX88XXX_MODEL_AX8817X),  {Billionton Systems, USB2AR}
  (idVendor:$08dd;idProduct:$0114;Model:AX88XXX_MODEL_AX88178),  {Billionton Systems, GUSB2AM-1G-B}
  (idVendor:$0557;idProduct:$2009;Model:AX88XXX_MODEL_AX8817X),  {ATEN UC210T}
  (idVendor:$0411;idProduct:$003d;Model:AX88XXX_MODEL_AX8817X),  {Buffalo LUA-U2-KTX}
  (idVendor:$0411;idProduct:$006e;Model:AX88XXX_MODEL_AX88178),  {Buffalo LUA-U2-GT 10/100/1000}
  (idVendor:$6189;idProduct:$182d;Model:AX88XXX_MODEL_AX8817X),  {Sitecom LN-029 "USB 2.0 10/100 Ethernet adapter"}
  (idVendor:$0df6;idProduct:$0056;Model:AX88XXX_MODEL_AX88178),  {Sitecom LN-031 "USB 2.0 10/100/1000 Ethernet adapter"}
  (idVendor:$0df6;idProduct:$061c;Model:AX88XXX_MODEL_AX88178),  {Sitecom LN-028 "USB 2.0 10/100/1000 Ethernet adapter"}
  (idVendor:$07aa;idProduct:$0017;Model:AX88XXX_MODEL_AX8817X),  {Corega FEther USB2-TX}
  (idVendor:$1189;idProduct:$0893;Model:AX88XXX_MODEL_AX8817X),  {Surecom EP-1427X-2}
  (idVendor:$1631;idProduct:$6200;Model:AX88XXX_MODEL_AX8817X),  {goodway corp usb gwusb2e}
  (idVendor:$04f1;idProduct:$3008;Model:AX88XXX_MODEL_AX8817X),  {JVC MP-PRX1 Port Replicator}
  (idVendor:$17ef;idProduct:$7203;Model:AX88XXX_MODEL_AX88772B),  {Lenovo U2L100P 10/100}
  (idVendor:$0b95;idProduct:$772b;Model:AX88XXX_MODEL_AX88772B),  {ASIX AX88772B 10/100}
  (idVendor:$0b95;idProduct:$7720;Model:AX88XXX_MODEL_AX88772),  {ASIX AX88772 10/100}
  (idVendor:$0b95;idProduct:$1780;Model:AX88XXX_MODEL_AX88178),  {ASIX AX88178 10/100/1000}
  (idVendor:$0789;idProduct:$0160;Model:AX88XXX_MODEL_AX88178),  {Logitec LAN-GTJ/U2A}
  (idVendor:$13b1;idProduct:$0018;Model:AX88XXX_MODEL_AX88772),  {Linksys USB200M Rev 2}
  (idVendor:$1557;idProduct:$7720;Model:AX88XXX_MODEL_AX88772),  {0Q0 cable ethernet}
  (idVendor:$07d1;idProduct:$3c05;Model:AX88XXX_MODEL_AX88772),  {DLink DUB-E100 H/W Ver B1}
  (idVendor:$2001;idProduct:$3c05;Model:AX88XXX_MODEL_AX88772),  {DLink DUB-E100 H/W Ver B1 Alternate}
  (idVendor:$2001;idProduct:$1a02;Model:AX88XXX_MODEL_AX88772),  {DLink DUB-E100 H/W Ver C1}
  (idVendor:$1737;idProduct:$0039;Model:AX88XXX_MODEL_AX88178),  {Linksys USB1000}
  (idVendor:$04bb;idProduct:$0930;Model:AX88XXX_MODEL_AX88178),  {IO-DATA ETG-US2}
  (idVendor:$050d;idProduct:$5055;Model:AX88XXX_MODEL_AX88178),  {Belkin F5D5055}
  (idVendor:$05ac;idProduct:$1402;Model:AX88XXX_MODEL_AX88772),  {Apple USB Ethernet Adapter}
  (idVendor:$0b95;idProduct:$772a;Model:AX88XXX_MODEL_AX88772),  {Cables-to-Go USB Ethernet Adapter}
  (idVendor:$14ea;idProduct:$ab11;Model:AX88XXX_MODEL_AX88178),  {ABOCOM for pci}
  (idVendor:$0db0;idProduct:$a877;Model:AX88XXX_MODEL_AX88772),  {ASIX 88772a}
  (idVendor:$0b95;idProduct:$7e2b;Model:AX88XXX_MODEL_AX88772B),  {Asus USB Ethernet Adapter}
  (idVendor:$0b95;idProduct:$172a;Model:AX88XXX_MODEL_AX88172A),  {ASIX 88172a demo board}
  (idVendor:$066b;idProduct:$20f9;Model:AX88XXX_MODEL_HG20F9));  {USBLINK HG20F9 "USB 2.0 LAN"}

 {AX88XXX Command constants}
 AX_CMD_SET_SW_MII = $06;
 AX_CMD_READ_MII_REG = $07;
 AX_CMD_WRITE_MII_REG = $08;
 AX_CMD_STATMNGSTS_REG = $09;
 AX_CMD_SET_HW_MII = $0a;
 AX_CMD_READ_EEPROM = $0b;
 AX_CMD_WRITE_EEPROM = $0c;
 AX_CMD_WRITE_ENABLE = $0d;
 AX_CMD_WRITE_DISABLE = $0e;
 AX_CMD_READ_RX_CTL = $0f;
 AX_CMD_WRITE_RX_CTL = $10;
 AX_CMD_READ_IPG012 = $11;
 AX_CMD_WRITE_IPG0 = $12;
 AX_CMD_WRITE_IPG1 = $13;
 AX_CMD_READ_NODE_ID = $13;
 AX_CMD_WRITE_NODE_ID = $14;
 AX_CMD_WRITE_IPG2 = $14;
 AX_CMD_WRITE_MULTI_FILTER = $16;
 AX88172_CMD_READ_NODE_ID = $17;
 AX_CMD_READ_PHY_ID = $19;
 AX_CMD_READ_MEDIUM_STATUS = $1a;
 AX_CMD_WRITE_MEDIUM_MODE = $1b;
 AX_CMD_READ_MONITOR_MODE = $1c;
 AX_CMD_WRITE_MONITOR_MODE = $1d;
 AX_CMD_READ_GPIOS = $1e;
 AX_CMD_WRITE_GPIOS = $1f;
 AX_CMD_SW_RESET = $20;
 AX_CMD_SW_PHY_STATUS = $21;
 AX_CMD_SW_PHY_SELECT = $22;
 AX_QCTCTRL = $2A;

 {AX88XXX Chipcode constants}
 AX_CHIPCODE_MASK = $70;
 AX_AX88772_CHIPCODE = $00;
 AX_AX88772A_CHIPCODE = $10;
 AX_AX88772B_CHIPCODE = $20;
 AX_HOST_EN = $01;

 {AX88XXX PHY select constants}
 AX_PHYSEL_PSEL = $01;
 AX_PHYSEL_SSMII = $00;
 AX_PHYSEL_SSEN = $10;

 {AX88XXX PHY select constants}
 AX_PHY_SELECT_MASK = (1 shl 3) or (1 shl 2);
 AX_PHY_SELECT_INTERNAL = 0;
 AX_PHY_SELECT_EXTERNAL = (1 shl 2);

 {AX88XXX Monitor constants}
 AX_MONITOR_MODE = $01;
 AX_MONITOR_LINK = $02;
 AX_MONITOR_MAGIC = $04;
 AX_MONITOR_HSFS = $10;

 {AX88172 Medium Status constants}
 AX88172_MEDIUM_FD = $02;
 AX88172_MEDIUM_TX = $04;
 AX88172_MEDIUM_FC = $10;
 AX88172_MEDIUM_DEFAULT = (AX88172_MEDIUM_FD or AX88172_MEDIUM_TX or AX88172_MEDIUM_FC);

 AX_MCAST_FILTER_SIZE = 8;
 AX_MAX_MCAST = 64;

 AX_SWRESET_CLEAR = $00;
 AX_SWRESET_RR = $01;
 AX_SWRESET_RT = $02;
 AX_SWRESET_PRTE = $04;
 AX_SWRESET_PRL = $08;
 AX_SWRESET_BZ = $10;
 AX_SWRESET_IPRL = $20;
 AX_SWRESET_IPPD = $40;

 AX88772_IPG0_DEFAULT = $15;
 AX88772_IPG1_DEFAULT = $0c;
 AX88772_IPG2_DEFAULT = $12;

 {AX88772 & AX88178 Medium Mode constants}
 AX_MEDIUM_PF = $0080;
 AX_MEDIUM_JFE = $0040;
 AX_MEDIUM_TFC = $0020;
 AX_MEDIUM_RFC = $0010;
 AX_MEDIUM_ENCK = $0008;
 AX_MEDIUM_AC = $0004;
 AX_MEDIUM_FD = $0002;
 AX_MEDIUM_GM = $0001;
 AX_MEDIUM_SM = $1000;
 AX_MEDIUM_SBP = $0800;
 AX_MEDIUM_PS = $0200;
 AX_MEDIUM_RE = $0100;

 AX88178_MEDIUM_DEFAULT = (AX_MEDIUM_PS or AX_MEDIUM_FD or AX_MEDIUM_AC or AX_MEDIUM_RFC or AX_MEDIUM_TFC or AX_MEDIUM_JFE or AX_MEDIUM_RE);

 AX88772_MEDIUM_DEFAULT = (AX_MEDIUM_FD or AX_MEDIUM_RFC or AX_MEDIUM_TFC or AX_MEDIUM_PS or AX_MEDIUM_AC or AX_MEDIUM_RE);

 {AX88772 & AX88178 RX_CTL constants}
 AX_RX_CTL_SO = $0080;
 AX_RX_CTL_AP = $0020;
 AX_RX_CTL_AM = $0010;
 AX_RX_CTL_AB = $0008;
 AX_RX_CTL_SEP = $0004;
 AX_RX_CTL_AMALL = $0002;
 AX_RX_CTL_PRO = $0001;
 AX_RX_CTL_MFB_2048 = $0000;
 AX_RX_CTL_MFB_4096 = $0100;
 AX_RX_CTL_MFB_8192 = $0200;
 AX_RX_CTL_MFB_16384 = $0300;

 AX_DEFAULT_RX_CTL = (AX_RX_CTL_SO or AX_RX_CTL_AB);

 {GPIO 0 .. 2 toggles}
 AX_GPIO_GPO0EN = $01; {GPIO0 Output enable}
 AX_GPIO_GPO_0 = $02; {GPIO0 Output value}
 AX_GPIO_GPO1EN = $04; {GPIO1 Output enable}
 AX_GPIO_GPO_1 = $08; {GPIO1 Output value}
 AX_GPIO_GPO2EN = $10; {GPIO2 Output enable}
 AX_GPIO_GPO_2 = $20; {GPIO2 Output value}
 AX_GPIO_RESERVED = $40; {Reserved}
 AX_GPIO_RSE = $80; {Reload serial EEPROM}

 AX_EEPROM_MAGIC = $deadbeef;
 AX_EEPROM_LEN = $200;

 {Model specific constants}
 PHY_MODE_MARVELL = $0000;
 MII_MARVELL_LED_CTRL = $0018;
 MII_MARVELL_STATUS = $001b;
 MII_MARVELL_CTRL = $0014;

 MARVELL_LED_MANUAL = $0019;

 MARVELL_STATUS_HWCFG = $0004;

 MARVELL_CTRL_TXDELAY = $0002;
 MARVELL_CTRL_RXDELAY = $0080;

 PHY_MODE_RTL8211CL = $000C;

 AX88772A_PHY14H  = $14;
 AX88772A_PHY14H_DEFAULT = $442C;

 AX88772A_PHY15H  = $15;
 AX88772A_PHY15H_DEFAULT = $03C8;

 AX88772A_PHY16H  = $16;
 AX88772A_PHY16H_DEFAULT = $4044;

{==============================================================================}
type
 {AX88XXX specific types}
 PAX88XXXNetwork = ^TAX88XXXNetwork;

 {AX88XXX Device Methods}
 TAX88XXXStartDevice = function(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
 TAX88XXXStopDevice = function(Network:PAX88XXXNetwork):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
 TAX88XXXResetDevice = function(Network:PAX88XXXNetwork):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
 TAX88XXXResetLink = function(Network:PAX88XXXNetwork):LongWord;{$IFDEF i386} stdcall;{$ENDIF}

 TAX88XXXReceiveData = function(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
 TAX88XXXTransmitData = function(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord;{$IFDEF i386} stdcall;{$ENDIF}

 TAX88XXXUpdateStatus = function(Network:PAX88XXXNetwork;Request:PUSBRequest):LongWord;{$IFDEF i386} stdcall;{$ENDIF}

 {AX88XXX Device}
 TAX88XXXNetwork = record
  {Network Properties}
  Network:TNetworkDevice;
  {Driver Properties}
  Model:LongWord;                               {Model type for the AX88XXX device (eg AX88XXX_MODEL_AX88772}
  StartDevice:TAX88XXXStartDevice;              {Model specific Start Device method for AX88XXX device}
  StopDevice:TAX88XXXStopDevice;                {Model specific Stop Device method for AX88XXX device}
  ResetDevice:TAX88XXXResetDevice;              {Model specific Reset Device method for AX88XXX device}
  ResetLink:TAX88XXXResetLink;                  {Model specific Reset Link method for AX88XXX device}
  ReceiveData:TAX88XXXReceiveData;              {Model specific Receive Data method for AX88XXX device}
  TransmitData:TAX88XXXTransmitData;            {Model specific Transmit Data method for AX88XXX device}
  UpdateStatus:TAX88XXXUpdateStatus;            {Model specific Update Status method for AX88XXX device}
  GPIOData:LongWord;                            {Model specific GPIO data for AX88XXX device}
  LinkStatus:LongWord;                          {Last reported link status}
  PHYLock:TMutexHandle;                         {MII PHY Lock Handle}
  PHYAddress:LongWord;                          {MII PHY Address}
  PHYIdentifier:LongWord;                       {MII PHY Identifier}
  HardwareAddress:THardwareAddress;             {Current Ethernet MAC Address}
  ReceiveRequestSize:LongWord;                  {Size of each USB receive request buffer}
  TransmitRequestSize:LongWord;                 {Size of each USB transmit request buffer}
  ReceiveEntryCount:LongWord;                   {Number of entries in the receive queue}
  TransmitEntryCount:LongWord;                  {Number of entries in the transmit queue}
  ReceivePacketCount:LongWord;                  {Maximum number of packets per receive entry}
  TransmitPacketCount:LongWord;                 {Maximum number of packets per transmit entry}
  ReceiveOverhead:LongWord;                     {Number of bytes of overhead at start of receive packet}
  TransmitOverhead:LongWord;                    {Number of bytes of overhead at start of transmit packet}
  TransmitReserved:LongWord;                    {Number of bytes reserved for padding at end of transmit packet}

  //To Do //asix_rx_fixup_info //TAX88XXXReceiveState / PAX88XXXReceiveState
  Last:PNetworkEntry;
  Header:LongWord;
  Remaining:Word;
  SplitHeader:Boolean;

  {USB Properties}
  ReceiveRequest:PUSBRequest;                   {USB request for packet receive data}
  TransmitRequest:PUSBRequest;                  {USB request for packet transmit data}
  InterruptRequest:PUSBRequest;                 {USB request for interrupt data}
  ReceiveEndpoint:PUSBEndpointDescriptor;       {Bulk IN Endpoint}
  TransmitEndpoint:PUSBEndpointDescriptor;      {Bulk OUT Endpoint}
  InterruptEndpoint:PUSBEndpointDescriptor;     {Interrupt IN Endpoint}
  PendingCount:LongWord;                        {Number of USB requests pending for this network}
  WaiterThread:TThreadId;                       {Thread waiting for pending requests to complete (for network close)}
 end;

 {AX88172 Interrupt Data}
 PAX88172InterruptData = ^TAX88172InterruptData;
 TAX88172InterruptData = packed record
  Reserved1:Word;
  Link:Byte;
  Reserved2:Word;
  Status:Byte;
  Reserved3:Word;
 end;

{==============================================================================}
{var}
 {AX88XXX specific variables}

{==============================================================================}
{Initialization Functions}
procedure AX88XXXInit;

{==============================================================================}
{AX88XXX Network Functions}
function AX88XXXNetworkOpen(Network:PNetworkDevice):LongWord;
function AX88XXXNetworkClose(Network:PNetworkDevice):LongWord;
function AX88XXXNetworkControl(Network:PNetworkDevice;Request:Integer;Argument1:PtrUInt;var Argument2:PtrUInt):LongWord;

function AX88XXXBufferAllocate(Network:PNetworkDevice;var Entry:PNetworkEntry):LongWord;
function AX88XXXBufferRelease(Network:PNetworkDevice;Entry:PNetworkEntry):LongWord;
function AX88XXXBufferReceive(Network:PNetworkDevice;var Entry:PNetworkEntry):LongWord;
function AX88XXXBufferTransmit(Network:PNetworkDevice;Entry:PNetworkEntry):LongWord;

{==============================================================================}
{AX88XXX USB Functions}
function AX88XXXDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
function AX88XXXDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;

procedure AX88XXXReceiveWorker(Request:PUSBRequest);
procedure AX88XXXReceiveComplete(Request:PUSBRequest);

procedure AX88XXXTransmitWorker(Request:PUSBRequest);
procedure AX88XXXTransmitComplete(Request:PUSBRequest);

procedure AX88XXXInterruptWorker(Request:PUSBRequest);
procedure AX88XXXInterruptComplete(Request:PUSBRequest);

{==============================================================================}
{AX88XXX Helper Functions}
function AX88XXXCheckDevice(Device:PUSBDevice;out Model:LongWord):LongWord;

function AX88XXXGetEndpoints(Device:PUSBDevice;out Interrface:PUSBInterface;out Receive,Transmit,Interrupt:PUSBEndpointDescriptor):LongWord;
function AX88XXXGetModelInfo(Network:PAX88XXXNetwork):LongWord;

function AX88XXXReadCommand(Device:PUSBDevice;Command:Byte;Value,Index,Size:Word;Data:Pointer):LongWord;
function AX88XXXWriteCommand(Device:PUSBDevice;Command:Byte;Value,Index,Size:Word;Data:Pointer):LongWord;

function AX88XXXMDIORead(Device:PUSBDevice;Address:LongWord;Location:Word;var Value:Word):LongWord;
function AX88XXXMDIOWrite(Device:PUSBDevice;Address:LongWord;Location,Value:Word):LongWord;

function AX88XXXSetSoftwareMII(Device:PUSBDevice):LongWord;
function AX88XXXSetHardwareMII(Device:PUSBDevice):LongWord;

function AX88XXXReadPHYAddress(Device:PUSBDevice;Internal:Boolean;var Address:LongWord):LongWord;
function AX88XXXGetPHYAddress(Device:PUSBDevice;var Address:LongWord):LongWord; inline;

function AX88XXXGetPHYIdentifier(Device:PUSBDevice;var Identifier:LongWord):LongWord;

function AX88XXXSoftwareReset(Device:PUSBDevice;Flags:Byte):LongWord;

function AX88XXXReadRXCTL(Device:PUSBDevice;var Value:Word):LongWord;
function AX88XXXWriteRXCTL(Device:PUSBDevice;Value:Word):LongWord;

function AX88XXXReadMediumStatus(Device:PUSBDevice;var Value:Word):LongWord;
function AX88XXXWriteMediumMode(Device:PUSBDevice;Value:Word):LongWord;

function AX88XXXWriteGPIO(Device:PUSBDevice;Value:Word;Delay:LongWord):LongWord;

function AX88XXXGetMacAddress(Device:PUSBDevice;Address:PHardwareAddress):LongWord;
function AX88XXXSetMacAddress(Device:PUSBDevice;Address:PHardwareAddress):LongWord;

{==============================================================================}
{==============================================================================}

implementation

{==============================================================================}
{==============================================================================}
var
 {AX88XXX specific variables}
 AX88XXXInitialized:Boolean;

 AX88XXXDriver:PUSBDriver;  {AX88XXX Driver interface (Set by AX88XXXInit)}

{==============================================================================}
{==============================================================================}
{AX88XXX Network Functions}
procedure AX88XXXTransmitStart(Network:PAX88XXXNetwork); forward;

{==============================================================================}
{==============================================================================}
{AX88XXX Model Specific Functions}
{AX88XXX}
function AX88XXXReceiveData(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord; forward;
function AX88XXXTransmitData(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord; forward;
function AX88XXXUpdateStatus(Network:PAX88XXXNetwork;Request:PUSBRequest):LongWord; forward;

{AX88172}
function AX88172StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord; forward;
function AX88172ResetLink(Network:PAX88XXXNetwork):LongWord; forward;

{AX88178}
function AX88178StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord; forward;
function AX88178ResetDevice(Network:PAX88XXXNetwork):LongWord; forward;
function AX88178ResetLink(Network:PAX88XXXNetwork):LongWord; forward;

{AX88772}
function AX88772StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord; forward;
function AX88772StopDevice(Network:PAX88XXXNetwork):LongWord; forward;
function AX88772ResetDevice(Network:PAX88XXXNetwork):LongWord; forward;
function AX88772ResetLink(Network:PAX88XXXNetwork):LongWord; forward;
function AX88772ResetHardware(Network:PAX88XXXNetwork):LongWord; forward;

{AX88772A}
function AX88772AResetHardware(Network:PAX88XXXNetwork):LongWord;  forward;

{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure AX88XXXInit;
{Initialize the AX88XXX unit, create and register the driver}

{Note: Called only during system startup}
var
 Status:LongWord;
begin
 {}
 {Check Initialized}
 if AX88XXXInitialized then Exit;

 {Create AX88XXX Network Driver}
 AX88XXXDriver:=USBDriverCreate;
 if AX88XXXDriver <> nil then
  begin
   {Update AX88XXX Network Driver}
   {Driver}
   AX88XXXDriver.Driver.DriverName:=AX88XXX_DRIVER_NAME;
   {USB}
   AX88XXXDriver.DriverBind:=AX88XXXDriverBind;
   AX88XXXDriver.DriverUnbind:=AX88XXXDriverUnbind;

   {Register AX88XXX Network Driver}
   Status:=USBDriverRegister(AX88XXXDriver);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to register AX88XXX driver: ' + USBStatusToString(Status));
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to create AX88XXX driver');
  end;

 AX88XXXInitialized:=True;
end;

{==============================================================================}
{==============================================================================}
{AX88XXX Network Functions}
function AX88XXXNetworkOpen(Network:PNetworkDevice):LongWord;
{Implementation of NetworkDeviceOpen for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkDeviceOpen instead}
var
 Value:Word;
 Status:LongWord;
 Device:PUSBDevice;
 Entry:PNetworkEntry;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Device.DeviceData);
 if Device = nil then Exit;

 {Acquire the Lock}
 if MutexLock(Network.Lock) = ERROR_SUCCESS then
  begin
   try
    {Check State}
    Result:=ERROR_ALREADY_OPEN;
    if Network.NetworkState <> NETWORK_STATE_CLOSED then Exit;

    {Set Result}
    Result:=ERROR_OPERATION_FAILED;

    {Start Device (Prepare)}
    if Assigned(PAX88XXXNetwork(Network).StartDevice) then
     begin
      Status:=PAX88XXXNetwork(Network).StartDevice(PAX88XXXNetwork(Network),True,False);
      if Status <> ERROR_SUCCESS then
       begin
        Result:=Status;
        Exit;
       end;
     end;

    try
     {Allocate Receive Queue Buffer}
     Network.ReceiveQueue.Buffer:=BufferCreate(SizeOf(TNetworkEntry),PAX88XXXNetwork(Network).ReceiveEntryCount + 1);
     if Network.ReceiveQueue.Buffer = INVALID_HANDLE_VALUE then
      begin
       if NETWORK_LOG_ENABLED then NetworkLogError(Network,'AX88XXX: Failed to create receive queue buffer');

       Exit;
      end;

     {Allocate Receive Queue Semaphore}
     Network.ReceiveQueue.Wait:=SemaphoreCreate(0);
     if Network.ReceiveQueue.Wait = INVALID_HANDLE_VALUE then
      begin
       if NETWORK_LOG_ENABLED then NetworkLogError(Network,'AX88XXX: Failed to create receive queue semaphore');

       Exit;
      end;

     {Allocate Receive Queue Buffers}
     Entry:=BufferIterate(Network.ReceiveQueue.Buffer,nil);
     while Entry <> nil do
      begin
       {Initialize Entry}
       Entry.Size:=PAX88XXXNetwork(Network).ReceiveRequestSize;
       Entry.Offset:=PAX88XXXNetwork(Network).ReceiveOverhead;
       Entry.Count:=0; {PAX88XXXNetwork(Network).ReceivePacketCount}

       {Allocate USB Request Buffer}
       Entry.Buffer:=USBBufferAllocate(Device,Entry.Size);
       if Entry.Buffer = nil then
        begin
         if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to allocate USB receive buffer');

         Exit;
        end;

       {Initialize Packets}
       SetLength(Entry.Packets,PAX88XXXNetwork(Network).ReceivePacketCount);

       {Initialize First Packet}
       Entry.Packets[0].Buffer:=Entry.Buffer;
       Entry.Packets[0].Data:=Entry.Buffer + Entry.Offset;
       Entry.Packets[0].Length:=Entry.Size - Entry.Offset;

       Entry:=BufferIterate(Network.ReceiveQueue.Buffer,Entry);
      end;

     {Allocate Receive Queue Entries}
     SetLength(Network.ReceiveQueue.Entries,PAX88XXXNetwork(Network).ReceiveEntryCount);

     {Allocate Transmit Queue Buffer}
     Network.TransmitQueue.Buffer:=BufferCreate(SizeOf(TNetworkEntry),PAX88XXXNetwork(Network).TransmitEntryCount + 1);
     if Network.TransmitQueue.Buffer = INVALID_HANDLE_VALUE then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to create transmit queue buffer');

       Exit;
      end;

     {Allocate Transmit Queue Semaphore}
     Network.TransmitQueue.Wait:=SemaphoreCreate(PAX88XXXNetwork(Network).TransmitEntryCount);
     if Network.TransmitQueue.Wait = INVALID_HANDLE_VALUE then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to create transmit queue semaphore');

       Exit;
      end;

     {Allocate Transmit Queue Buffers}
     Entry:=BufferIterate(Network.TransmitQueue.Buffer,nil);
     while Entry <> nil do
      begin
       {Initialize Entry}
       Entry.Size:=PAX88XXXNetwork(Network).TransmitRequestSize;
       Entry.Offset:=PAX88XXXNetwork(Network).TransmitOverhead;
       Entry.Count:=PAX88XXXNetwork(Network).TransmitPacketCount;

       {Allocate USB Request Buffer}
       Entry.Buffer:=USBBufferAllocate(Device,Entry.Size);
       if Entry.Buffer = nil then
        begin
         if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to allocate USB transmit buffer');

         Exit;
        end;

       {Initialize Packets}
       SetLength(Entry.Packets,PAX88XXXNetwork(Network).TransmitPacketCount);

       {Initialize First Packet}
       Entry.Packets[0].Buffer:=Entry.Buffer;
       Entry.Packets[0].Data:=Entry.Buffer + Entry.Offset;
       Entry.Packets[0].Length:=Entry.Size - (Entry.Offset + PAX88XXXNetwork(Network).TransmitReserved);

       Entry:=BufferIterate(Network.TransmitQueue.Buffer,Entry);
      end;

     {Allocate Transmit Queue Entries}
     SetLength(Network.TransmitQueue.Entries,PAX88XXXNetwork(Network).TransmitEntryCount);

     {Allocate Transmit Request}
     PAX88XXXNetwork(Network).TransmitRequest:=USBRequestAllocate(Device,PAX88XXXNetwork(Network).TransmitEndpoint,AX88XXXTransmitComplete,0,nil);
     if PAX88XXXNetwork(Network).TransmitRequest = nil then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to allocate transmit request');

       Exit;
      end;

     {Allocate Receive Request}
     PAX88XXXNetwork(Network).ReceiveRequest:=USBRequestAllocate(Device,PAX88XXXNetwork(Network).ReceiveEndpoint,AX88XXXReceiveComplete,0,nil);
     if PAX88XXXNetwork(Network).ReceiveRequest = nil then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to allocate receive request');

       Exit;
      end;

     {Submit Receive Request}
     {Get Entry}
     Entry:=BufferGet(Network.ReceiveQueue.Buffer);
     if Entry <> nil then
      begin
       {Update Pending}
       Inc(PAX88XXXNetwork(Network).PendingCount);

       {Update Entry}
       Entry.DriverData:=Network;

       {Initialize Request}
       USBRequestInitialize(PAX88XXXNetwork(Network).ReceiveRequest,AX88XXXReceiveComplete,Entry.Buffer,Entry.Size,Entry);

       {$IFDEF AX88XXX_DEBUG}
       if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Submitting receive request');
       {$ENDIF}

       {Submit Request}
       Status:=USBRequestSubmit(PAX88XXXNetwork(Network).ReceiveRequest);
       if Status <> USB_STATUS_SUCCESS then
        begin
         if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to submit receive request: ' + USBStatusToString(Status));

         {Update Pending}
         Dec(PAX88XXXNetwork(Network).PendingCount);

         {Update Entry}
         Entry.DriverData:=nil;

         {Free Entry}
         BufferFree(Entry);
         Exit;
        end;
      end
     else
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to get receive buffer entry');

       Exit;
      end;

     {Allocate Interrupt Request}
     PAX88XXXNetwork(Network).InterruptRequest:=USBRequestAllocate(Device,PAX88XXXNetwork(Network).InterruptEndpoint,AX88XXXInterruptComplete,PAX88XXXNetwork(Network).InterruptEndpoint.wMaxPacketSize,Network);
     if PAX88XXXNetwork(Network).InterruptRequest = nil then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to allocate interrupt request');

       Exit;
      end;

     {Update Pending}
     Inc(PAX88XXXNetwork(Network).PendingCount);

     {$IFDEF AX88XXX_DEBUG}
     if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Submitting interrupt request');
     {$ENDIF}

     {Submit Interrupt Request}
     Status:=USBRequestSubmit(PAX88XXXNetwork(Network).InterruptRequest);
     if Status <> USB_STATUS_SUCCESS then
      begin
       if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to submit interrupt request: ' + USBStatusToString(Status));

       {Update Pending}
       Dec(PAX88XXXNetwork(Network).PendingCount);
       Exit;
      end;

     {Start Device (Enable)}
     if Assigned(PAX88XXXNetwork(Network).StartDevice) then
      begin
       Status:=PAX88XXXNetwork(Network).StartDevice(PAX88XXXNetwork(Network),False,True);
       if Status <> ERROR_SUCCESS then
        begin
         Result:=Status;
         Exit;
        end;
      end;

     {Set State to Open}
     Network.NetworkState:=NETWORK_STATE_OPEN;

     {Notify the State}
     NotifierNotify(@Network.Device,DEVICE_NOTIFICATION_OPEN);

     {Get Network Status}
     AX88XXXMDIORead(Device,PAX88XXXNetwork(Network).PHYAddress,MII_BMSR,Value);
     if (Value and BMSR_LSTATUS) <> 0 then
      begin
       {Update Link Status}
       PAX88XXXNetwork(Network).LinkStatus:=1;

       {Set Status to Up}
       Network.NetworkStatus:=NETWORK_STATUS_UP;

       {Notify the Status}
       NotifierNotify(@Network.Device,DEVICE_NOTIFICATION_UP);
      end;

     {Return Result}
     Result:=ERROR_SUCCESS;
    finally
     {Check Result}
     if Result <> ERROR_SUCCESS then
      begin
       {Check Interrupt Request}
       if PAX88XXXNetwork(Network).InterruptRequest <> nil then
        begin
         {Cancel Interrupt Request}
         USBRequestCancel(PAX88XXXNetwork(Network).InterruptRequest);

         {Release Interrupt Request}
         USBRequestRelease(PAX88XXXNetwork(Network).InterruptRequest);
        end;

       {Check Receive Request}
       if PAX88XXXNetwork(Network).ReceiveRequest <> nil then
        begin
         {Cancel Receive Request}
         USBRequestCancel(PAX88XXXNetwork(Network).ReceiveRequest);

         {Release Receive Request}
         USBRequestRelease(PAX88XXXNetwork(Network).ReceiveRequest);
        end;

       {Check Transmit Request}
       if PAX88XXXNetwork(Network).TransmitRequest <> nil then
        begin
         {Release Transmit Request}
         USBRequestRelease(PAX88XXXNetwork(Network).TransmitRequest);
        end;

       {Check Transmit Queue Buffer}
       if Network.TransmitQueue.Buffer <> INVALID_HANDLE_VALUE then
        begin
         {Deallocate Transmit Queue Entries}
         SetLength(Network.TransmitQueue.Entries,0);

         {Deallocate Transmit Queue Buffers}
         Entry:=BufferIterate(Network.TransmitQueue.Buffer,nil);
         while Entry <> nil do
          begin
           {Release USB Request Buffer}
           USBBufferRelease(Entry.Buffer);

           {Deinitialize Packets}
           SetLength(Entry.Packets,0);

           Entry:=BufferIterate(Network.TransmitQueue.Buffer,Entry);
          end;

         {Deallocate Transmit Queue Buffer}
         BufferDestroy(Network.TransmitQueue.Buffer);

         Network.TransmitQueue.Buffer:=INVALID_HANDLE_VALUE;
        end;

       {Check Transmit Queue Semaphore}
       if Network.TransmitQueue.Wait <> INVALID_HANDLE_VALUE then
        begin
         {Deallocate Transmit Queue Semaphore}
         SemaphoreDestroy(Network.TransmitQueue.Wait);

         Network.TransmitQueue.Wait:=INVALID_HANDLE_VALUE;
        end;

       {Check Receive Queue Buffer}
       if Network.ReceiveQueue.Buffer <> INVALID_HANDLE_VALUE then
        begin
         {Deallocate Receive Queue Entries}
         SetLength(Network.ReceiveQueue.Entries,0);

         {Deallocate Receive Queue Buffers}
         Entry:=BufferIterate(Network.ReceiveQueue.Buffer,nil);
         while Entry <> nil do
          begin
           {Release USB Request Buffer}
           USBBufferRelease(Entry.Buffer);

           {Initialize Packets}
           SetLength(Entry.Packets,0);

           Entry:=BufferIterate(Network.ReceiveQueue.Buffer,Entry);
          end;

         {Deallocate Receive Queue Buffer}
         BufferDestroy(Network.ReceiveQueue.Buffer);

         Network.ReceiveQueue.Buffer:=INVALID_HANDLE_VALUE;
        end;

       {Check Receive Queue Semaphore}
       if Network.ReceiveQueue.Wait <> INVALID_HANDLE_VALUE then
        begin
         {Deallocate Receive Queue Semaphore}
         SemaphoreDestroy(Network.ReceiveQueue.Wait);

         Network.ReceiveQueue.Wait:=INVALID_HANDLE_VALUE;
        end;
      end;
    end;
   finally
    {Release the Lock}
    MutexUnlock(Network.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

function AX88XXXNetworkClose(Network:PNetworkDevice):LongWord;
{Implementation of NetworkDeviceClose for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkDeviceClose instead}
var
 Message:TMessage;
 Device:PUSBDevice;
 Entry:PNetworkEntry;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Device.DeviceData);
 if Device = nil then Exit;

 {Check State}
 Result:=ERROR_NOT_OPEN;
 if Network.NetworkState <> NETWORK_STATE_OPEN then Exit;

 {Set State to Closing}
 Result:=ERROR_OPERATION_FAILED;
 if NetworkDeviceSetState(Network,NETWORK_STATE_CLOSING) <> ERROR_SUCCESS then Exit;

 {Acquire the Lock}
 if MutexLock(Network.Lock) = ERROR_SUCCESS then
  begin
   try
    {Cancel Interrupt Request}
    USBRequestCancel(PAX88XXXNetwork(Network).InterruptRequest);

    {Cancel Receive Request}
    USBRequestCancel(PAX88XXXNetwork(Network).ReceiveRequest);

    {Check Pending}
    if PAX88XXXNetwork(Network).PendingCount <> 0 then
     begin
      {$IFDEF AX88XXX_DEBUG}
      if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Waiting for ' + IntToStr(PAX88XXXNetwork(Network).PendingCount) + ' pending requests to complete');
      {$ENDIF}

      {Wait for Pending}

      {Setup Waiter}
      PAX88XXXNetwork(Network).WaiterThread:=GetCurrentThreadId;

      {Release the Lock}
      MutexUnlock(Network.Lock);

      {Wait for Message}
      ThreadReceiveMessage(Message);

      {Acquire the Lock}
      if MutexLock(Network.Lock) <> ERROR_SUCCESS then Exit;
     end;

    {Set State to Closed}
    Network.NetworkState:=NETWORK_STATE_CLOSED;

    {Notify the State}
    NotifierNotify(@Network.Device,DEVICE_NOTIFICATION_CLOSE);

    {Stop Device}
    if Assigned(PAX88XXXNetwork(Network).StopDevice) then
     begin
      PAX88XXXNetwork(Network).StopDevice(PAX88XXXNetwork(Network));
     end;

    {Check Interrupt Request}
    if PAX88XXXNetwork(Network).InterruptRequest <> nil then
     begin
      {Release Interrupt Request}
      USBRequestRelease(PAX88XXXNetwork(Network).InterruptRequest);
     end;

    {Check Receive Request}
    if PAX88XXXNetwork(Network).ReceiveRequest <> nil then
     begin
      {Release Receive Request}
      USBRequestRelease(PAX88XXXNetwork(Network).ReceiveRequest);
     end;

    {Check Transmit Request}
    if PAX88XXXNetwork(Network).TransmitRequest <> nil then
     begin
      {Release Transmit Request}
      USBRequestRelease(PAX88XXXNetwork(Network).TransmitRequest);
     end;

    {Check Transmit Queue Buffer}
    if Network.TransmitQueue.Buffer <> INVALID_HANDLE_VALUE then
     begin
      {Deallocate Transmit Queue Entries}
      SetLength(Network.TransmitQueue.Entries,0);

      {Deallocate Transmit Queue Buffers}
      Entry:=BufferIterate(Network.TransmitQueue.Buffer,nil);
      while Entry <> nil do
       begin
        {Release USB Request Buffer}
        USBBufferRelease(Entry.Buffer);

        {Deinitialize Packets}
        SetLength(Entry.Packets,0);

        Entry:=BufferIterate(Network.TransmitQueue.Buffer,Entry);
       end;

      {Deallocate Transmit Queue Buffer}
      BufferDestroy(Network.TransmitQueue.Buffer);

      Network.TransmitQueue.Buffer:=INVALID_HANDLE_VALUE;
     end;

    {Check Transmit Queue Semaphore}
    if Network.TransmitQueue.Wait <> INVALID_HANDLE_VALUE then
     begin
      {Deallocate Transmit Queue Semaphore}
      SemaphoreDestroy(Network.TransmitQueue.Wait);

      Network.TransmitQueue.Wait:=INVALID_HANDLE_VALUE;
     end;

    {Check Receive Queue Buffer}
    if Network.ReceiveQueue.Buffer <> INVALID_HANDLE_VALUE then
     begin
      {Deallocate Receive Queue Entries}
      SetLength(Network.ReceiveQueue.Entries,0);

      {Deallocate Receive Queue Buffers}
      Entry:=BufferIterate(Network.ReceiveQueue.Buffer,nil);
      while Entry <> nil do
       begin
        {Release USB Request Buffer}
        USBBufferRelease(Entry.Buffer);

        {Initialize Packets}
        SetLength(Entry.Packets,0);

        Entry:=BufferIterate(Network.ReceiveQueue.Buffer,Entry);
       end;

      {Deallocate Receive Queue Buffer}
      BufferDestroy(Network.ReceiveQueue.Buffer);

      Network.ReceiveQueue.Buffer:=INVALID_HANDLE_VALUE;
     end;

    {Check Receive Queue Semaphore}
    if Network.ReceiveQueue.Wait <> INVALID_HANDLE_VALUE then
     begin
      {Deallocate Receive Queue Semaphore}
      SemaphoreDestroy(Network.ReceiveQueue.Wait);

      Network.ReceiveQueue.Wait:=INVALID_HANDLE_VALUE;
     end;

    {Return Result}
    Result:=ERROR_SUCCESS;
   finally
    {Release the Lock}
    MutexUnlock(Network.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

function AX88XXXNetworkControl(Network:PNetworkDevice;Request:Integer;Argument1:PtrUInt;var Argument2:PtrUInt):LongWord;
{Implementation of NetworkDeviceControl for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkDeviceControl instead}
var
 Value:Word;
 Status:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Device.DeviceData);
 if Device = nil then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX: Network Control (Request=' + IntToStr(Request) + ')');
 {$ENDIF}

 {Acquire the Lock}
 if MutexLock(Network.Lock) = ERROR_SUCCESS then
  begin
   try
    {Set Result}
    Result:=ERROR_OPERATION_FAILED;
    Status:=USB_STATUS_SUCCESS;

    {Check Request}
    case Request of
     NETWORK_CONTROL_CLEAR_STATS:begin
       {Clear Statistics}
       {Network}
       Network.ReceiveBytes:=0;
       Network.ReceiveCount:=0;
       Network.ReceiveErrors:=0;
       Network.TransmitBytes:=0;
       Network.TransmitCount:=0;
       Network.TransmitErrors:=0;
       Network.StatusCount:=0;
       Network.StatusErrors:=0;
       Network.BufferOverruns:=0;
       Network.BufferUnavailable:=0;
      end;
     NETWORK_CONTROL_GET_STATS:begin
       {Get Statistics}
       if Argument2 < SizeOf(TNetworkStatistics) then Exit;

       {Network}
       PNetworkStatistics(Argument1).ReceiveBytes:=Network.ReceiveBytes;
       PNetworkStatistics(Argument1).ReceiveCount:=Network.ReceiveCount;
       PNetworkStatistics(Argument1).ReceiveErrors:=Network.ReceiveErrors;
       PNetworkStatistics(Argument1).TransmitBytes:=Network.TransmitBytes;
       PNetworkStatistics(Argument1).TransmitCount:=Network.TransmitCount;
       PNetworkStatistics(Argument1).TransmitErrors:=Network.TransmitErrors;
       PNetworkStatistics(Argument1).StatusCount:=Network.StatusCount;
       PNetworkStatistics(Argument1).StatusErrors:=Network.StatusErrors;
       PNetworkStatistics(Argument1).BufferOverruns:=Network.BufferOverruns;
       PNetworkStatistics(Argument1).BufferUnavailable:=Network.BufferUnavailable;
      end;
     NETWORK_CONTROL_SET_MAC:begin
       {Set the MAC for this device}
       Status:=AX88XXXSetMacAddress(Device,PHardwareAddress(Argument1));
       if Status = USB_STATUS_SUCCESS then
        begin
         {Save the MAC Address}
         PAX88XXXNetwork(Network).HardwareAddress:=PHardwareAddress(Argument1)^;
        end;
      end;
     NETWORK_CONTROL_GET_MAC:begin
       {Get the MAC for this device}
       Status:=AX88XXXGetMacAddress(Device,PHardwareAddress(Argument1));
      end;
     NETWORK_CONTROL_SET_LOOPBACK:begin
       {Set Loopback Mode}
       if LongBool(Argument1) then
        begin
         //To Do
        end
       else
        begin
         //To Do
        end;
      end;
     NETWORK_CONTROL_RESET:begin
       {Reset the device}
       //To Do
      end;
     NETWORK_CONTROL_DISABLE:begin
       {Disable the device}
       //To Do
      end;
     NETWORK_CONTROL_GET_HARDWARE:begin
       {Get Hardware address for this device}
       Status:=AX88XXXGetMacAddress(Device,PHardwareAddress(Argument1));
      end;
     NETWORK_CONTROL_GET_BROADCAST:begin
       {Get Broadcast address for this device}
       PHardwareAddress(Argument1)^:=ETHERNET_BROADCAST;
      end;
     NETWORK_CONTROL_GET_MTU:begin
       {Get MTU for this device}
       Argument2:=ETHERNET_MTU;
      end;
     NETWORK_CONTROL_GET_HEADERLEN:begin
       {Get Header length for this device}
       Argument2:=ETHERNET_HEADER_SIZE;
      end;
     NETWORK_CONTROL_GET_LINK:begin
       {Get Link State for this device}
       AX88XXXMDIORead(Device,PAX88XXXNetwork(Network).PHYAddress,MII_BMSR,Value);
       if (Value and BMSR_LSTATUS) <> 0 then
        begin
         {Link Up}
         Argument2:=NETWORK_LINK_UP;
        end
       else
        begin
         {Link Down}
         Argument2:=NETWORK_LINK_DOWN;
        end;
      end;
     else
      begin
       Exit;
      end;
    end;

    {Check Status}
    if Status <> USB_STATUS_SUCCESS then Exit;

    {Return Result}
    Result:=ERROR_SUCCESS;
   finally
    {Release the Lock}
    MutexUnlock(Network.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

function AX88XXXBufferAllocate(Network:PNetworkDevice;var Entry:PNetworkEntry):LongWord;
{Implementation of NetworkBufferAllocate for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkBufferAllocate instead}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Setup Entry}
 Entry:=nil;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX: Buffer Allocate');
 {$ENDIF}

 {Check State}
 Result:=ERROR_NOT_READY;
 if Network.NetworkState <> NETWORK_STATE_OPEN then Exit;

 {Set Result}
 Result:=ERROR_OPERATION_FAILED;

 {Wait for Entry (Transmit Buffer)}
 Entry:=BufferGet(Network.TransmitQueue.Buffer);
 if Entry <> nil then
  begin
   {Update Entry}
   Entry.Size:=PAX88XXXNetwork(Network).TransmitRequestSize;
   Entry.Offset:=PAX88XXXNetwork(Network).TransmitOverhead;
   Entry.Count:=PAX88XXXNetwork(Network).TransmitPacketCount;

   {Update First Packet}
   Entry.Packets[0].Buffer:=Entry.Buffer;
   Entry.Packets[0].Data:=Entry.Buffer + Entry.Offset;
   Entry.Packets[0].Length:=Entry.Size - (Entry.Offset + PAX88XXXNetwork(Network).TransmitReserved);

   {$IFDEF AX88XXX_DEBUG}
   if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX:  Entry.Size = ' + IntToStr(Entry.Size));
   if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX:  Entry.Offset = ' + IntToStr(Entry.Offset));
   if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX:  Entry.Count = ' + IntToStr(Entry.Count));
   if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX:  Entry.Packets[0].Length = ' + IntToStr(Entry.Packets[0].Length));
   {$ENDIF}

   {Return Result}
   Result:=ERROR_SUCCESS;
  end;
end;

{==============================================================================}

function AX88XXXBufferRelease(Network:PNetworkDevice;Entry:PNetworkEntry):LongWord;
{Implementation of NetworkBufferRelease for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkBufferRelease instead}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX: Buffer Release');
 {$ENDIF}

 {Check Entry}
 if Entry = nil then Exit;

 {Check State}
 Result:=ERROR_NOT_READY;
 if Network.NetworkState <> NETWORK_STATE_OPEN then Exit;

 {Acquire the Lock}
 if MutexLock(Network.Lock) = ERROR_SUCCESS then
  begin
   try
    {Free Entry (Receive Buffer)}
    Result:=BufferFree(Entry);
   finally
    {Release the Lock}
    MutexUnlock(Network.Lock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

function AX88XXXBufferReceive(Network:PNetworkDevice;var Entry:PNetworkEntry):LongWord;
{Implementation of NetworkBufferReceive for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkBufferReceive instead}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Setup Entry}
 Entry:=nil;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX: Buffer Receive');
 {$ENDIF}

 {Check State}
 Result:=ERROR_NOT_READY;
 if Network.NetworkState <> NETWORK_STATE_OPEN then Exit;

 {Wait for Entry}
 if SemaphoreWait(Network.ReceiveQueue.Wait) = ERROR_SUCCESS then
  begin
   {Acquire the Lock}
   if MutexLock(Network.Lock) = ERROR_SUCCESS then
    begin
     try
      {Remove Entry}
      Entry:=Network.ReceiveQueue.Entries[Network.ReceiveQueue.Start];

      {Update Start}
      Network.ReceiveQueue.Start:=(Network.ReceiveQueue.Start + 1) mod PAX88XXXNetwork(Network).ReceiveEntryCount;

      {Update Count}
      Dec(Network.ReceiveQueue.Count);

      {Return Result}
      Result:=ERROR_SUCCESS;
     finally
      {Release the Lock}
      MutexUnlock(Network.Lock);
     end;
    end
   else
    begin
     Result:=ERROR_CAN_NOT_COMPLETE;
    end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

function AX88XXXBufferTransmit(Network:PNetworkDevice;Entry:PNetworkEntry):LongWord;
{Implementation of NetworkBufferTransmit for the AX88XXX device}
{Note: Not intended to be called directly by applications, use NetworkBufferTransmit instead}
var
 Empty:Boolean;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;
 if Network.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(Network,'AX88XXX: Buffer Transmit');
 {$ENDIF}

 {Check Entry}
 if Entry = nil then Exit;
 if (Entry.Count = 0) or (Entry.Count > 1) then Exit;

 {Check State}
 Result:=ERROR_NOT_READY;
 if Network.NetworkState <> NETWORK_STATE_OPEN then Exit;

 {Wait for Entry}
 if SemaphoreWait(Network.TransmitQueue.Wait) = ERROR_SUCCESS then
  begin
   {Acquire the Lock}
   if MutexLock(Network.Lock) = ERROR_SUCCESS then
    begin
     try
      {Check Empty}
      Empty:=(Network.TransmitQueue.Count = 0);

      {Add Entry}
      Network.TransmitQueue.Entries[(Network.TransmitQueue.Start + Network.TransmitQueue.Count) mod PAX88XXXNetwork(Network).TransmitEntryCount]:=Entry;

      {Update Count}
      Inc(Network.TransmitQueue.Count);

      {Check Empty}
      if Empty then
       begin
        {Start Transmit}
        AX88XXXTransmitStart(PAX88XXXNetwork(Network));
       end;

      {Return Result}
      Result:=ERROR_SUCCESS;
     finally
      {Release the Lock}
      MutexUnlock(Network.Lock);
     end;
    end
   else
    begin
     Result:=ERROR_CAN_NOT_COMPLETE;
    end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

{==============================================================================}

procedure AX88XXXTransmitStart(Network:PAX88XXXNetwork);
{Transmit start function for the AX88XXX Network device}
{Note: Not intended to be called directly by applications}

{Note: Caller must hold the network lock}
var
 Status:LongWord;
 Request:PUSBRequest;
 Entry:PNetworkEntry;
 Packet:PNetworkPacket;
begin
 {}
 {Check Network}
 if Network = nil then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Transmit Start');
 {$ENDIF}

 {Check Count}
 if Network.Network.TransmitQueue.Count = 0 then Exit;

 {Get Entry}
 Entry:=Network.Network.TransmitQueue.Entries[Network.Network.TransmitQueue.Start];
 if Entry = nil then Exit;

 {Get Request}
 Request:=Network.TransmitRequest;

 {Update Entry}
 Entry.DriverData:=Network;

 {Initialize Request}
 USBRequestInitialize(Request,AX88XXXTransmitComplete,Entry.Buffer,Entry.Size,Entry);

 {Transmit Data}
 if Assigned(Network.TransmitData) then
  begin
   {Model Specific Behaviour}
   Status:=Network.TransmitData(Network,Request,Entry);
   if Status <> ERROR_SUCCESS then
    begin
     {$IFDEF AX88XXX_DEBUG}
     if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Failed to Transmit Data (Status=' + ErrorToString(Status) + ')');
     {$ENDIF}

     {Update Entry}
     Entry.DriverData:=nil;

     Exit;
    end;
  end
 else
  begin
   {Default Behaviour}
   {Get Packet}
   Packet:=@Entry.Packets[0];

   {$IFDEF AX88XXX_DEBUG}
   if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Packet Length = ' + IntToStr(Packet.Length));
   {$ENDIF}

   {Update Request}
   Request.Size:=Packet.Length;
  end;

 {Update Pending}
 Inc(Network.PendingCount);

 {$IFDEF AX88XXX_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Submitting transmit request');
 {$ENDIF}

 {Submit the Request}
 Status:=USBRequestSubmit(Request);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to submit transmit request: ' + USBStatusToString(Status));

   {Update Entry}
   Entry.DriverData:=nil;

   {Update Pending}
   Dec(Network.PendingCount);
  end;
end;

{==============================================================================}
{==============================================================================}
{AX88XXX USB Functions}
function AX88XXXDriverBind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Bind the AX88XXX driver to a USB device if it is suitable}
{Device: The USB device to attempt to bind to}
{Interrface: The USB interface to attempt to bind to (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed, USB_STATUS_DEVICE_UNSUPPORTED if unsupported or another error code on failure}
var
 Model:LongWord;
 Status:LongWord;
 Network:PAX88XXXNetwork;
 NetworkInterface:PUSBInterface;
 ReceiveEndpoint:PUSBEndpointDescriptor;
 TransmitEndpoint:PUSBEndpointDescriptor;
 InterruptEndpoint:PUSBEndpointDescriptor;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Attempting to bind USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Check Interface (Bind to device only)}
 if Interrface <> nil then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Interface bind not supported by driver');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check AX88XXX Device}
 if AX88XXXCheckDevice(Device,Model) <> USB_STATUS_SUCCESS then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Device not found in supported device list');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check Device Speed}
 if Device.Speed <> USB_SPEED_HIGH then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Device speed is not USB_SPEED_HIGH');
   {$ENDIF}
   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Get Endpoints}
 if AX88XXXGetEndpoints(Device,NetworkInterface,ReceiveEndpoint,TransmitEndpoint,InterruptEndpoint) <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to find endpoints for device');

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Check Configuration}
 if Device.ConfigurationValue = 0 then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Assigning configuration ' + IntToStr(Device.Configuration.Descriptor.bConfigurationValue) + ' (' + IntToStr(Device.Configuration.Descriptor.bNumInterfaces) + ' interfaces available)');
   {$ENDIF}

   {Set Configuration}
   Status:=USBDeviceSetConfiguration(Device,Device.Configuration.Descriptor.bConfigurationValue);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to set device configuration: ' + USBStatusToString(Status));

     {Return Result}
     Result:=Status;
     Exit;
    end;
  end;

 {USB device reset not required because the USB core already did a reset on the port during attach}

 {Create Network}
 Network:=PAX88XXXNetwork(NetworkDeviceCreateEx(SizeOf(TAX88XXXNetwork)));
 if Network = nil then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to create new network device');

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Update Network}
 {Device}
 Network.Network.Device.DeviceBus:=DEVICE_BUS_USB;
 Network.Network.Device.DeviceType:=NETWORK_TYPE_ETHERNET;
 Network.Network.Device.DeviceFlags:=NETWORK_FLAG_RX_BUFFER or NETWORK_FLAG_TX_BUFFER;
 Network.Network.Device.DeviceData:=Device;
 Network.Network.Device.DeviceDescription:=AX88XXX_NETWORK_DESCRIPTION;
 {Network}
 Network.Network.NetworkState:=NETWORK_STATE_CLOSED;
 Network.Network.NetworkStatus:=NETWORK_STATUS_DOWN;
 Network.Network.DeviceOpen:=AX88XXXNetworkOpen;
 Network.Network.DeviceClose:=AX88XXXNetworkClose;
 Network.Network.DeviceControl:=AX88XXXNetworkControl;
 Network.Network.BufferAllocate:=AX88XXXBufferAllocate;
 Network.Network.BufferRelease:=AX88XXXBufferRelease;
 Network.Network.BufferReceive:=AX88XXXBufferReceive;
 Network.Network.BufferTransmit:=AX88XXXBufferTransmit;
 {Driver}
 Network.Model:=Model;
 Network.PHYLock:=INVALID_HANDLE_VALUE;
 {USB}
 Network.ReceiveEndpoint:=ReceiveEndpoint;
 Network.TransmitEndpoint:=TransmitEndpoint;
 Network.InterruptEndpoint:=InterruptEndpoint;
 Network.WaiterThread:=INVALID_HANDLE_VALUE;

 {Get Model Info}
 if AX88XXXGetModelInfo(Network) <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to get model specific information for network');

   {Destroy Network}
   NetworkDeviceDestroy(@Network.Network);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Create PHY Lock}
 Network.PHYLock:=MutexCreate;
 if Network.PHYLock = INVALID_HANDLE_VALUE then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to create PHY lock for network');

   {Destroy Network}
   NetworkDeviceDestroy(@Network.Network);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Register Network}
 if NetworkDeviceRegister(@Network.Network) <> ERROR_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(Device,'AX88XXX: Failed to register new network device');

   {Destroy PHY Lock}
   MutexDestroy(Network.PHYLock);

   {Destroy Network}
   NetworkDeviceDestroy(@Network.Network);

   {Return Result}
   Result:=USB_STATUS_DEVICE_UNSUPPORTED;
   Exit;
  end;

 {Update Device}
 Device.DriverData:=Network;

 {Return Result}
 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

function AX88XXXDriverUnbind(Device:PUSBDevice;Interrface:PUSBInterface):LongWord;
{Unbind the AX88XXX driver from a USB device}
{Device: The USB device to unbind from}
{Interrface: The USB interface to unbind from (or nil for whole device)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Network:PAX88XXXNetwork;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Check Interface}
 if Interrface <> nil then Exit;

 {Check Driver}
 if Device.Driver <> AX88XXXDriver then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Unbinding USB device (Manufacturer=' + Device.Manufacturer + ' Product=' + Device.Product + ' Address=' + IntToStr(Device.Address) + ')');
 {$ENDIF}

 {Get Network}
 Network:=PAX88XXXNetwork(Device.DriverData);
 if Network = nil then Exit;

 {Close Network}
 AX88XXXNetworkClose(@Network.Network);

 {Destroy PHY Lock}
 if Network.PHYLock <> INVALID_HANDLE_VALUE then
  begin
   MutexDestroy(Network.PHYLock);
  end;

 {Update Device}
 Device.DriverData:=nil;

 {Deregister Network}
 if NetworkDeviceDeregister(@Network.Network) <> ERROR_SUCCESS then Exit;

 {Destroy Network}
 NetworkDeviceDestroy(@Network.Network);

 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

procedure AX88XXXReceiveWorker(Request:PUSBRequest);
{Called (by a Worker thread) to process a completed USB request from the AX88XXX bulk IN endpoint}
{Request: The USB request which has completed}
var
 Status:LongWord;
 Message:TMessage;
 Next:PNetworkEntry;
 Entry:PNetworkEntry;
 Network:PAX88XXXNetwork;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Entry}
 Entry:=PNetworkEntry(Request.DriverData);
 if Entry = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Entry.DriverData);
 if Network <> nil then
  begin
   {Acquire the Lock}
   if MutexLock(Network.Network.Lock) = ERROR_SUCCESS then
    begin
     try
      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, setting receive request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}

        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;

      {Check Result}
      if Request.Status = USB_STATUS_SUCCESS then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Receive complete (Size=' + IntToStr(Request.Size) + ' Actual Size=' + IntToStr(Request.ActualSize) + ')');
        {$ENDIF}

        {Check Size}
        if Request.ActualSize > 0 then
         begin
          {Get Next}
          Next:=nil;
          if BufferAvailable(Network.Network.ReceiveQueue.Buffer) > 0 then
           begin
            Next:=BufferGet(Network.Network.ReceiveQueue.Buffer);
           end;

          {Check Next}
          if Next <> nil then
           begin
            {Check Receive Queue Count}
            if Network.Network.ReceiveQueue.Count < Network.ReceiveEntryCount then
             begin
              {Update Entry}
              Entry.Count:=0;

              {Receive Data}
              if Assigned(Network.ReceiveData) then
               begin
                {Model Specific Behaviour}
                Status:=Network.ReceiveData(Network,Request,Entry);
                if Status <> ERROR_SUCCESS then
                 begin
                  {$IFDEF AX88XXX_DEBUG}
                  if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Failed to Receive Data (Status=' + ErrorToString(Status) + ')');
                  {$ENDIF}
                 end;
               end
              else
               begin
                {Default Behaviour}

                //To Do //See: rx_process / usbnet_skb_return

                BufferFree(Entry); //To Do  //Temporary
                //Next:=Entry; //To Do  //Temporary

               end;
             end
            else
             begin
              if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Receive queue overrun, packet discarded');

              {Free Entry}
              BufferFree(Entry);

              {Update Statistics}
              Inc(Network.Network.ReceiveErrors);
              Inc(Network.Network.BufferOverruns);
             end;
           end
          else
           begin
            if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: No receive buffer available, packet discarded');

            {Get Next}
            Next:=Entry;

            {Update Statistics}
            Inc(Network.Network.ReceiveErrors);
            Inc(Network.Network.BufferUnavailable);
           end;
         end
        else
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed receive request (ActualSize=' + USBStatusToString(Request.ActualSize) + ')');

          {Get Next}
          Next:=Entry;

          {Update Statistics}
          Inc(Network.Network.ReceiveErrors);
         end;
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed receive request (Status=' + USBStatusToString(Request.Status) + ')');

        {Get Next}
        Next:=Entry;

        {Update Statistics}
        Inc(Network.Network.ReceiveErrors);
       end;

      {Update Pending}
      Dec(Network.PendingCount);

      {Update Next}
      Next.DriverData:=nil;

      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {Free Next}
        BufferFree(Next);

        {Check Pending}
        if Network.PendingCount = 0 then
         begin
          {Check Waiter}
          if Network.WaiterThread <> INVALID_HANDLE_VALUE then
           begin
            {$IFDEF AX88XXX_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, sending message to waiter thread (Thread=' + IntToHex(Network.WaiterThread,8) + ')');
            {$ENDIF}

            {Send Message}
            FillChar(Message,SizeOf(TMessage),0);
            ThreadSendMessage(Network.WaiterThread,Message);
            Network.WaiterThread:=INVALID_HANDLE_VALUE;
           end;
         end;
       end
      else
       begin
        {Check Next}
        if Next <> nil then
         begin
          {Update Pending}
          Inc(Network.PendingCount);

          {Update Next}
          Next.DriverData:=Network;

          {Initialize Request}
          USBRequestInitialize(Request,AX88XXXReceiveComplete,Next.Buffer,Next.Size,Next);

          {$IFDEF AX88XXX_DEBUG}
          if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Resubmitting receive request');
          {$ENDIF}

          {Resubmit Request}
          Status:=USBRequestSubmit(Request);
          if Status <> USB_STATUS_SUCCESS then
           begin
            if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to resubmit receive request: ' + USBStatusToString(Status));

            {Update Pending}
            Dec(Network.PendingCount);

            {Update Next}
            Next.DriverData:=nil;

            {Free Next}
            BufferFree(Next);
           end;
         end
        else
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: No receive buffer available, cannot resubmit receive request');

          {Update Statistics}
          Inc(Network.Network.BufferUnavailable);
         end;
       end;
     finally
      {Release the Lock}
      MutexUnlock(Network.Network.Lock);
     end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Receive request invalid');
  end;
end;

{==============================================================================}

procedure AX88XXXReceiveComplete(Request:PUSBRequest);
{Called when a USB request from the AX88XXX bulk IN endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 WorkerScheduleEx(0,WORKER_FLAG_PRIORITY,TWorkerTask(AX88XXXReceiveWorker),Request,nil);
end;

{==============================================================================}

procedure AX88XXXTransmitWorker(Request:PUSBRequest);
{Called (by a Worker thread) to process a completed USB request to the AX88XXX bulk OUT endpoint}
{Request: The USB request which has completed}
var
 Message:TMessage;
 Entry:PNetworkEntry;
 Network:PAX88XXXNetwork;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Entry}
 Entry:=PNetworkEntry(Request.DriverData);
 if Entry = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Entry.DriverData);
 if Network <> nil then
  begin
   {Acquire the Lock}
   if MutexLock(Network.Network.Lock) = ERROR_SUCCESS then
    begin
     try
      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, setting transmit request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}

        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;

      {Check Result}
      if Request.Status = USB_STATUS_SUCCESS then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Transmit complete');
        {$ENDIF}

        {Update Statistics}
        Inc(Network.Network.TransmitCount);
        Inc(Network.Network.TransmitBytes,Entry.Packets[0].Length);
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed transmit request (Status=' + USBStatusToString(Request.Status) + ')');

        {Update Statistics}
        Inc(Network.Network.TransmitErrors);
       end;

      {Update Start}
      Network.Network.TransmitQueue.Start:=(Network.Network.TransmitQueue.Start + 1) mod PAX88XXXNetwork(Network).TransmitEntryCount;

      {Update Count}
      Dec(Network.Network.TransmitQueue.Count);

      {Signal Queue Free}
      SemaphoreSignal(Network.Network.TransmitQueue.Wait);

      {Update Entry}
      Entry.DriverData:=nil;

      {Free Entry (Transmit Buffer)}
      BufferFree(Entry);

      {Update Pending}
      Dec(Network.PendingCount);

      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {Check Pending}
        if Network.PendingCount = 0 then
         begin
          {Check Waiter}
          if Network.WaiterThread <> INVALID_HANDLE_VALUE then
           begin
            {$IFDEF AX88XXX_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, sending message to waiter thread (Thread=' + IntToHex(Network.WaiterThread,8) + ')');
            {$ENDIF}

            {Send Message}
            FillChar(Message,SizeOf(TMessage),0);
            ThreadSendMessage(Network.WaiterThread,Message);
            Network.WaiterThread:=INVALID_HANDLE_VALUE;
           end;
         end;
       end
      else
       begin
        {Check Count}
        if Network.Network.TransmitQueue.Count > 0 then
         begin
          {Start Transmit}
          AX88XXXTransmitStart(Network);
         end;
       end;
     finally
      {Release the Lock}
      MutexUnlock(Network.Network.Lock);
     end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Transmit request invalid');
  end;
end;

{==============================================================================}

procedure AX88XXXTransmitComplete(Request:PUSBRequest);
{Called when a USB request to the AX88XXX bulk OUT endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 WorkerScheduleEx(0,WORKER_FLAG_PRIORITY,TWorkerTask(AX88XXXTransmitWorker),Request,nil);
end;

{==============================================================================}

procedure AX88XXXInterruptWorker(Request:PUSBRequest);
{Called (by a Worker thread) to process a completed USB request from the AX88XXX interrupt IN endpoint}
{Request: The USB request which has completed}
var
 Status:LongWord;
 Message:TMessage;
 Network:PAX88XXXNetwork;
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Request.DriverData);
 if Network <> nil then
  begin
   {Acquire the Lock}
   if MutexLock(Network.Network.Lock) = ERROR_SUCCESS then
    begin
     try
      {Update Statistics}
      Inc(Network.Network.StatusCount);

      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, setting interrupt request status to USB_STATUS_DEVICE_DETACHED');
        {$ENDIF}

        {Update Request}
        Request.Status:=USB_STATUS_DEVICE_DETACHED;
       end;

      {Check Result}
      if Request.Status = USB_STATUS_SUCCESS then
       begin
        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Interrupt complete (Size=' + IntToStr(Request.Size) + ' Actual Size=' + IntToStr(Request.ActualSize) + ')');
        {$ENDIF}

        {Update Status}
        if Assigned(Network.UpdateStatus) then
         begin
          Status:=Network.UpdateStatus(Network,Request);
          if Status <> ERROR_SUCCESS then
           begin
            {$IFDEF AX88XXX_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Failed to Update Status (Status=' + ErrorToString(Status) + ')');
            {$ENDIF}
           end;
         end;
       end
      else
       begin
        if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed interrupt request (Status=' + USBStatusToString(Request.Status) + ')');

        {Update Statistics}
        Inc(Network.Network.StatusErrors);
       end;

      {Update Pending}
      Dec(Network.PendingCount);

      {Check State}
      if Network.Network.NetworkState = NETWORK_STATE_CLOSING then
       begin
        {Check Pending}
        if Network.PendingCount = 0 then
         begin
          {Check Waiter}
          if Network.WaiterThread <> INVALID_HANDLE_VALUE then
           begin
            {$IFDEF AX88XXX_DEBUG}
            if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Close pending, sending message to waiter thread (Thread=' + IntToHex(Network.WaiterThread,8) + ')');
            {$ENDIF}

            {Send Message}
            FillChar(Message,SizeOf(TMessage),0);
            ThreadSendMessage(Network.WaiterThread,Message);
            Network.WaiterThread:=INVALID_HANDLE_VALUE;
           end;
         end;
       end
      else
       begin
        {Update Pending}
        Inc(Network.PendingCount);

        {$IFDEF AX88XXX_DEBUG}
        if USB_LOG_ENABLED then USBLogDebug(Request.Device,'AX88XXX: Resubmitting interrupt request');
        {$ENDIF}

        {Resubmit Request}
        Status:=USBRequestSubmit(Request);
        if Status <> USB_STATUS_SUCCESS then
         begin
          if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to resubmit interrupt request: ' + USBStatusToString(Status));

          {Update Pending}
          Dec(Network.PendingCount);
         end;
       end;
     finally
      {Release the Lock}
      MutexUnlock(Network.Network.Lock);
     end;
    end
   else
    begin
     if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Failed to acquire lock');
    end;
  end
 else
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Interrupt request invalid');
  end;
end;

{==============================================================================}

procedure AX88XXXInterruptComplete(Request:PUSBRequest);
{Called when a USB request from the AX88XXX interrupt IN endpoint completes}
{Request: The USB request which has completed}
{Note: Request is passed to worker thread for processing to prevent blocking the USB completion}
begin
 {}
 {Check Request}
 if Request = nil then Exit;

 WorkerScheduleEx(0,WORKER_FLAG_PRIORITY,TWorkerTask(AX88XXXInterruptWorker),Request,nil);
end;

{==============================================================================}
{==============================================================================}
{AX88XXX Helper Functions}
function AX88XXXCheckDevice(Device:PUSBDevice;out Model:LongWord):LongWord;
{Check the Vendor and Device ID against the supported devices}
{Device: USB device to check}
{Model: The Model type if a matching Vendor and Device ID are found (eg AX88XXX_MODEL_AX88772}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Count:Integer;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Defaults}
 Model:=AX88XXX_MODEL_NONE;

 {Check Device}
 if Device = nil then Exit;

 {Check Device IDs}
 for Count:=0 to AX88XXX_DEVICE_ID_COUNT - 1 do
  begin
   if (AX88XXX_DEVICE_ID[Count].idVendor = Device.Descriptor.idVendor) and (AX88XXX_DEVICE_ID[Count].idProduct = Device.Descriptor.idProduct) then
    begin
     {Return Model}
     Model:=AX88XXX_DEVICE_ID[Count].Model;

     Result:=USB_STATUS_SUCCESS;
     Exit;
    end;
  end;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function AX88XXXGetEndpoints(Device:PUSBDevice;out Interrface:PUSBInterface;out Receive,Transmit,Interrupt:PUSBEndpointDescriptor):LongWord;
{Locate the AX88XXX interface and receive, transmit, interrupt endpoints}
{Device: USB device to locate endpoints for}
{Interrface: On return the USB interface containing the receive, transmit and interrupt endpoints}
{Receive: On return the USB bulk in endpoint for receive}
{Transmit: On return the USB bulk out endpoint for transmit}
{Interrupt: On return the USB interrupt in endpoint for sttaus (May be nil on return if device does not provide an interrupt endpoint)}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Count:Integer;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Defaults}
 Interrface:=nil;
 Receive:=nil;
 Transmit:=nil;
 Interrupt:=nil;

 {Check Device}
 if Device = nil then Exit;

 {Check Interfaces}
 for Count:=0 to Length(Device.Configuration.Interfaces) - 1 do
  begin
   {Reset Endpoints}
   Receive:=nil;
   Transmit:=nil;
   Interrupt:=nil;

   {Get Interface}
   Interrface:=Device.Configuration.Interfaces[Count];
   if Interrface <> nil then
    begin
     {Get Receive Endpoint}
     Receive:=USBDeviceFindEndpointByType(Device,Interrface,USB_DIRECTION_IN,USB_TRANSFER_TYPE_BULK);

     {Get Transmit Endpoint}
     Transmit:=USBDeviceFindEndpointByType(Device,Interrface,USB_DIRECTION_OUT,USB_TRANSFER_TYPE_BULK);

     {Get Interrupt Endpoint}
     Interrupt:=USBDeviceFindEndpointByType(Device,Interrface,USB_DIRECTION_IN,USB_TRANSFER_TYPE_INTERRUPT);

     {Check Receive and Transmit Endpoints}
     if (Receive <> nil) and (Transmit <> nil) then
      begin
       Result:=USB_STATUS_SUCCESS;
       Exit;
      end;
    end;
  end;

 {Reset Defaults}
 Interrface:=nil;
 Receive:=nil;
 Transmit:=nil;
 Interrupt:=nil;

 Result:=USB_STATUS_DEVICE_UNSUPPORTED;
end;

{==============================================================================}

function AX88XXXGetModelInfo(Network:PAX88XXXNetwork):LongWord;
{Determine the model specific information for a AX88XXX USB Ethernet Adapter}
{Network: The AX88XXX Network device to obtain the model info for}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Check Model}
 case Network.Model of
  AX88XXX_MODEL_AX8817X:begin
    {AX8817X}
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_AX88178:begin
    {AX88178}
    {Device}
    Network.Network.Device.DeviceFlags:=Network.Network.Device.DeviceFlags or NETWORK_FLAG_RX_MULTIPACKET;
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_AX88772B:begin
    {AX88772B}
    {Device}
    Network.Network.Device.DeviceFlags:=Network.Network.Device.DeviceFlags or NETWORK_FLAG_RX_MULTIPACKET;
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_AX88772:begin
    {AX88772}
    {Device}
    Network.Network.Device.DeviceFlags:=Network.Network.Device.DeviceFlags or NETWORK_FLAG_RX_MULTIPACKET;
    {Driver}
    Network.StartDevice:=AX88772StartDevice;
    Network.StopDevice:=AX88772StopDevice;
    Network.ResetDevice:=AX88772ResetDevice;
    Network.ResetLink:=AX88772ResetLink;

    Network.ReceiveData:=AX88XXXReceiveData;
    Network.TransmitData:=AX88XXXTransmitData;
    Network.UpdateStatus:=AX88XXXUpdateStatus;

    Network.ReceiveOverhead:=4;
    Network.TransmitOverhead:=4;
    Network.TransmitReserved:=4; {Allow for up to 4 bytes padding}
    Network.ReceiveRequestSize:=SIZE_2K;
    Network.TransmitRequestSize:=ETHERNET_MAX_PACKET_SIZE + Network.TransmitOverhead + Network.TransmitReserved;
    Network.ReceiveEntryCount:=512;
    Network.TransmitEntryCount:=64;
    Network.ReceivePacketCount:=Network.ReceiveRequestSize div (ETHERNET_MIN_PACKET_SIZE + Network.ReceiveOverhead);
    Network.TransmitPacketCount:=1;

    //To Do //ReceiveState ?
   end;
  AX88XXX_MODEL_AX88172A:begin
    {AX88172A}
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_NETGEAR_FA120:begin
    {NETGEAR_FA120}
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_DLINK_DUB_E100:begin
    {DLINK_DUB_E100}
    //To Do
   end;
  AX88XXX_MODEL_HAWKING_UF200:begin
    {HAWKING_UF200}
    {Driver}
    //To Do
   end;
  AX88XXX_MODEL_HG20F9:begin
    {HG20F9}
    {Device}
    Network.Network.Device.DeviceFlags:=Network.Network.Device.DeviceFlags or NETWORK_FLAG_RX_MULTIPACKET;
    {Driver}
    //To Do
   end;
  else
   begin
    Result:=USB_STATUS_DEVICE_UNSUPPORTED;
    Exit;
   end;
 end;

 Result:=USB_STATUS_SUCCESS;
end;

{==============================================================================}

function AX88XXXReadCommand(Device:PUSBDevice;Command:Byte;Value,Index,Size:Word;Data:Pointer):LongWord;
{Send a read command to a AX88XXX USB Ethernet Adapter}
{Device: USB device to read from}
{Command: The read command to send}
{Value: Value param for the command}
{Index: Index param for the command}
{Size: Size of the data to be read in bytes}
{Data: Pointer to a buffer to receive thethe data}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Send Read Command}
 Result:=USBControlRequest(Device,nil,Command,USB_BMREQUESTTYPE_DIR_IN or USB_BMREQUESTTYPE_TYPE_VENDOR or USB_BMREQUESTTYPE_RECIPIENT_DEVICE,Value,Index,Data,Size);
end;

{==============================================================================}

function AX88XXXWriteCommand(Device:PUSBDevice;Command:Byte;Value,Index,Size:Word;Data:Pointer):LongWord;
{Send a write command to a AX88XXX USB Ethernet Adapter}
{Device: USB device to write to}
{Command: The write command to send}
{Value: Value param for the command}
{Index: Index param for the command}
{Size: Size of the data to be written in bytes}
{Data: Pointer to the data to be sent}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Send Write Command}
 Result:=USBControlRequest(Device,nil,Command,USB_BMREQUESTTYPE_DIR_OUT or USB_BMREQUESTTYPE_TYPE_VENDOR or USB_BMREQUESTTYPE_RECIPIENT_DEVICE,Value,Index,Data,Size);
end;

{==============================================================================}

function AX88XXXMDIORead(Device:PUSBDevice;Address:LongWord;Location:Word;var Value:Word):LongWord;
{Perform an MDIO (MII) read from a AX88XXX USB Ethernet Adapter}
{Device: USB device to read from}
{Address: The PHY address to read from}
{Location: The MII register location to read}
{Value: The value returned from the read}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 SMSR:Byte;
 Count:LongWord;
 Status:LongWord;
 Network:PAX88XXXNetwork;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Value}
 Value:=0;

 {Check Device}
 if Device = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Device.DriverData);
 if Network = nil then Exit;

 {Acquire PHY Lock}
 if MutexLock(Network.PHYLock) = ERROR_SUCCESS then
  begin
   try
    {Wait for PHY}
    Count:=0;
    repeat
     {Set Software MII}
     Status:=AX88XXXSetSoftwareMII(Device);
     if Status <> USB_STATUS_SUCCESS then Exit;

     {Wait}
     MicrosecondDelay(1000);

     {Read Status}
     Status:=AX88XXXReadCommand(Device,AX_CMD_STATMNGSTS_REG,0,0,SizeOf(Byte),@SMSR);

     {Update Count}
     Inc(Count);
    until ((SMSR and AX_HOST_EN) <> 0) or (Count >= 30) or (Status <> USB_STATUS_SUCCESS);
    if Status <> USB_STATUS_SUCCESS then Exit;

    {Read from PHY}
    AX88XXXReadCommand(Device,AX_CMD_READ_MII_REG,Address,Location,SizeOf(Word),@Value);

    {Set Hardware MII}
    AX88XXXSetHardwareMII(Device);

    {Update Value}
    Value:=WordLEtoN(Value);

    {$IFDEF AX88XXX_DEBUG}
    if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: AX88XXXMDIORead (Address=' + IntToHex(Address,8) + ' Location= ' + IntToHex(Location,4) + ' Value=' + IntToHex(Value,4));
    {$ENDIF}

    {Return Result}
    Result:=USB_STATUS_SUCCESS;
   finally
    {Release PHY Lock}
    MutexUnlock(Network.PHYLock);
   end;
  end;

 //To Do //See: asix_mdio_read
end;

{==============================================================================}

function AX88XXXMDIOWrite(Device:PUSBDevice;Address:LongWord;Location,Value:Word):LongWord;
{Perform an MDIO (MII) write to a AX88XXX USB Ethernet Adapter}
{Device: USB device to write to}
{Address: The PHY address to write to}
{Location: The MII register location to write}
{Value: The value to be written}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 SMSR:Byte;
 Count:LongWord;
 Status:LongWord;
 Network:PAX88XXXNetwork;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Device.DriverData);
 if Network = nil then Exit;

 {$IFDEF AX88XXX_DEBUG}
 if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: AX88XXXMDIOWrite (Address=' + IntToHex(Address,8) + ' Location= ' + IntToHex(Location,4) + ' Value=' + IntToHex(Value,4));
 {$ENDIF}

 {Acquire PHY Lock}
 if MutexLock(Network.PHYLock) = ERROR_SUCCESS then
  begin
   try
    {Wait for PHY}
    Count:=0;
    repeat
     {Set Software MII}
     Status:=AX88XXXSetSoftwareMII(Device);
     if Status <> USB_STATUS_SUCCESS then Exit;

     {Wait}
     MicrosecondDelay(1000);

     {Read Status}
     Status:=AX88XXXReadCommand(Device,AX_CMD_STATMNGSTS_REG,0,0,SizeOf(Byte),@SMSR);

     {Update Count}
     Inc(Count);
    until ((SMSR and AX_HOST_EN) <> 0) or (Count >= 30) or (Status <> USB_STATUS_SUCCESS);
    if Status <> USB_STATUS_SUCCESS then Exit;

    {Update Value}
    Value:=WordNToLE(Value);

    {Write to PHY}
    AX88XXXWriteCommand(Device,AX_CMD_WRITE_MII_REG,Address,Location,SizeOf(Word),@Value);

    {Set Hardware MII}
    AX88XXXSetHardwareMII(Device);

    {Return Result}
    Result:=USB_STATUS_SUCCESS;
   finally
    {Release PHY Lock}
    MutexUnlock(Network.PHYLock);
   end;
  end;

  //To Do //See: asix_mdio_write
end;

{==============================================================================}

function AX88XXXSetSoftwareMII(Device:PUSBDevice):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_SET_SW_MII,$0000,0,0, nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to enable software MII access: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_set_sw_mii
end;

{==============================================================================}

function AX88XXXSetHardwareMII(Device:PUSBDevice):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_SET_HW_MII,$0000,0,0,nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to enable hardware MII access: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_set_hw_mii
end;

{==============================================================================}

function AX88XXXReadPHYAddress(Device:PUSBDevice;Internal:Boolean;var Address:LongWord):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
  Offset:LongWord;
  Buffer:array[0..1] of Byte;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Address}
 Address:=0;

 {Check Device}
 if Device = nil then Exit;

 {Get Offset}
 if Internal then Offset:=1 else Offset:=0;

 {Read Command}
 Result:=AX88XXXReadCommand(Device,AX_CMD_READ_PHY_ID,0,0,2,@Buffer);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to read PHYID register: ' + USBStatusToString(Result));
  Exit;
 end;

 {Get Address}
 Address:=Buffer[Offset];

 //To Do//See: asix_read_phy_addr
end;

{==============================================================================}

function AX88XXXGetPHYAddress(Device:PUSBDevice;var Address:LongWord):LongWord; inline;
{Get the internal PHY address from a AX88XXX USB Ethernet Adapter}
{Device: USB device to get the address from}
{Address: The returned address}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=AX88XXXReadPHYAddress(Device,True,Address);
end;

{==============================================================================}

function AX88XXXGetPHYIdentifier(Device:PUSBDevice;var Identifier:LongWord):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
var
 Value:Word;
 Count:LongWord;
 Network:PAX88XXXNetwork;
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Identifier}
 Identifier:=0;

 {Check Device}
 if Device = nil then Exit;

 {Get Network}
 Network:=PAX88XXXNetwork(Device.DriverData);
 if Network = nil then Exit;

 {Poll in case the firmware or PHY is not ready}
 for Count:=0 to 99 do
  begin
   {Read MII_PHYSID1}
   if AX88XXXMDIORead(Device,Network.PHYAddress,MII_PHYSID1,Value) <> USB_STATUS_SUCCESS then Exit;

   if (Value <> 0) and (Value <> $FFFF) then Break;

   Sleep(1);
  end;
 if (Value = 0) or (Value = $FFFF) then Exit;

 {Get Identifier}
 Identifier:=(Value and $FFFF) shl 16;

 {Read MII_PHYSID2}
 if AX88XXXMDIORead(Device,Network.PHYAddress,MII_PHYSID2,Value) <> USB_STATUS_SUCCESS then Exit;

 {Update Identifier}
 Identifier:=Identifier or (Value and $FFFF);

 Result:=USB_STATUS_SUCCESS;

 //To Do //See: asix_get_phyid
end;

{==============================================================================}

function AX88XXXSoftwareReset(Device:PUSBDevice;Flags:Byte):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_SW_RESET,Flags,0,0,nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to perform software reset: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_sw_reset
end;

{==============================================================================}

function AX88XXXReadRXCTL(Device:PUSBDevice;var Value:Word):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Value}
 Value:=0;

 {Check Device}
 if Device = nil then Exit;

 {Read Command}
 Result:=AX88XXXReadCommand(Device,AX_CMD_READ_RX_CTL,0,0,SizeOf(Word),@Value);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to read RX_CTL register: ' + USBStatusToString(Result));
 end;

 {Update Value}
 Value:=WordLEToN(Value);

 //To Do //See: asix_read_rx_ctl
end;

{==============================================================================}

function AX88XXXWriteRXCTL(Device:PUSBDevice;Value:Word):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_RX_CTL,Value,0,0,nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write RX_CTL register: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_write_rx_ctl
end;

{==============================================================================}

function AX88XXXReadMediumStatus(Device:PUSBDevice;var Value:Word):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Setup Value}
 Value:=0;

 {Check Device}
 if Device = nil then Exit;

 {Read Command}
 Result:=AX88XXXReadCommand(Device,AX_CMD_READ_MEDIUM_STATUS,0,0,SizeOf(Word),@Value);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to read Medium Status register: ' + USBStatusToString(Result));
 end;

 {Update Value}
 Value:=WordLEToN(Value);

 //To Do //See: asix_read_medium_status
end;

{==============================================================================}

function AX88XXXWriteMediumMode(Device:PUSBDevice;Value:Word):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_MEDIUM_MODE,Value,0,0,nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write Medium Mode register: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_write_medium_mode
end;

{==============================================================================}

function AX88XXXWriteGPIO(Device:PUSBDevice;Value:Word;Delay:LongWord):LongWord;
//???
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_GPIOS,Value,0,0,nil);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write GPIO register: ' + USBStatusToString(Result));
 end;

 {Delay}
 if Delay > 0 then Sleep(Delay);

 //To Do //See: asix_write_gpio
end;

{==============================================================================}

function AX88XXXGetMacAddress(Device:PUSBDevice;Address:PHardwareAddress):LongWord;
{Get the MAC address of the AX88XXX USB Ethernet Adapter}
{Device: USB device read from}
{Address: Value to read the MAC address into}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Check Address}
 if Address = nil then Exit;

 {Read Command}
 Result:=AX88XXXReadCommand(Device,AX_CMD_READ_NODE_ID,0,0,ETHERNET_ADDRESS_SIZE,Address);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to read NODE ID register: ' + USBStatusToString(Result));
 end;
end;

{==============================================================================}

function AX88XXXSetMacAddress(Device:PUSBDevice;Address:PHardwareAddress):LongWord;
{Set the MAC address of the AX88XXX USB Ethernet Adapter}
{Device: USB device to write to}
{Address: MAC address value to set}
{Return: USB_STATUS_SUCCESS if completed or another error code on failure}
begin
 {}
 Result:=USB_STATUS_INVALID_PARAMETER;

 {Check Device}
 if Device = nil then Exit;

 {Check Address}
 if Address = nil then Exit;
 if not ValidHardwareAddress(Address^) then Exit;

 {Write Command}
 Result:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_NODE_ID,0,0,ETHERNET_ADDRESS_SIZE,Address);

 {Check Result}
 if Result <> USB_STATUS_SUCCESS then
 begin
  if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write NODE ID register: ' + USBStatusToString(Result));
 end;

 //To Do //See: asix_set_mac_address
end;

{==============================================================================}
{==============================================================================}
{AX88XXX Model Specific Functions}
{AX88XXX}
function AX88XXXReceiveData(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord;
{Receive Data function for all AX88XXX device}
{Note: Internal use only, caller must hold the device lock}

 procedure AX88XXXResetReceiveState(Network:PAX88XXXNetwork);
 begin
  {}
  //To Do //Use a structure instead ?
  Network.Header:=0;
  Network.Remaining:=0;
  Network.SplitHeader:=False;
 end;

var
 Size:Word;
 CopyLength:Word;
 Offset:LongWord;

begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Check Request}
 if Request = nil then Exit;

 {Check Entry}
 if Entry = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 Offset:=0;

 {Check State}
 if (Network.Remaining > 0) and ((Network.Remaining + SizeOf(LongWord)) <= Request.ActualSize) then
  begin
   {Get Next Offset}
   Offset:=(Network.Remaining + 1) and $fffe;

   {Get Next Header}
   Network.Header:=LongWordLEToN(PLongWord(Request.Data + Offset)^);

   {Reset Offset}
   Offset:=0;

   {Get Frame Length}
   Size:=Network.Header and $7ff;
   if Size <> ((not(Network.Header) shr 16) and $7ff) then
    begin
     if NETWORK_LOG_ENABLED then NetworkLogError(@Network.Network,'AX88XXX: Header synchronisation lost (Remaining=' + IntToStr(Network.Remaining) + ')');

     {Reset State}
     AX88XXXResetReceiveState(Network);
    end;
  end;

 while (Offset + SizeOf(Word)) <= Request.ActualSize do
  begin
   if Network.Remaining = 0 then
    begin
     if (Request.ActualSize - Offset) = SizeOf(Word) then
      begin
       {Get First Half of Header}
       Network.Header:=WordLEToN(PWord(Request.Data + Offset)^);
       Network.SplitHeader:=True;
       Inc(Offset,SizeOf(Word));
       Break;
      end;

     if Network.SplitHeader then
      begin
       {Get Second Half of Header}
       Network.Header:=Network.Header or (WordLEToN(PWord(Request.Data + Offset)^) shl 16);
       Network.SplitHeader:=False;
       Inc(Offset,SizeOf(Word));
      end
     else
      begin
       {Get Complete Header}
       Network.Header:=LongWordLEToN(PLongWord(Request.Data + Offset)^);
       Inc(Offset,SizeOf(LongWord));
      end;

     {$IFDEF AX88XXX_DEBUG}
     if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Header = ' + IntToStr(Network.Header));
     {$ENDIF}

     {Get Frame Length}
     Size:=Network.Header and $7ff;
     if Size <> ((not(Network.Header) shr 16) and $7ff) then
      begin
       if NETWORK_LOG_ENABLED then NetworkLogError(@Network.Network,'AX88XXX: Bad header length (Header=' + IntToStr(Network.Header) + ' Offset=' + IntToStr(Offset) + ')');

       {Reset State}
       AX88XXXResetReceiveState(Network);

       {Free Entry}
       BufferFree(Entry);

       Exit;
      end;
     if Size > ETHERNET_MAX_PACKET_SIZE then
      begin
       if NETWORK_LOG_ENABLED then NetworkLogError(@Network.Network,'AX88XXX: Bad receive length (Size=' + IntToStr(Size) + ')');

       {Reset State}
       AX88XXXResetReceiveState(Network);

       {Free Entry}
       BufferFree(Entry);

       Exit;
      end;

     Network.Remaining:=Size;
    end;

   if Network.Remaining > (Request.ActualSize - Offset) then
    begin
     CopyLength:=Request.ActualSize - Offset;
     Dec(Network.Remaining,CopyLength);
    end
   else
    begin
     CopyLength:=Network.Remaining;
     Network.Remaining:=0;
    end;

   {$IFDEF AX88XXX_DEBUG}
   if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: CopyLength = ' + IntToStr(CopyLength) + ' Remaining=' + IntToStr(Network.Remaining));
   {$ENDIF}

   {Check Remaining}
   if Network.Remaining = 0 then
    begin
     {Update Entry}
     Inc(Entry.Count);

     {Update Packet}
     Entry.Packets[Entry.Count - 1].Buffer:=Request.Data + Offset;
     Entry.Packets[Entry.Count - 1].Data:=Request.Data  + Offset; {Does not require Entry.Offset}
     Entry.Packets[Entry.Count - 1].Length:=CopyLength;

     {$IFDEF AX88XXX_DEBUG}
     if USB_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Receiving packet (Length=' + IntToStr(Entry.Packets[Entry.Count - 1].Length) + ', Count=' + IntToStr(Entry.Count) + ')');
     {$ENDIF}

     {Update Statistics}
     Inc(Network.Network.ReceiveCount);
     Inc(Network.Network.ReceiveBytes,Entry.Packets[Entry.Count - 1].Length);
    end
   else
    begin
     {Store Entry}

     //To Do //What to do, can / does this ever happen ?

     if NETWORK_LOG_ENABLED then NetworkLogError(@Network.Network,'AX88XXX: Remaining not zero (Remaining=' + IntToStr(Network.Remaining) + ')');

    end;

   {Update Offset}
   Inc(Offset,(CopyLength + 1) and $fffe);

   {$IFDEF AX88XXX_DEBUG}
   if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Offset = ' + IntToStr(Offset));
   {$ENDIF}
  end;

 {Check Offset}
 if Offset = Request.ActualSize then
  begin
   {Check Count}
   if Entry.Count > 0 then
    begin
     {Add Entry}
     Network.Network.ReceiveQueue.Entries[(Network.Network.ReceiveQueue.Start + Network.Network.ReceiveQueue.Count) mod Network.ReceiveEntryCount]:=Entry;

     {Update Count}
     Inc(Network.Network.ReceiveQueue.Count);

     {Signal Packet Received}
     SemaphoreSignal(Network.Network.ReceiveQueue.Wait);
    end
   else
    begin
     {Free Entry}
     BufferFree(Entry);
    end;
  end
 else
  begin
   if NETWORK_LOG_ENABLED then NetworkLogError(@Network.Network,'AX88XXX: Bad packet length (ActualSize=' + IntToStr(Request.ActualSize) + ' Offset=' + IntToStr(Offset) + ')');

   {Reset State}
   AX88XXXResetReceiveState(Network);

   {Free Entry}
   BufferFree(Entry);
  end;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: asix_rx_fixup_common
         //     asix_rx_fixup_internal
         //     reset_asix_rx_fixup_info
         //     asix_rx_fixup_common_free (From unbind)
end;

{==============================================================================}

function AX88XXXTransmitData(Network:PAX88XXXNetwork;Request:PUSBRequest;Entry:PNetworkEntry):LongWord;
{Transmit Data function for all AX88XXX device}
{Note: Internal use only, caller must hold the device lock}
var
  Packet:PNetworkPacket;
  PacketHeader:LongWord;
  PaddingLength:LongWord;
  PadddingBytes:LongWord;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Check Request}
 if Request = nil then Exit;

 {Check Entry}
 if Entry = nil then Exit;

 {Get Packet}
 Packet:=@Entry.Packets[0];

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Packet Length = ' + IntToStr(Packet.Length));
 {$ENDIF}

 {Setup Padding Bytes}
 PadddingBytes:=$ffff0000;

 {Get Padding Length}
 if (Packet.Length + 4) and (Network.TransmitEndpoint.wMaxPacketSize - 1) > 0 then PaddingLength:=0 else PaddingLength:=4;

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Padding Length = ' + IntToStr(PaddingLength));
 {$ENDIF}

 {Get Packet Header}
 PacketHeader:=((Packet.Length xor $0000ffff) shl 16) + Packet.Length;

 {Add Packet Header}
 PLongWord(PtrUInt(Request.Data) + 0)^:=LongWordNToLE(PacketHeader);

 {$IFDEF AX88XXX_DEBUG}
 if NETWORK_LOG_ENABLED then NetworkLogDebug(@Network.Network,'AX88XXX: Packet Header = ' + IntToStr(PacketHeader));
 {$ENDIF}

 {Check Padding Length}
 if PaddingLength > 0 then
  begin
   {Add Padding}
   PLongWord(PtrUInt(Request.Data) + 4 + LongWord(Packet.Length))^:=LongWordNToLE(PadddingBytes);
  end;

 {Update Request}
 Request.Size:=Packet.Length + 4 + PaddingLength;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: asix_tx_fixup
end;

{==============================================================================}

function AX88XXXUpdateStatus(Network:PAX88XXXNetwork;Request:PUSBRequest):LongWord;
{Update Status function for all AX88XXX device}
{Note: Internal use only, caller must hold the device lock}
var
 Value:Word;
 Link:LongWord;
 Data:PAX88172InterruptData;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Check Request}
 if Request = nil then Exit;

 {Check Size}
 if Request.ActualSize < SizeOf(TAX88172InterruptData) then
  begin
   if USB_LOG_ENABLED then USBLogError(Request.Device,'AX88XXX: Status error (Size=' + IntToStr(Request.ActualSize) + ')');

   {Update Statistics}
   Inc(Network.Network.StatusErrors);
  end
 else
  begin
   {Get Data}
   Data:=PAX88172InterruptData(Request.Data);

   {Get Link}
   Link:=Data.Link and $01;

   {Check Link}
   if Link <> Network.LinkStatus then
    begin
     {Update Link Status}
     Network.LinkStatus:=Link;

     {Get Network Status}
     AX88XXXMDIORead(Request.Device,Network.PHYAddress,MII_BMSR,Value);
     if (Value and BMSR_LSTATUS) <> 0 then
      begin
       {Check Status}
       if Network.Network.NetworkStatus <> NETWORK_STATUS_UP then
        begin
         {Set Status to Up}
         Network.Network.NetworkStatus:=NETWORK_STATUS_UP;

         {Notify the Status}
         NotifierNotify(@Network.Network.Device,DEVICE_NOTIFICATION_UP);
        end;
      end
     else
      begin
       {Check Status}
       if Network.Network.NetworkStatus <> NETWORK_STATUS_DOWN then
        begin
         {Set Status to Down}
         Network.Network.NetworkStatus:=NETWORK_STATUS_DOWN;

         {Notify the Status}
         NotifierNotify(@Network.Network.Device,DEVICE_NOTIFICATION_DOWN);
        end;
      end;
    end;
  end;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: asix_status
end;

{==============================================================================}
{AX88172}
function AX88172StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord;
{Start Device function for AX88172 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 if Prepare then
  begin
   Result:=ERROR_OPERATION_FAILED;

   //To Do
  end;

 if Enable then
  begin
   Result:=ERROR_OPERATION_FAILED;

   //To Do
  end;

 //To Do //See: ax88172_bind
end;

{==============================================================================}

function AX88172ResetLink(Network:PAX88XXXNetwork):LongWord;
{Reset Link function for AX88172 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 //To Do //See: ax88172_link_reset
end;

{==============================================================================}
{AX88178}
function AX88178StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord;
{Start Device function for AX88178 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 if Prepare then
  begin
   Result:=ERROR_OPERATION_FAILED;

   //To Do
  end;

 if Enable then
  begin
   Result:=ERROR_OPERATION_FAILED;

   //To Do
  end;

 //To Do //See: ax88178_bind
end;

{==============================================================================}

function AX88178ResetDevice(Network:PAX88XXXNetwork):LongWord;
{Reset Device function for AX88178 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 //To Do //See: ax88178_reset
end;

{==============================================================================}

function AX88178ResetLink(Network:PAX88XXXNetwork):LongWord;
{Reset Link function for AX88178 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 //To Do //See: ax88178_link_reset
end;

{==============================================================================}
{AX88772}
function AX88772StartDevice(Network:PAX88XXXNetwork;Prepare,Enable:Boolean):LongWord;
{Start Device function for AX88772 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Chipcode:Byte;
 Status:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 if Prepare then
  begin
   Result:=ERROR_OPERATION_FAILED;

   {Get MAC Address}
   FillChar(Network.HardwareAddress,SizeOf(THardwareAddress),0);

   AX88XXXGetMacAddress(Device,@Network.HardwareAddress);

   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Hardware Address = ' + HardwareAddressToString(Network.HardwareAddress));
   {$ENDIF}

   {Check MAC Address}
   if not ValidHardwareAddress(Network.HardwareAddress) then
    begin
     {Random MAC Address}
     Network.HardwareAddress:=RandomHardwareAddress;

     {$IFDEF AX88XXX_DEBUG}
     if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Random Address = ' + HardwareAddressToString(Network.HardwareAddress));
     {$ENDIF}

     {Set MAC Address}
     Status:=AX88XXXSetMacAddress(Device,@Network.HardwareAddress);
     if Status <> USB_STATUS_SUCCESS then Exit;
    end;

   {Get PHY Address}
   Status:=AX88XXXGetPHYAddress(Device,Network.PHYAddress);
   if Status <> USB_STATUS_SUCCESS then Exit;

   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: PHY Address = ' + IntToHex(Network.PHYAddress,8));
   {$ENDIF}

   {Get Chipcode}
   AX88XXXReadCommand(Device,AX_CMD_STATMNGSTS_REG,0,0,SizeOf(Byte),@Chipcode);

   {Check Chipcode}
   Chipcode:=Chipcode and AX_CHIPCODE_MASK;
   if Chipcode = AX_AX88772_CHIPCODE then
    begin
     Status:=AX88772ResetHardware(Network);
     if Status <> ERROR_SUCCESS then
      begin
       if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to reset AX88772 hardware: ' + ErrorToString(Status));

       Result:=Status;
       Exit;
      end;
    end
   else
    begin
     Status:=AX88772AResetHardware(Network);
     if Status <> ERROR_SUCCESS then
      begin
       if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to reset AX88772A hardware: ' + ErrorToString(Status));

       Result:=Status;
       Exit;
      end;
    end;

   {Read PHYID register *AFTER* the PHY was reset properly}
   AX88XXXGetPHYIdentifier(Device,Network.PHYIdentifier);

   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: PHY Identifier = ' + IntToHex(Network.PHYIdentifier,8));
   {$ENDIF}

   {Return Result}
   Result:=ERROR_SUCCESS;
  end;

 if Enable then
  begin
   {Nothing}
   Result:=ERROR_SUCCESS;
  end;

 //To Do //See: ax88772_bind
end;

{==============================================================================}

function AX88772StopDevice(Network:PAX88XXXNetwork):LongWord;
{Stop Device function for AX88772 devices}
{Note: Internal use only, caller must hold the device lock}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Nothing}
 Result:=ERROR_SUCCESS;

 //To Do //See: ax88772_unbind
end;

{==============================================================================}

function AX88772ResetDevice(Network:PAX88XXXNetwork):LongWord;
{Reset Device function for AX88772 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Status:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 {Reset MAC Address}
 Status:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_NODE_ID,0,0,ETHERNET_ADDRESS_SIZE,@Network.HardwareAddress);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset RX_CTL}
 Status:=AX88XXXWriteRXCTL(Device,AX_DEFAULT_RX_CTL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset Medium Mode}
 Status:=AX88XXXWriteMediumMode(Device,AX88772_MEDIUM_DEFAULT);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: ax88772_reset
end;

{==============================================================================}

function AX88772ResetLink(Network:PAX88XXXNetwork):LongWord;
{Reset Link function for AX88772 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Value:Word;
 Status:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 //To Do //mii_check_media ?

 {Get Medium Mode}
 Value:=AX88772_MEDIUM_DEFAULT;

 {Reset Medium Mode}
 Status:=AX88XXXWriteMediumMode(Device,Value);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: ax88772_link_reset
 //      //AX_MEDIUM_PS = SPEED_100
 //      //AX_MEDIUM_FD = DUPLEX_FULL
end;

{==============================================================================}

function AX88772ResetHardware(Network:PAX88XXXNetwork):LongWord;
{Reset Hardware function for AX88772 devices}
{Note: Internal use only, caller must hold the device lock}
var
 Value:Word;
 Status:LongWord;
 EmbeddedPHY:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 {Reset GPIO}
 Status:=AX88XXXWriteGPIO(Device,AX_GPIO_RSE or AX_GPIO_GPO_2 or AX_GPIO_GPO2EN,5);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Select PHY}
 EmbeddedPHY:=0;
 if (Network.PHYAddress and $1F) = $10 then EmbeddedPHY:=1;

 Status:=AX88XXXWriteCommand(Device,AX_CMD_SW_PHY_SELECT,EmbeddedPHY,0,0,nil);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to select PHY #1: ' + USBStatusToString(Status));
   Exit;
  end;

 {Software Reset}
 if EmbeddedPHY > 0 then
  begin
   Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPPD);
   if Status <> USB_STATUS_SUCCESS then Exit;

   Sleep(10);

   Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_CLEAR);
   if Status <> USB_STATUS_SUCCESS then Exit;

   Sleep(60);

   Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPRL or AX_SWRESET_PRL);
   if Status <> USB_STATUS_SUCCESS then Exit;
  end
 else
  begin
   Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPPD or AX_SWRESET_PRL);
   if Status <> USB_STATUS_SUCCESS then Exit;
  end;

 Sleep(150);

 //To Do
 //if (in_pm && (!asix_mdio_read_nopm(dev->net, dev->mii.phy_id,  MII_PHYSID1)))
 // (
 //  ret = -EIO;
 //  goto out;
 // )

 {Reset RX_CTL}
 Status:=AX88XXXWriteRXCTL(Device,AX_DEFAULT_RX_CTL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset Medium Mode}
 Status:=AX88XXXWriteMediumMode(Device,AX88772_MEDIUM_DEFAULT);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset IPG}
 Status:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_IPG0,AX88772_IPG0_DEFAULT or AX88772_IPG1_DEFAULT,AX88772_IPG2_DEFAULT,0,nil);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write IPG,IPG1,IPG2 registers: ' + USBStatusToString(Status));
   Exit;
  end;

 {Reset MAC Address}
 Status:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_NODE_ID,0,0,ETHERNET_ADDRESS_SIZE,@Network.HardwareAddress);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset RX_CTL}
 Status:=AX88XXXWriteRXCTL(Device,AX_DEFAULT_RX_CTL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Read RX_CTL}
 if AX88XXXReadRXCTL(Device,Value) = USB_STATUS_SUCCESS then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: RX_CTL value after reset: ' + IntToHex(Value,4));
   {$ENDIF}
  end;

 {Read Medium Status}
 if AX88XXXReadMediumStatus(Device,Value)  = USB_STATUS_SUCCESS then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Medium Status value after reset: ' + IntToHex(Value,4));
   {$ENDIF}
  end;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: ax88772_hw_reset
end;

{==============================================================================}
{AX88772A}
function AX88772AResetHardware(Network:PAX88XXXNetwork):LongWord;
{Reset Hardware function for AX88772A devices}
{Note: Internal use only, caller must hold the device lock}
var
 Value:Word;
 PHY14H:Word;
 PHY15H:Word;
 PHY16H:Word;
 Chipcode:Byte;
 Status:LongWord;
 EmbeddedPHY:LongWord;
 Device:PUSBDevice;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check Network}
 if Network = nil then Exit;

 {Get Device}
 Device:=PUSBDevice(Network.Network.Device.DeviceData);
 if Device = nil then Exit;

 Result:=ERROR_OPERATION_FAILED;

 {Reset GPIO}
 Status:=AX88XXXWriteGPIO(Device,AX_GPIO_RSE,5);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Select PHY}
 EmbeddedPHY:=0;
 if (Network.PHYAddress and $1F) = $10 then EmbeddedPHY:=1;

 Status:=AX88XXXWriteCommand(Device,AX_CMD_SW_PHY_SELECT,EmbeddedPHY or AX_PHYSEL_SSEN,0,0,nil);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to select PHY #1: ' + USBStatusToString(Status));
   Exit;
  end;

 Sleep(10);

 {Software Reset}
 Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPPD or AX_SWRESET_IPRL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 Sleep(10);

 Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPRL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 Sleep(160);

 Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_CLEAR);
 if Status <> USB_STATUS_SUCCESS then Exit;

 Status:=AX88XXXSoftwareReset(Device,AX_SWRESET_IPRL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 Sleep(200);

 //To Do
 //if (in_pm && (!asix_mdio_read_nopm(dev->net, dev->mii.phy_id, MII_PHYSID1)))
 // (
 //  ret = -1;
 //  goto out;
 //  )

 Status:=AX88XXXReadCommand(Device,AX_CMD_STATMNGSTS_REG,0,0,SizeOf(Byte),@Chipcode);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Check Chipcode}
 if (Chipcode and AX_CHIPCODE_MASK) = AX_AX88772B_CHIPCODE then
  begin
   Status:=AX88XXXWriteCommand(Device,AX_QCTCTRL,$8000,$8001,0,nil);
   if Status <> USB_STATUS_SUCCESS then
    begin
     if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write QCTCTRL register: ' + USBStatusToString(Status));
     Exit;
    end;
  end
 else if (Chipcode and AX_CHIPCODE_MASK) = AX_AX88772A_CHIPCODE then
  begin
   {Check if the PHY registers have default settings}
   AX88XXXMDIORead(Device,Network.PHYAddress,AX88772A_PHY14H,PHY14H);

   AX88XXXMDIORead(Device,Network.PHYAddress,AX88772A_PHY15H,PHY15H);

   AX88XXXMDIORead(Device,Network.PHYAddress,AX88772A_PHY16H,PHY16H);

   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: PHY register values PHY14H=' + IntToHex(PHY14H,4) + ' PHY15H=' + IntToHex(PHY15H,4) + ' PHY16H=' + IntToHex(PHY16H,4));
   {$ENDIF}

   {Restore PHY registers default setting if not}
   if PHY14H <> AX88772A_PHY14H_DEFAULT then
    begin
     AX88XXXMDIOWrite(Device,Network.PHYAddress,AX88772A_PHY14H,AX88772A_PHY14H_DEFAULT);
    end;

   if PHY15H <> AX88772A_PHY15H_DEFAULT then
    begin
     AX88XXXMDIOWrite(Device,Network.PHYAddress,AX88772A_PHY15H,AX88772A_PHY15H_DEFAULT);
    end;

   if PHY16H <> AX88772A_PHY16H_DEFAULT then
    begin
     AX88XXXMDIOWrite(Device,Network.PHYAddress,AX88772A_PHY16H,AX88772A_PHY16H_DEFAULT);
    end;
  end;

 {Reset IPG}
 Status:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_IPG0,AX88772_IPG0_DEFAULT or AX88772_IPG1_DEFAULT,AX88772_IPG2_DEFAULT,0,nil);
 if Status <> USB_STATUS_SUCCESS then
  begin
   if USB_LOG_ENABLED then USBLogError(nil,'AX88XXX: Failed to write IPG,IPG1,IPG2 registers: ' + USBStatusToString(Status));
   Exit;
  end;

 {Reset MAC Address}
 Status:=AX88XXXWriteCommand(Device,AX_CMD_WRITE_NODE_ID,0,0,ETHERNET_ADDRESS_SIZE,@Network.HardwareAddress);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset RX_CTL}
 Status:=AX88XXXWriteRXCTL(Device,AX_DEFAULT_RX_CTL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset Medium Mode}
 Status:=AX88XXXWriteMediumMode(Device,AX88772_MEDIUM_DEFAULT);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Reset RX_CTL}
 Status:=AX88XXXWriteRXCTL(Device,AX_DEFAULT_RX_CTL);
 if Status <> USB_STATUS_SUCCESS then Exit;

 {Read RX_CTL}
 if AX88XXXReadRXCTL(Device,Value) = USB_STATUS_SUCCESS then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: RX_CTL value after reset: ' + IntToHex(Value,4));
   {$ENDIF}
  end;

 {Read Medium Status}
 if AX88XXXReadMediumStatus(Device,Value)  = USB_STATUS_SUCCESS then
  begin
   {$IFDEF AX88XXX_DEBUG}
   if USB_LOG_ENABLED then USBLogDebug(Device,'AX88XXX: Medium Status value after reset: ' + IntToHex(Value,4));
   {$ENDIF}
  end;

 {Return Result}
 Result:=ERROR_SUCCESS;

 //To Do //See: ax88772a_hw_reset
end;

{==============================================================================}
{==============================================================================}

initialization
 AX88XXXInit;

{==============================================================================}

finalization
 {Nothing}

{==============================================================================}
{==============================================================================}

end.
