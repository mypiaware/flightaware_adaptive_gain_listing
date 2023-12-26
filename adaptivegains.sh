#!/bin/bash

# A script to display the adaptive gain values used by FlightAware's dump1090-fa ver 6.0 and higher if the Adaptive Gain mode is enabled.
# https://github.com/mypiaware/flightaware_adaptive_gain_listing/
# Version 2.01

VERSION="2.01"

SCRIPTNAME=`basename "$0"`  # Get the name of this script in the event it has been changed from the default name of 'adaptivegains'.

# Check for a help request.
if [[ $1 =~ ^-\?$ ]] || [[ $1 =~ ^--?help$ ]]; then
   printf "\033[0;36mFlightAware dump1090-fa Adaptive Gains Listing (ver $VERSION)\033[0m\n\n"
   printf "Simply run this command to view all available recorded gain values:\n"
   printf "   \033[1m$SCRIPTNAME\033[0m\n\n"
   printf "To limit the number of displayed lines:\n"
   printf "   \033[1m$SCRIPTNAME -#\033[0m  (# is the number of lines to limit)\n\n"
   printf "\033[1;34mFor more help:\n"
   printf "https://github.com/mypiaware/flightaware_adaptive_gain_listing/\033[0m\n"
   exit 0
fi

# Check if dump1090-fa is installed and its version is at least 6.0.
if [[ $(dump1090-fa --version 2> /dev/null) =~ dump1090-fa[[:space:]]+([[:digit:]]+)\.[[:digit:]]+ ]]; then
   DUMP_VERSION=${BASH_REMATCH[1]}
fi
if [ -z $DUMP_VERSION ] || [ $DUMP_VERSION -lt 6 ]; then
   printf "\033[1;31mdump1090-fa version 6.0 or higher must be installed!\033[0m\n"
   exit 1
fi

# Check for invalid arguments.
if [[ $# -gt 1 ]] || ([[ $# -eq 1 ]] && ! [[ $1 =~ ^-[[:digit:]]+$ ]]); then
   printf "\033[1;31mInvalid argument!\033[0m\n"
   printf "For help:  $SCRIPTNAME --help\n"
   exit 2
fi

# By default, this script is set to list all recorded gain values.  An input argument may be set at the command line to limit the number of displayed lines.  Or, the line display limit may be hard-coded here as well.
if [[ $# -eq 1 ]] && [[ $1 =~ ^-([[:digit:]]+)$ ]]; then
   LINELIMIT=${BASH_REMATCH[1]}  # First, make an attempt to read in an input argument from the command line that decides how many lines should be displayed.  Otherwise, use a hard-coded value below.
else
   LINELIMIT=0  # Use a value of '0' to list all recorded gain values.  Otherwise, select an integer greater than '0' to limit the display to a number of the most recent recorded gain values.
fi

# Check if Adaptive Gain mode is enabled.
if ! systemctl status dump1090-fa | grep -qEi 'adaptive-range'; then
   AG_ENABLED=0
else
   AG_ENABLED=1
fi

# Save all available recorded gain values along with timestamps to a TIMESGAINS array.
declare -a TIMESGAINS
OLDESTBOOT="$(($(sudo journalctl --list-boots | wc -l)-1))"  # Numeric value of oldest boot.  (Only relevant if storage is set to persistent.)
LINECOUNT=0
for (( b=$OLDESTBOOT; b>=0; b-- )); do
   LOGOUTPUT="$(sudo journalctl -u dump1090-fa.service -b -$b --lines=all --no-hostname --no-pager 2> /dev/null)"
   if [[ $? -eq 0 ]]; then  # Ignore any rare instance a very quick reboot occurring and no values getting recorded by journald.
      while read LOGLINE; do
         MYREGEX='^([[:alpha:]]{3}\s+[[:digit:]]{2}\s+[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2})\s+dump1090-fa\[[[:digit:]]+\]:\s+rtlsdr:\s+tuner\s+gain\s+set\s+to\s+([[:digit:]]+\.[[:digit:]])\s+dB'
         if [[ "$LOGLINE" =~ $MYREGEX ]]; then
            TIMESGAINS[$LINECOUNT]="$(printf "%-17s%4s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}")"  # Date/time & gain value.
            ((LINECOUNT+=1))
         fi
      done <<< "$LOGOUTPUT"
      if [[ $b -gt 0 ]]; then
         TIMESGAINS[$LINECOUNT]="---------------------"  # A printed line of dashes indicates when the device has been rebooted.  (Only relevant if 'Storage=persistent' is set in the '/etc/systemd/journald.conf' file.)
         ((LINECOUNT+=1))
      fi
   fi
done

# Print results
if [[ $AG_ENABLED -eq 1 ]] && [[ ${#TIMESGAINS[@]} -eq 0 ]]; then
   # In the rare instance Adaptive Gain was just very recently enabled and the first adaptive gain value has yet to be determined.
   printf "Adaptive Gains are being calculated. Please wait a few minutes...\n"
   exit 0
else
   # Give a warning to inform user that Adaptive Gain mode is not enabled.
   if [[ $AG_ENABLED -eq 0 ]]; then
      printf "\033[1;31mWarning: Adaptive Gain mode is not enabled!\033[0m\n"
      printf "For help:  $SCRIPTNAME --help\n"
   fi
   # For the sake of formatting the length of the field used by the line numbers.
   if [[ $LINELIMIT -eq 0 ]] || [[ ${#TIMESGAINS[@]} -le $LINELIMIT ]]; then
        LINECOUNTLENGTH=$(expr length ${#TIMESGAINS[@]});
   else LINECOUNTLENGTH=$(expr length $LINELIMIT)
   fi
   # Print all or a portion of the TIMESGAINS array along with line numbers.
   STARTLINE="$((${#TIMESGAINS[@]}-$LINELIMIT))"
   if [[ $STARTLINE  -lt 0 ]] || [[ $LINELIMIT -eq 0 ]]; then STARTLINE=0; fi  # Adjust STARTLINE if necessary.
   LINENUM=1
   for LINEPRINT in "${TIMESGAINS[@]:${STARTLINE}}"; do  # Print from the start of the array or from a certain index value.
      printf "%${LINECOUNTLENGTH}s  %s\n" $LINENUM "$LINEPRINT"
      ((LINENUM+=1))
   done
fi

# Gain values may still be displayed if they have been recorded eariler while Adaptive Gain mode was only recently enabled but is currently not enabled.
if [[ $AG_ENABLED -eq 0 ]]; then
   exit 3
else
   exit 0
fi
