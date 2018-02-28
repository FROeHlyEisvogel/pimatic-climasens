pimatic-climate-sensor
====================

Pimatic Plugin that monitors BLE-ClimateSensors.

Configuration
-------------
This plugin is running and tested on raspberry pi and should also work on all other linux distributions.
It requires the "bluez" bluetooth protocol stack for linux.

Copy the whole folder into the "pimatic-app/node_modules/" folder.
After restarting pimatic the plugin will show up in the plugins section.

It is recommented to use a second bluetooth adapter exclusively for this plugin.
The bluetooth adapter has to provide the bluetooth low energy protocol (> v.4.0).


Adding-Devices
--------------
To add an device you can use the "discover devices" function from pimatic.