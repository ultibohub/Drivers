## Ultibo Drivers

This repository contains a collection of additional drivers for various hardware and devices.

While key drivers supporting common and standard devices will continue to be added to the Core repository other drivers will be collected here.

Where possible all drivers in this repository are intended to be platform neutral, any that rely on a particular platform, architecture or model of SoC will be clearly indicated.

Contributions of additional drivers are welcome, while drivers that utilize the device model in Ultibo core are preferred we will accept contributions that simply interface directly with a specific piece of hardware.

Please try to include any relevant information about supported devices and models in the header of the driver unit along with brief instructions on how to use the driver. Drivers can be written in any of the languages supported by the Ultibo API.

_Note that there isn't much here yet, if you have created a driver (even a simple one) consider contributing it so others can use it too._

### Driver categories

Additional categories will be added as required.

#### Display

Framebuffer and display device drivers.

#### GPIO

Drivers supports GPIO functionality, including multiplexer and extender devices as well as I2C, SPI and USB devices which provide GPIO functionality.

#### Input

Input devices such as keyboard, mouse and other button/control handling devices.

#### Network

Drivers for network devices such as USB dongles, note that drivers for on board devices will normally be included in the Core repository.

#### Touch

Touch screen and digitizer drivers.

#### Misc

Miscellaneous drivers that don't fit into any other category or mini drivers that provide access to optional functionality.

#### Experimental

Purely experimental (and possibly non functional) drivers that are for testing, development and/or feedback.

