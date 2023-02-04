#!/bin/bash

# Simple installation script to download and install/update the 'adaptivegains' command for dump1090-fa.
# https://github.com/mypiaware/flightaware_adaptive_gain_listing

AGCMD="/usr/local/bin/adaptivegains"
URL="https://github.com/mypiaware/flightaware_adaptive_gain_listing/raw/main/adaptivegains.sh"
CHECKSUM="ffd66b18206d4465d7733e3c3a7ff2f2"  # Checksum of 'adaptivegains.sh' (verson 1.2).  [Needs to be all lowercase]

if ! [ -f "$AGCMD" ]; then
   while ! [[ $USERCHOICE =~ ^[YyNn]$ ]]; do printf "Download & install the 'adaptivegains' command? [y/n]: "; read USERCHOICE; done
else
   while ! [[ $USERCHOICE =~ ^[YyNn]$ ]]; do printf "Download & reinstall/update the 'adaptivegains' command? [y/n]: "; read USERCHOICE; done
fi

if [[ $USERCHOICE =~ [Yy] ]]; then
   sudo mv "$AGCMD" "${AGCMD}".old >/dev/null 2>&1
   printf "\n"
   sudo wget -q --show-progress "$URL" -O "$AGCMD"
   printf "\n"
   if [ -f "$AGCMD" ] && [[ $(md5sum "$AGCMD") =~ $CHECKSUM ]] ; then
      if ! [ -f "$AGCMD".old ]; then ACTION="installed"
      elif diff "$AGCMD".old "$AGCMD" >/dev/null 2>&1; then ACTION="reinstalled"
      else ACTION="updated"
      fi
      sudo chmod +x "$AGCMD"
      sudo rm -f "${AGCMD}".old
      printf "\033[1;32mSUCCESS: The 'adaptivegains' command was $ACTION!\033[0m\n\n"
      exit 0
   else
      if [ -f "${AGCMD}".old ]; then ACTION="update"; else ACTION="install"; fi
      sudo rm -f "$AGCMD"
      sudo mv "${AGCMD}".old "$AGCMD" >/dev/null 2>&1
      printf "\033[1;31mERROR: Failure trying to $ACTION the 'adaptivegains' command!\033[0m\n\n"
      exit 1
   fi
else
   exit 0
fi
