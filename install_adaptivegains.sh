#!/bin/bash

# Simple installation script to download and install/update the 'adaptivegains' command for dump1090-fa.
# https://github.com/mypiaware/flightaware_adaptive_gain_listing

AGCMD="/usr/local/bin/adaptivegains"
URL="https://github.com/mypiaware/flightaware_adaptive_gain_listing/raw/main/adaptivegains.sh"
CHECKSUM="a938f205f520119e74045a2b9c39beee"  # MD5 Checksum of 'adaptivegains.sh' (verson 2.01).  [Needs to be all lowercase]
LATESTVERSION="2.01"

if [ -f "$AGCMD" ] && [[ $(md5sum "$AGCMD") =~ $CHECKSUM ]]; then
   printf "\033[1;34mThe installed version of 'adaptivegains' is the latest version (version $LATESTVERSION).\033[0m\n"
   exit 0
elif [ -f "$AGCMD" ] && [[ ! $(md5sum "$AGCMD") =~ $CHECKSUM ]]; then
   while ! [[ $USERCHOICE =~ ^[YyNn]$ ]]; do printf "\033[1;33mDownload & update the 'adaptivegains' command? [y/n]:\033[0m "; read USERCHOICE; done
   if [[ $USERCHOICE =~ [Yy] ]]; then ACTION="update"; else exit 0; fi
elif ! [ -f "$AGCMD" ]; then
   while ! [[ $USERCHOICE =~ ^[YyNn]$ ]]; do printf "\033[1;33mDownload & install the 'adaptivegains' command? [y/n]:\033[0m "; read USERCHOICE; done
   if [[ $USERCHOICE =~ [Yy] ]]; then ACTION="install"; else exit 0; fi
else
   printf "Unknown error occurred!\n"
   exit 3  # Script should never reach this point.
fi

if [ $ACTION = "update" ]; then
   sudo mv "$AGCMD" "${AGCMD}".old >/dev/null 2>&1
   printf "\n"
   sudo wget -q --show-progress "$URL" -O "$AGCMD"
   printf "\n"
   if [ -f "$AGCMD" ] && [[ $(md5sum "$AGCMD") =~ $CHECKSUM ]]; then
      sudo chmod +x "$AGCMD"
      sudo rm -f "${AGCMD}".old
      printf "\033[1;32mSUCCESS: The 'adaptivegains' command was updated to version $LATESTVERSION!\033[0m\n\n"
      exit 0
   else
      printf "\033[1;31mERROR: Failure trying to update the 'adaptivegains' command!\033[0m\n\n"
      sudo mv "${AGCMD}".old "$AGCMD" >/dev/null 2>&1
      exit 1
   fi
fi

if [ $ACTION = "install" ]; then
   printf "\n"
   sudo wget -q --show-progress "$URL" -O "$AGCMD"
   printf "\n"
   if [ -f "$AGCMD" ] && [[ $(md5sum "$AGCMD") =~ $CHECKSUM ]] ; then
      sudo chmod +x "$AGCMD"
      printf "\033[1;32mSUCCESS: The 'adaptivegains' command (version $LATESTVERSION) was installed!\033[0m\n\n"
      exit 0
   else
      printf "\033[1;31mERROR: Failure trying to install the 'adaptivegains' command!\033[0m\n\n"
      exit 2
   fi
fi

printf "Unknown error occurred!\n"
exit 4  # Script should never reach this point.
