# FlightAware Adaptive Gain Listing
This Linux script command will conveniently list the recent changing gain values from FlightAware's dump1090-fa Adaptive Gain feature.

In September 2021, FlightAware released version 6.0 of their PiAware software. A very interesting new feature included in this version was something called [Adaptive Gain](https://github.com/flightaware/dump1090/blob/main/README.adaptive-gain.md#adaptive-gain-configuration) used by dump1090-fa. In short, the gain value used by dump1090-fa can now be continually and automatically adjusted based on the current environment.

This script will allow a user to see a listing of the changing adaptive gain values from such a setup.

Currently, this script has only been verified with FlightAware's package installation on a Raspberry Pi OS operating system and with FlightAware's PiAware SD card image.

An example of this scipt listing the recent adaptive gain values:

![Adaptive Gains Listing](https://i.imgur.com/JX1orE5.png)


## How to Install
Execute this one command line. The operating system will then have a global command called `adaptivegains`.
```
bash -c "$(wget -qO - https://github.com/mypiaware/flightaware_adaptive_gain_listing/raw/main/install_adaptivegains.sh)"
```


## How to Use
After the command above is executed, simply type `adaptivegains` at any directory location.  A listing of the previous gain values will be displayed along with the date/time stamp of when the gain value changed.  Also included are line numbers on the far left.  Any line with dashes (`---------------------`) is simply indicating a moment when the computer rebooted (see [below](https://github.com/mypiaware/flightaware_adaptive_gain_listing/blob/main/README.md#to-view-more-gain-values) regarding multiple boots).


## Limiting the Number of Lines
By default, the `adaptivegains` command will list all of the available recorded gain values.  If, for some reason, a limit is desired for the number of lines displayed, an argument may be set at the command line such as:

```adaptivegains -10```

The above example will limit the number of displayed lines to 10.


## Enable Adaptive Gain
In order to get a listing of adaptive gains from dump1090-fa, the Adaptive Gain mode must be enabled.  Here is a summary of how to enable Adaptive Gain:

* If using a package installation of dump1090-fa installed on Raspberry Pi OS:
  ```
  if [ ! -f /etc/default/dump1090-fa.original ]; then sudo cp /etc/default/dump1090-fa /etc/default/dump1090-fa.original; fi
  sudo sed -i 's/.*ADAPTIVE_DYNAMIC_RANGE[[:space:]]*=.*/ADAPTIVE_DYNAMIC_RANGE=yes/' /etc/default/dump1090-fa
  sudo systemctl restart dump1090-fa
  ```
* If using the PiAware SD card image:
  ```
  sudo piaware-config adaptive-dynamic-range yes
  sudo systemctl restart dump1090-fa
  ```
  

## To View More Gain Values
(This is for experts only.) By default, the logs from dump1090-fa will only contain the most recent gain values - possibly from less than 24 hours ago - and will also only contain the gain values from the most recent boot.

If wanting to see an exhaustive listing of adaptive gain values from dump1090-fa - including gain values from previous boots, then the following change will need to be made to the journald configuration file.  The following works for both the package installation and SD card image.  Before the first edit of the configuration file is done, a copy of the original configuration file should be made first.  This should only be done one time with the following command:
```
if [ ! -f /etc/systemd/journald.conf.original ]; then sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.original; fi
```  
Make a small edit to the configuration file and restart the journald service with these three commands:
```
sudo sed -i 's/.*Storage[[:space:]]*=.*//' /etc/systemd/journald.conf
echo 'Storage=persistent' | sudo tee -a /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```
From this point on, the `adaptivegains` command will start displaying all of the recent gain values from the current boot and from any of the subsequent boots of the system.

<h3><b>:x: WARNING</b> :x: <b>WARNING</b> :x: <b>WARNING :x:</b></h3>

Although the steps above may provide a very lengthy list of gain values, there are at least two consequences to know about:
* The log files will be continually written to the disk as opposed to volatile memory.
* The log files may grow very large in size in a short amount of time

By default, the journald service will write log files to the `/run/log/journal/` directory - which is a directory that is stored in memory and gets deleted after each computer reboot.  Also by default, because very little storage space is allocated to the `/run/log/journal/` directory, some of the older log files will get purged during the current boot of the system.  This is the reason why some of the older gain values will simply no longer be available - even in the current boot of the system.

If the journald service is configured to use persistence storage, journald will then continually save the log files to the disk.  The journald service will then begin to save all current gain values from the current boot and future boots of the system.  However, there will be many writes done to the disk.  If using a Raspberry Pi with an SD card, the SD card may be subject to some wear, and the life of the SD card may be deteriated.  Also, the size of the log files will grow quite large in size in a short amount of time - possibly around 100 MB in one day!

<b>It is strongly recommended to only run journald with persistence for a short amount of time</b> - possibly only for a few days at the most.  It is very simple to revert journald to using volatile memory again with the following two commands:
```
sudo sed -i 's/.*Storage[[:space:]]*=.*/Storage=volatile/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```
