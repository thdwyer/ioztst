#!/bin/bash
##########
#
# Project     : iozone shell wrapper
# Version     : ver 0.90.6
# Started     : Wed 31 Jul 2024
# Author      : Terry Dwyer
# Module      :
# Purpose     : Setup and run throughput drive tests using the iozone utility.
#             :
# Description : If you use the examples be careful of the file sizes you pick
#             : I'd suggest doing the throughput (individual) test and an
#             : initial tests numbered 0,1 and 2, thread number of 4 and test
#             : file size no greater than 2GB. Max number of files 4 min number
#             : of files doesn't matter
#             : The suggested figures will use 8GB of disk space during the test
#             : If you have another drive mounted it's probably useful, given
#             : enough space to use that even if it's a USB device.
#             : The device I'm running my tests on is a USB3 dock with
#             : 5 4TB drives in a zfs array.
#
# Todo list   : See past EOF for list
#
##########

# start of code here

#################################################
# This variable if set to anything other than   #
# YES will prevent iozone from running          #
# Change this if tou want to produce a load     #
# ioz.sh files (only in the "Run" directory     #
# There can be only 2 files in the Default      #
# directory Auto.ioz.sh and Tput.ioz.sh         #
#                                               #
# Case of the variable value is important       #
# It MUST be uppercase YES or no test will run  #
# Or from the command line invoke with anything #
# other than YES and iozone will not run        #
# running the script without a parameter will   #
# allown it t0 run as usual                     #
#################################################

enableiozone=YES  # set to NO to turn off Default is on
cmdpassed=$1
if [ ${cmdpassed} == "YES" ] || [ -z ${cmdpassed} ]; then
   enableiozone=YES
else
   enableiozone=NO
fi
shopt -s nullglob
# Get the name of the running script
iam=$(basename $(readlink -nf $0))
# Get the version of this script from the header
version=`grep "^# Version" ${iam} | awk '{print $NF}'`
#echo "   >>> Version ${version}"; echo ; sleep 3
export TIME="\t%E real,\t%U user,\t%S sys"
timecmd=/usr/bin/time
# Replaces all spaces in the returned date value with underscores
datevar=`date | sed '{s/ /_/g}'`

clear

# Just to be clear, yu should not do too much testing
# on an SSD or you might shorten the life of it
# It's much preferable to use a spinning drive
# The faster the better.
# Your home directory - don't use tghis much if it's on an SSD
# basedir=$HOME
# Examples ZFS array on another machine
# basedir=/media/tdwyer/usbarray/
# Used for testing on my fstab mounted CIFS share on the media server ZFS arraay
# basedir=$HOME/Desktop/Media
# this is a Hitachi drive I use for backups and some storage
# "/media/tdwyer/Hitachi 4TB #1"
# basedir="/media/tdwyer/Hitachi 4TB #1"


# Read in the variables from the config file
source $HOME/.config/ioztst/iozconf

####################################################
# Uncomment the line "show_dirs" on the last line  #
# of the block.This function will show you all the #
# directories and result file settings             #
####################################################
function show_dirs {
   if [ "${dontclear}" != "true" ]; then
      clear
   fi
   echo
   echo " -----------------------------------------------------------------------------------"
   echo " |                            <<< Ver: ${version} >>>                                    |"
   echo " -----------------------------------------------------------------------------------"
   echo " |           Complete list of directory and files from your variables              |"
   echo " -----------------------------------------------------------------------------------"
   echo " |         Description          |  variable name  |         Variable data          |"
   echo " -----------------------------------------------------------------------------------"
   echo "------------------------------------------------------------------------------------"
   echo "                    Run iozone:   enableiozone      ${enableiozone}"
   echo "------------------------------------------------------------------------------------"
   echo "                       Basedir:   basedir           ${basedir}"
   echo "                       Testdir:   testdir           ${testdir}"
   echo "                     Targetdir:   targetdir         ${targetdir}"
   echo "                     Resultdir:   resultdir         ${resultdir}"
   echo "                    Resultfile:   resultfile        ${resultfile}"
   echo "           Screen Capture file:   scrncapfile       ${scrncapfile}"
   echo "                   Result file:   result            ${result}"
   echo "           Screen Capture file:   scrncap           ${scrncap}"
   echo " -----------------------------------------------------------------------------------"
   echo "            Saved Test Basedir:   savedtestbasedir  ${savedtestbasedir}"
   echo "            Saved This Run dir:   savedrun          ${savedrun}"
   echo "             Saved Default dir:   saveddefaults     ${saveddefaults}"
   echo "      Saved This Run Auto file:   Asaverunfile      ${Asaverunfile}"
   echo "      Saved This Run Tput file:   Tsaverunfile      ${Tsaverunfile}"
   echo "       Saved Default Auto file:   Asavedefaultfile  ${Asavedefaultfile}"
   echo "       Saved Default Tput file:   Tsavedefaultfile  ${Tsavedefaultfile}"
   echo " -----------------------------------------------------------------------------------"
   echo
   exit 1
}
### Uncomment the following line to see all your variable settings
#show_dirs
########################################################
# When you've finished testing comment the "show_dirs" #
# function call again so you can continue with testing #
########################################################

# Check to ensure that basedir is set in $HOME/.config/ioztst/iozconf
if [ ! -d "${basedir}/" ]; then
   clear
   echo
   echo "  >>> The \$basedir variable is empty or is not set correctly:"
   echo
   echo "  basedir=[${basedir}]  << Look for this in the file and edit it"
   echo "    In the line above, the space between the brackets"
   echo "    should not be empty. it should show the path to the"
   echo "    directory on the drive/array where you want to do the testing"
   echo "  Please set this variable in the config file before proceding"
   echo "  The config file is: $HOME/.config/ioztst/iozconf"
   echo "  Use the examples to guide your Basedir variable entry"
   echo
   echo "  Here is a full list of the appropriate variables used in your script"
   dontclear=true
   show_dirs
   exit 1
fi
#
# Check that iozone is installed.  If not prompt the user
if [ ! -f "/usr/bin/iozone" ] && [ "${enableiozone}" != "NO" ] ; then
   clear
   echo
   echo "  >>> You have not yet installed iozone on this system:"
   echo
   echo "  You can install the package with the command:"
   echo
   echo "   [sudo apt install iozone3]"
   echo
   echo "  Or run without it in demo mode or to create and save"
   echo "  testing definitions.  To run in demo mode: [ioztst.sh no]"
   exit 1
fi

###########################################################################
# Start of How much free space is there on $targetdir and filesystem type #
###########################################################################
diskspace=`df -h "${targetdir}" -T | awk 'END{print $5}'` ; echo "${diskspace}"
filesystype=`df -h "${targetdir}" -T | awk 'END{print $2}'` ; echo "${filesystype}"

if [ ${filesystype} = "zfs"  ]; then
   echo "Type ${filesystype} System File Cacheing and ZFS de-dup can be disabled (-I -+w 1 -+y 1 -+C 1 switches)"
   echo " ${filesystype} <<< ${diskspace} >>>"
else #if [ ${filesystype} = "ext4"  ]; then  ## Might need this later for EXT4 or NFS etc.
   echo "${filesystype} <<< ${diskspace} >>>"
   echo "Type ${filesystype} only system cacheing may be disable (-I switch)"
fi

#clear
#########################################################################
# End of How much free space is there on $targetdir and filesystem type #
#########################################################################

#######################################################
# This is the switchable MULTI/SINGLE select function #
#######################################################
function prompt_for_select {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()         {
      local key
      IFS= read -rsn1 key 2>/dev/null >&2
      if [[ $key = ""      ]]; then echo enter; fi;
      if [[ $key = $'\x20' ]]; then echo space; fi;
      if [[ $key = $'\x1b' ]]; then
        read -rsn2 key
        if [[ $key = [A ]]; then echo up;    fi;
        if [[ $key = [B ]]; then echo down;  fi;
      fi
    }
    toggle_option()    {
      local arr_name=$1
      eval "local arr=(\"\${${arr_name}[@]}\")"
      local option=$2
      if [[ ${arr[option]} == true ]]; then
        arr[option]=
      else
        arr[option]=true
      fi
      eval $arr_name='("${arr[@]}")'
    }

    ### THD
    ### This allows the cursor keys to switch off the previousley selected option
    turnoff_option() {
      local arr_name=$1
      eval "local arr=(\"\${${arr_name}[@]}\")"
      local option=$2
      # Modified from empty arr[option]=
      arr[option]=false
      eval $arr_name='("${arr[@]}")'
    }
    ### THD

    local retval=$1
    local options
    local defaults

    IFS=';' read -r -a options <<< "$2"
    if [[ -z $3 ]]; then
      defaults=()
    else
      IFS=';' read -r -a defaults <<< "$3"
    fi
    local selected=()

    for ((i=0; i<${#options[@]}; i++)); do
      selected+=("${defaults[i]:-false}")
      printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[x]"
            fi
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $active ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done

        # user key control
        ### THD
        ### This allows the cursor keys to switch off the previousley selected option
        case `key_input` in
            space)  toggle_option selected $active;;
            enter)  break;;
            up)     if [ $select_one -eq 1 ]; then turnoff_option selected $active; fi; ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   if [ $select_one -eq 1 ]; then turnoff_option selected $active; fi; ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done
    ### THD

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $retval='("${selected[@]}")'
}
##########################################################
# This is end of switchable MULTI/SINGLE select function #
##########################################################

##########################################################
# This function sets up parameters to be handed to       #
# the function prompt_for_select and calls it            #
##########################################################
function single_select {
   # This is be a single selection menu item. Set select_one to 1
   select_one=1 # Single selection menu item

   for i in "${!OPTION_VALUES[@]}"; do
      OPTION_STRING+="${OPTION_VALUES[$i]} (${OPTION_LABELS[$i]});"
   done
   clear

   echo
   echo " <<< Available space: ${diskspace} >>>"
   echo " <<< Filesystem type: ${filesystype} >>>"
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   prompt_for_select SELECTED1 "$OPTION_STRING"
   for i in "${!SELECTED1[@]}"; do
   	  if [ "${SELECTED1[$i]}" == "true" ]; then
		  CHECKED1+=("${OPTION_VALUES[$i]}")
          current="${OPTION_VALUES[$i]}"
          currstring="${OPTION_LABELS[$i]}"
      fi
   done
   ### debugging
   #size=${CHECKED1[@]}
   #statelist=${SELECTED1[@]}
   #echo "Current selection: $current  $currstring"
   #echo "Your selection: ${size}  ${statelist}"
   echo
}
##########################################################
# End of function single_select                          #
##########################################################

############################################################
# Start of type of test setting throughput (1) or auto (2) #
############################################################
function start_test {
testtype=1
if [ ${testtype} -eq 1  ] ; then # Throughput mode
   #testparm="${testtype}" # Test Mode: Throughput or All
   testtype=
   default_select=0 ; current=  ## Adress of first element in the options array
   current=
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   #OPTION_VALUES=("1" "2")
   #OPTION_LABELS=("Throughput test" "Run All tests")
   OPTION_VALUES=("1" "2" "3" "4" "5" "6" "7" "8" "0")
   OPTION_LABELS=("New Throughput test" "New Auto test" "Save new Throughput test" \
                  "Save new Auto test" "Save Default Throughput test" "Save Default Auto test" \
                  "Choose saved test to change or rerun" "Run full auto test (No save)" "Exit")

   MESSAGE1=" Choose the test mode. <<< Ver: ${version} >>>"
   MESSAGE2=" Default selection is [1]"
   MESSAGE3=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   MESSAGE4=" >> <Ctrl>C at any time to exit"
   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      testtype=${default_select} ; current=${default_select} # Set to throughput by default if no choice is made
      testtype=${OPTION_VALUES[$current]}
      testlabel=${OPTION_LABELS[$current]}
      ### Debugging
      #echo "Testtype:  ${testtype}"
      #echo "Testlabel: ${testlabel}"
   else
      testtype=${current}
      testlabel=${currstring}
   fi
   testmode=${testtype}

   ## For filenaming the saved tests and Loading the saved tests:
   if [ "${testtype}" == 1 ] || [ "${testtype}" == 2 ]; then
      if [ "${testtype}" == 1 ]; then
         testdesc=1
      elif [ "${testtype}" == 2 ]; then
         testdesc=2
      fi
      TT="New"           # Set save test type to New - unsaved
      #display_filelist
   elif [ "${testtype}" == 3 ] || [ "${testtype}" == 5 ]; then
      if [ "${testtype}" == 3 ]; then
         testdesc="1 S"
      elif [ "${testtype}" == 5 ]; then
         testdesc="1 D"
      fi
      TT="Tput"           # Set save test type to Throughput
      #display_filelist
   elif [ "${testtype}" == 4 ] || [ "${testtype}" == 6 ]; then
      if [ "${testtype}" == 4 ]; then
         testdesc="2 S"
      elif [ "${testtype}" == 6 ]; then
         testdesc="2 D"
      fi
      TT="Auto"           #  Set save test type to Auto
      #display_filelist
   elif [ "${testtype}" == 7 ]; then
      TT="Load"           #  Set save test type to Auto
      testdesc="L"
      display_filelist
      loadtestrun         # Go to the loadtest function

   elif [ "${testtype}" == 8 ]; then
      TT="FullAuto"           #  Set save test type to Auto
      testdesc="F A"
      # Set the only variables necessary for a full auto test
      # -a -+u -R -f [directory where tests will take place] -b [Excel results file]
      # This is done at the place where the parameters are assembled and written to a file
   elif [ "${testtype}" == 0 ]; then
      echo
      echo "   Exiting..." ; echo ; exit 0
   fi

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo
      if [  -z "${testtype}" ]; then
         echo "Error: You should not be here.  The default option was not used"
      else
         echo "Test options selected: [${testtype}], (${testlabel}).   Test Type is [${TT}]   Test Descr is [${testdesc}]"
         #echo "Test Type (TT): ${TT}    Descr: ${OPTION_LABELS[$current]}"
      fi
      echo
      read -p " >>> Press <Enter> to continue" z
   fi
fi
# Save these for use in the next routine
origtestmode=$testmode ; origtestlabel=$testlabel ; origTT=${TT} ; origtestdesc=${testdesc} ; origtesttype=${testtype}
}
# testtype
##########################################################
# End of type of test setting throughput (1) or auto (2) #
##########################################################

################################################
# Start of procedure to actually run the tests #
################################################
function runtest {
   thisdir=`pwd`
   testfiletype=`echo ${runfile} | cut -d "-" -f 1`
   if [ "${testfiletype}" == "Tput" ]; then
   testtype=1
   elif [ "${testfiletype}" == "Auto" ]; then
   testtype=2
   fi
   #echo "FileType: ${testfiletype}"
   #echo "Testtype: |${origtest}| |(${testtype})|"
   #echo "Testtype: ${testtype}"

   if [ "${thisdir}" == "${targetdir}" ] ; then
      clear
      echo
      echo "   <<< Ready to test >>>" ; sleep 1 ; echo
      #echo "testtype:  ${testtype}"
      read -p "   Press Enter to start testing" a ; echo
      ### Debug
      #echo "0 Test Type (TT): ${TT}"
      #echo "Testtype: ${testtype}  Origtest: ${origtest}"
# 1 -------
      if [ "${testtype}" == "1" ] ; then
         # Individual tests
         testtype=${origtest}
         echo "   1 Test Type (TT): ${TT}"
         echo "   Running Throughput test..."
         if [ ${TT} != "Load" ]; then
            # Need to source the commands from a here file or the -F parameter is not passed to iozone correctly
            echo "${timecmd} iozone -e -+u -R ${iopts} ${clist} -l ${lowlim} -u ${uplim} -r ${recsize}k \
                                    -s ${fsize}g -t ${threads} -F \"${basedir}\"/$testdir/f${filelist} -b $result" \
                                    | tr -s "[:blank:]" > "$targetdir/ioz.sh"
            # Call to savefile goes here
            savetestrun
         fi

         #  <<< At the beginning of the script >>>
         # Set the following variable to anything
         # other than uppercase YES to prevent
         # iozone from running.
         if [ "${enableiozone}" == "YES"  ]; then
            testfiletype=`echo ${runfile} | cut -d "-" -f 1`
            echo "   FileType: ${testfiletype}"
            echo "   Iozone enanbled: ${enableiozone}"
            echo "   Loading and running Throughput test: $targetdir/ioz.sh"
            echo
            source "$targetdir/ioz.sh" | tee ${scrncap}
         fi

         mv "$targetdir/ioz.sh" "$targetdir/ioz-old.sh"
# End 1 -------
# 2 -------
      elif [ "${testtype}" == "2" ] ; then
         testtype=${origtest}
         echo "   2 Test Type (TT): ${TT}"
         echo "   Running Auto test..."
         if [ ${TT} != "Load" ]; then
            # Need to source the commands from a here file or the -F parameter is not passed to iozone correctly
            echo "${timecmd} iozone -a -+u -R ${clist} ${switchstring} -r ${recsize}k \
                                    -f \"${basedir}\"/$testdir/testfile -b $result" \
                                    | tr -s "[:blank:]" > "$targetdir/ioz.sh"
            # Call to savefile goes here
            savetestrun
         fi

         #  <<< At the beginning of the script >>>
         # Set the following variable to anything
         # other than uppercase YES to prevent
         # iozone from running.
         if [ "${enableiozone}" == "YES"  ]; then
            testfiletype=`echo ${runfile} | cut -d "-" -f 1`
            echo "   FileType: ${testfiletype}"
            echo "   Iozone enanbled: ${enableiozone}"
            echo "   Loading and running Auto test: $targetdir/ioz.sh"
            echo
            source "$targetdir/ioz.sh" | tee ${scrncap}
         fi

         mv "$targetdir/ioz.sh" "$targetdir/ioz-old.sh"
# End 2 -------
# 3 -------
      elif [ "${testtype}" == "8" ] ; then
         testtype=${origtest}
         echo "   2 Test Type (TT): ${TT}"
         echo "   Running Auto test..."
         if [ ${TT} != "Load" ]; then
            # Need to source the commands from a here file or the -F parameter is not passed to iozone correctly
            echo "${timecmd} iozone -a -+u -R -f \"${basedir}\"/$testdir/testfile -b $result" \
                                    | tr -s "[:blank:]" > "$targetdir/ioz.sh"
         fi

         #  <<< At the beginning of the script >>>
         # Set the following variable to anything
         # other than uppercase YES to prevent
         # iozone from running.
         if [ "${enableiozone}" == "YES"  ]; then
            testfiletype=`echo ${runfile} | cut -d "-" -f 1`
            echo "   FileType: ${testfiletype}"
            echo "   Iozone enanbled: ${enableiozone}"
            echo "   Loading and running Auto test: $targetdir/ioz.sh"
            echo
            source "$targetdir/ioz.sh" | tee ${scrncap}
         fi

         mv "$targetdir/ioz.sh" "$targetdir/ioz-old.sh"
      fi
# End 3 -------
   else
      echo "Your Basedir is set to: ${basedir}   Your Testdir is set to: ${testdir}"
         read -p "Oops  ${thisdir} != ${targetdir}    Press Enter to exit failed test attempt" a ; echo
      fi
   echo
   ### Debug
   #read -p "Press Enter to continue" a

   exit 1
}
##############################################
# End of procedure to actually run the tests #
##############################################

#################################
# End of file counting function #
#################################
function countfiles {
   # unlike ll | wc -l,this only counts the real number
   # of files in a directory and ignores subdirs
   ff="`ls -l | grep '^-' | awk '{print $9}' | wc -l`"; numfiles=${ff} #; echo ${numfiles}
}
#################################
# End of file counting function #
#################################

###################################################################
# start of Number of files passed from the file selector routine  #
###################################################################
function FileNumbers {
   counter=1
   # Number of files passed from the file selector routine
   # This is intended to fill out the parameters for the
   # '-f' option for the multiple files required.
   # eg. <filename>{1,2,3,4}
   numbers=$threads

   for counter in $(seq ${counter} ${numbers})
   do
      if [ $counter -lt $numbers ]; then
         list="$list$counter,"
      else
         list="$list$counter"
      fi
      counter=$((counter+1))
   done
   filelist='{'$list'}'
   #echo ${filelist}
}
# filelist
#################################################################
# End of Number of files passed from the file selector routine  #
#################################################################

########################################################################################
# Start of test to eliminate errors when changing the drive/array the test will run on #
########################################################################################
function quote_basename {
   basename= ; newbasedir=
   iamhere=`pwd` #; echo "  PWD: ${iamhere}"
   # Search for the string "-f" or "-F"
   tputorauto=`grep -o -P '(-[f|F])' ${arrayfile}`
   ### Debug

   if [ ${tputorauto} == "-f" ]; then

      # test directory has a lowercase 'f' so it's auto mode with one file
      #filetgtdir=`grep -o -P '(?<=-f ).*(?=/testfile -b)' "${arrayfile}"`
      filetgtdir=`grep -o -P '(?<=-f ).*(?=/tmptest)' ${arrayfile}`
      filetgtdir="${filetgtdir}/tmptest"
      ### Debug
      skip=yes       # yes no or empty
      if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
         echo " >>> File mode selection"
         iamhere=`pwd`
         echo "                            Iamhere: ${iamhere}"
         echo "                       Test type is: Auto"
         echo "  Throughput test file targetdir is: ${filetgtdir}"
         echo "               Current targetdir is: ${targetdir}"
         echo "                       Arrayfile is: ${arrayfile}"
         echo
         read -p " >>> Press <Enter> to continue" z
      fi
   else
      # test directory has a uppercase 'F' so it's throughput with multiple files
      #filetgtdir=`grep -o -P '(?<=-F ).*(?=f{)' "${arrayfile}"`
      filetgtdir=`grep -o -P '(?<=-F ).*(?=/tmptest)' ${arrayfile}`
      filetgtdir="${filetgtdir}/tmptest"
      ### Debug
      skip=yes       # yes no or empty
      if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
         echo " >>> File mode selection"
         iamhere=`pwd`
         echo "                 Test type is: Throughput"
         echo "  Auto test file targetdir is: ${filetgtdir}"
         echo "         Current targetdir is: ${targetdir}"
         echo "                 Arrayfile is: ${arrayfile}"
         echo
         read -p " >>> Press <Enter> to continue" z
      fi
   fi
   # see it there is a double quote char in the variable string
   # If so it's already been quoted
   if ! [[ "$filetgtdir" =~ '"' ]]; then
      # So the string value will already be surrounded by quotes
      echo
      #echo "  Filetgtdir: |${filetgtdir}|  Targetdir: |${targetdir}|" #; echo "NoQuotes"
   else
      echo
      #echo "  Filetgtdir: |${filetgtdir}|  Targetdir: |${targetdir}|" #; echo "Quotes"
   fi
}
######################################################################################
# End of test to eliminate errors when changing the drive/array the test will run on #
######################################################################################

##########################################################################
# Start of edit all the ${basedir} strings to contain the changed string #
##########################################################################

function edit_basedir {
   DEFFILES={} ; DEFINDEX={} ; RUNFILES={} ; RUNINDEX={}
   if [ ${looping} -eq "1" ]; then
   # correct the basedir value so it is inserted into the ioz.sh run file
   targetdir=\"$basedir\"/$testdir
   ## <1
      # Defaults Directory
      cd ${saveddefaults}
      iamhere=`pwd`
      echo "      Current directory ${iamhere}"
      # Loop through the 2 saved Auto-ioz.sh & Tput-ioz.sh files
      # editing the basedir parameter when necessary
      # Default file loop goes here
      DEFFILES=(*ioz.sh)
      countfiles
      ## <2
      if [ ${numfiles} -gt 0 ]; then
         for (( i=0; i<${#DEFFILES[@]}; i++)); do
            DEFINDEX[$i]=$i
            arrayfile="${DEFFILES[i]}"
            echo "  >>> Filename is: ${arrayfile}"
            # Call quote basename here
            # Pass it a filename from the array
            quote_basename
            # If ${filetgtdir} and ${targetdir} are the same, there's nothing to do
            if [ "${filetgtdir}" != "${targetdir}" ]; then
               # Use ${basedir} to replace the string in the file
               newtgtdir=`sed -E "s:${filetgtdir}:${targetdir}:" "${arrayfile}"`
               echo "  <<< Rewriting file: ${arrayfile} with new ${targetdir} >>>"
               read -p "  <<< Press Enter to do it! >>>" a ; echo
               echo "    Replacing string ${filetgtdir} with ${targetdir}"
               echo
               #### rewriting the ioz scripts
               echo ${newtgtdir} > ${arrayfile}
            else
               nochange=Y
            fi
         done
         if [ "${nochange}" == "Y" ]; then
            echo
            echo "  Test directory values are the same" ; echo ; sleep 2
            echo
            read -p " >>> Press <Enter> to continue" z
         fi
      else
         echo " No ioz.sh files present" ; sleep 2
      fi
      ## >2

      clear
      # Run Directory
      echo "   Doing Throughput files now.. "
      echo
      cd ${savedrun}
      iamhere=`pwd`
      echo "      Current directory ${iamhere}"
      # Loop through the all the saved Auto-*-ioz.sh & Tput-*-ioz.sh files
      # editing the basedir parameter when necessary
      # There are up to 10 files
      # Run file loop goes here
      RUNFILES=(*ioz.sh)
      countfiles
      ## <3
      if [ ${numfiles} -gt 0 ]; then
         for (( i=0; i<${#RUNFILES[@]}; i++)); do
            RUNINDEX[$i]=$i
            # Call quote basename here
            #Pass it a filename from the array
            arrayfile="${RUNFILES[i]}"
            echo "  >>> Filename is: ${arrayfile}"
            quote_basename
            # If ${filetgtdir} and ${targetdir} are the same, there's nothing to do
            if [ "${filetgtdir}" != "${targetdir}" ]; then
               # Use ${basedir} to replace the string in the file
               newtgtdir=`sed -E "s:${filetgtdir}:${targetdir}:" "${arrayfile}"`
               echo "  <<< Rewriting file: ${arrayfile} with new ${targetdir} >>>"
               read -p "  <<< Press Enter to do it! >>>" a ; echo
               echo "  Replacing string ${filetgtdir} with ${targetdir}"
               echo
               #### rewriting the ioz scripts
               echo ${newtgtdir} > "${arrayfile}"
            else
               nochange=Y
            fi
         done
         if [ "${nochange}" == "Y" ]; then
            echo
            echo "  Test directory values are the same" ; echo ; sleep 2
            echo
            read -p " >>> Press <Enter> to continue" z
         fi
      else
         echo " No ioz.sh files present" ; sleep 2
      fi
      ## >3
   else
      # edit Individual files here.  Probably use the $runfile as the source
      echo "Editing file: $whatever"
   fi
   ## >1
   # Put the basedir value back to where it was for the targetdir string
   targetdir=$basedir/$testdir
}
########################################################################
# End of edit all the ${basedir} strings to contain the changed string #
########################################################################

##############################
# Start of display file list #
##############################
function display_filelist {

   # Because this is Load only we need to pick either the
   # Run or the Default directory to grab the ioztst file
   # So the first thing we see is a list of 2 directories
   # Thhe arrays for these two dirs can be populated manually
   #empty anything that may be left over
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=()

   OPTION_VALUES=("1" "2" "3")
   OPTION_LABELS=("Run Directory" "Default Directory" "Change basedir on all files")
   OPTION_STRING=()

   default_select=0 ; current= ; looping=0

   MESSAGE1=" Choose the directory. <<< Ver: ${version} >>>"
   MESSAGE2=" Default selection is [1]"
   MESSAGE3=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   MESSAGE4=" >> <Ctrl>C at any time to exit"

   # Call the function for select_single
   single_select

   if [ -z "${current}" ] ; then
      testtype=${default_select} ; current=${default_select} # Set to throughput by default if no choice is made
      testtype=${OPTION_VALUES[$current]}
      testlabel=${OPTION_LABELS[$current]}
   else
      testtype=${current}
      testlabel=${currstring}
   fi
   testmode=${testtype}

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      iamhere=`pwd`
      end=(${!OPTION_VALUES[@]})   # put all the indices in an array
      end=${end[@]: -1}    # get the last one
      echo " >>> Function display_filelist"
      echo " Last entry in array: |${end}|"
      echo "             Current: |${current}|"
      echo "           Test type: |${testtype}|"
      echo "          Test label: |${testlabel}|"
      echo "        Savedrun Dir: |${savedrun}|"
      echo "   Saveddefaults Dir: |${saveddefaults}|"
      echo "             Iamhere: |${iamhere}|"
      echo
      echo ; read -p "  Press <Enter> to continue" z
   fi

   ## At this point there are only two directories to enter
   ## This applies to Loading or Saving files
   if [ ${testtype} -eq 1 ]; then
      #echo " Changing to ${savedrun}"
      cd ${savedrun}
      iamhere=`pwd`
   elif [ ${testtype} -eq 2 ]; then
      #echo " Changing to ${saveddefaults}"
      cd ${saveddefaults}
      iamhere=`pwd`
   elif [ ${testtype} -eq 3 ]; then
      clear
      # Loop through the files in each storage directory (Run & Default)
      # make sure all -f|F strings are formatted with quotes
      echo "   looping through all *ioz.sh files"
      echo
      looping=1
      edit_basedir
      loopdone=Y
      looping=0
   fi

   ### Logic for Load file or save files
   if [ "${testdesc}" == "1" ] || [ "${testdesc}" == "2" ]; then
      echo "Dir: ${iamhere}"
      # Load one of two file types Throughput or Auto
   elif [ "${testdesc}" == "1 S" ] || [ "${testdesc}" == "2 S" ]; then
      # [1 S] (Save new Throughput test) - [2 S] (Save new Auto test)
      echo "Dir: ${iamhere}"
   elif [ "${testdesc}" == "1 D" ] || [ "${testdesc}" == "2 D" ]; then
      # [1 D] (Save Default Throughput test) - [2 D](Save Default Auto test)
      echo "Dir: ${iamhere}"
   elif [ "${testdesc}" == "L" ]; then
      echo "Dir: ${iamhere}"
      # Need a test here to see what the call was from so it can return
      if [ "${loopdone}" == "Y" ]; then
         # testtype=9
         # This SHOULD NOT BE HERE. I don't have a way to
         # return - go up a level from within a function
         # so in order to get somewhere useful call the
         # start_test function from within it's own loop
         start_test
      fi
      # Load one of two file types Throughput or Auto
      load_file_from_list
   fi
}
# testmode
############################
# End of display file list #
############################

###########################
# Start of load file list #
###########################
function load_file_from_list {
   # Load file list from saved files directories and process them
   # into a list than be made into an array to choose a file from

   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=()

   default_select=1 ; current=

   FILENAMES=(*ioz.sh)
   countfiles
   if [ ${numfiles} -gt 0 ]; then
      ## use this form of do loop to prevent problems with the date string
      for ((i=0; i<${#FILENAMES[@]}; i++)); do
         INDEX[$i]=$i
         ### Debug
         #echo "array loop $i" ; echo
         #echo "Array Index: ${INDEX[i]}"
         #echo " File Index: ${FILENAMES[i]}"
#        OPTION_VALUES[$i]="${INDEX[i]} "
#        OPTION_LABELS[$i]="${FILENAMES[i]} "
         OPTION_VALUES[$i]="${INDEX[i]}"
         OPTION_LABELS[$i]="${FILENAMES[i]}"
      done
### This is the place to allow an editor to be invoked after picking a file

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes      # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      iamhere=`pwd`
      end=(${!OPTION_VALUES[@]})   # put all the indices in an array
      end=${end[@]: -1}    # get the last one
      echo " Last entry in array: |${end}|"
      echo "             Current: |${current}|"
      echo "           Test type: |${testtype}|"
      echo "          Test label: |${testlabel}|"
### THD Change these
      echo "        Savedrun Dir: |${savedrun}|"
      echo "   Saveddefaults Dir: |${saveddefaults}|"
      echo "             Iamhere: |${iamhere}|"
      echo ; read -p "  Press <Enter> to continue" z
   fi

   else
      echo "Directory is empty"; sleep 2
   fi

   # Here we have to parse the index and filenames into strings
   # that can be assogned to the OPTION_VALUES and OPTION_LABELS
   # so they can be used in a file selection menu

   # awk and/or sed string manipulation goes here
   default_select=0; current=

   MESSAGE1=" Choose the file. <<< Ver: ${version} >>>"
   MESSAGE2=" Default selection is [0]"
   MESSAGE3=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   MESSAGE4=" >> <Ctrl>C at any time to exit"

   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      testtype=${default_select} ; current=${default_select} # Set to throughput by default if no choice is made
      testtype=${OPTION_VALUES[$current]}
      testlabel=${OPTION_LABELS[$current]}
   else
      testtype=${current}
      testlabel=${currstring}
   fi
   testmode=${testtype}
   arrayfile=${testlabel}
   # xargs strips the trailing space from the filenmae selected from the array
   #runfile=`echo "${testlabel}" | xargs`
   runfile=${testlabel}
   echo "   File to copy: [${runfile}] to:"
   echo "   Target:       [${targetdir}/ioz.sh]"



#-------------------------------- THD ----------------------------------------------------
# At this point call the function that changes the drive/array the test will be done on
# What do we do.
# quote_basename will produce a string containing the -f or -F option string with quotes
# around the ${basename} part of ${targetdir} so there is no chance of either an
# unquoted or a two times doublequoted basedir string the $basedir string is returned
# in it's doublequoted form in any case
# Two choices:
# 1) change the source file before it is copied to the target directory
# 2} leave the source file alone and change it on the way through.
# It's simple enough, tidy up the command line by removing any unnecessary spaces
# the entire command string can be held in a variable and echoed to either the original
# file which can then be copied, or echoed to the file on the $targetdir (drive/array)
# It's likely that I will insert a item in the second menu that will offer the user
# a chance to convert all the files at once, so here the $targetdir in the file should
# checked against the variable $targetdir.  If different,it should be automatically
# changed, the user doesen't even have to know it happened.
#-----------------------------------------------------------------------------------------

quote_basename

echo
read -p "   Press Enter to continue" a ; echo
#exit 1
#-----------------------------------------------------------------------------------------
   #runfile=${testlabel}
   #echo "   File to copy: [${runfile}] to:"
   #echo "   Target:       [${targetdir}/ioz.sh]"

   cp "${runfile}" "${targetdir}/ioz.sh"
   ### Debug
   #copyok=`ls ${targetdir}/ioz.sh` ; echo "   File copied? ${copyok}"
   ((testtype++)) # Increment the testtype variable to indiate Tput,1 orAutp, 2

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo
      if [ -z "${testtype}" ]; then
         echo "Error: You should not be here.  The default option was not used"
      else
         dir=`pwd`
         echo "Test option selected: [${testtype}], (${testlabel}).   \
               Test Type is [${TT}]   Test Descr is [${testdesc}]"
         echo "Test Type (TT): ${TT}    Option description: ${testlabel}   Number of files: ${numfiles}"
         echo "${dir}"
         echo "File to copy: [${runfile}] to Target: [${targetdir}/ioz.sh]"
         echo
         ## use this form of do loop to prevent problems with the dae string
         #for ((i=0; i<${#OPTION_LABELS[@]}; i++)); do
         #   echo "Array Index: ${OPTION_VALUES[i]} File Index: ${OPTION_LABELS[i]}"
         #done
      fi
      echo
      read -p " >>> Press <Enter> to continue" z
   fi
   cd "${targetdir}"
   runtest
}
# load_file_from_list
# testtype
#########################
# End of load file list #
#########################

####################################################################
# Start of save any of 4 test run filetypes to the appropriate dir #
####################################################################
function savetestrun {
   # Replaces all spaces with underscores
   datevar=`date | sed '{s/ /_/g}'`
   # If test type is 1 or 2 nothing is done - not saved
   # Save up to 5 of the Throughput and Auto test run files
   if [ "${testdesc}" == "1 S" ]; then     # 3 [1 S] (Save new Throughput test)
      # check for presence of dir
      if [ ! -d "${savedrun}" ] ; then
         mkdir "${savedrun}"
      fi
      mode=Tput
      cp "$targetdir/ioz.sh" "${savedrun}/${Tsaverunfile}"
      if [ -e "${savedrun}/${Tsaverunfile}" ]; then
         echo "       Saved:  $targetdir/ioz.sh"
         echo "          to:  ${savedrun}/${Tsaverunfile}"
      else
         echo " Save failed:  $targetdir/ioz.sh"
         echo "          to:  ${savedrun}/${Tsaverunfile}"
      fi

   elif [ "${testdesc}" == "2 S" ]; then   # 4 [2 S] (Save new Auto test)
      # check for presence of dir
      if [ ! -d "${savedrun}" ] ; then
         mkdir "${savedrun}"
      fi
      mode=Auto
      cp "$targetdir/ioz.sh" "${savedrun}/${Asaverunfile}"
      if [ -e "${savedrun}/${Asaverunfile}" ]; then
         echo "       Saved:  $targetdir/ioz.sh"
         echo "          to:  ${savedrun}/${Asaverunfile}"
      else
         echo " Save failed:  $targetdir/ioz.sh"
         echo "          to:  ${savedrun}/${Asaverunfile}"
      fi

   elif [ "${testdesc}" == "1 D" ]; then   # 5 [1 D] (Save Default Throughput test)
      # check for presence of dir
      if [ ! -d "${saveddefaults}" ] ; then
         mkdir "${saveddefaults}"
      fi
      mode=Tput
      cp "$targetdir/ioz.sh" "${saveddefaults}/${Tsavedefaultfile}"
      if [ -e "${saveddefaults}/${Tsavedefaultfile}" ]; then
         echo "       Saved:  $targetdir/ioz.sh"
         echo "          to:  ${saveddefaults}/${Tsavedefaultfile}"
      else
         echo " Save failed:  $targetdir/ioz.sh"
         echo "          to:  ${saveddefaults}/${Tsavedefaultfile}"
      fi

   elif [ "${testdesc}" == "2 D" ]; then   # 6 [2 D](Save Default Auto test)
      # check for presence of dir
      if [ ! -d "${saveddefaults}" ] ; then
         mkdir "${saveddefaults}"
      fi
      mode=Auto
      cp "$targetdir/ioz.sh" "${saveddefaults}/${Asavedefaultfile}"
      if [ -e "${saveddefaults}/${Asavedefaultfile}" ]; then
         echo "       Saved:  $targetdir/ioz.sh"
         echo "          to:  ${saveddefaults}/${Asavedefaultfile}"
      else
         echo " Save failed:  $targetdir/ioz.sh"
         echo "          to:  ${saveddefaults}/${Asavedefaultfile}"
      fi

   fi
# Save these for use in the next routine
# origtestmode=$testmode ; origtestlabel=$testlabel ; origTT=${TT} ; origtestdesc=${testdesc} ; origtesttype=${testtype}
testmode=$origtestmode ; testlabel=$origtestlabel ; testtype=$origtesttype

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo " >>> Function savetestrun"
      if [ "${testdesc}" == "1" ] || [ "${testdesc}" == "2"tmptest ]; then
         testtype="1 or 2"
         mode="ioz.sh file not saved"
      fi
      echo "       Type of test: <${testtype}>"
      echo "    Test Descriptor: <${testdesc}>"
      echo "          Test Mode: <${testmode}>"
      echo "          File mode: <${mode}>"
      echo "          Targetdir: <$targetdir>"
      echo "         Source fie: <$targetdir/ioz.sh>"
      echo "       Auto Runfile: ${Asaverunfile}"
      echo "       Tput Runfile: ${Tsaverunfile}"
      echo "      Absolute path: ${savedrun}/"
      echo "  Default Auto file: ${Asavedefaultfile}"
      echo "  Default Tput file: ${Tsavedefaultfile}"
      echo "      Absolute path: ${saveddefaults}/"

      read -p "  << Press enter >>" z
      echo
   fi
}
# savetestrun
# testdesc
##################################################################
# End of Save any of 4 test run filetypes to the appropriate dir #
##################################################################

####################################################################
# Start of save any of 4 test run filetypes to the appropriate dir #
####################################################################
function loadtestrun {
   # Check for load type, cd to the appropriate dir and load the file
   # cd to the base of the saved directory structure

   if [ ${testdesc} = "1 S" ]; then     # 3 [1 S] (Load Throughput test)
      if [ ! -d "${savedrun}" ] ; then
         echo " Directory Not present - save a file first" ; sleep 2
      else
         cd "${savedrun}"
         # Call routine to display saved files
      fi
   elif [ ${testdesc} = "2 S" ]; then   # 4 [2 S] (Load Auto test)
      if [ ! -d "${asavedrun}" ] ; then
         echo " Directory Not present - save a file first" ; sleep 2
      else
         cd "${savedrun}"
         # Call routine to display saved files
      fi
   elif [ ${testdesc} = "1 D" ]; then   # 5 [1 D] (Load Default Throughput test)
      if [ ! -d "${saveddefaults}" ] ; then
         echo " Directory Not present - save a file first" ; sleep 2
      else
         cd "${saveddefaults}"
         # Call routine to display saved files
      fi
   elif [ ${testdesc} = "2 D" ]; then   # 6 [2 D] (Load Default Auto test)
      if [ ! -d "${saveddefaults}" ] ; then
         echo " Directory Not present - save a file first" ; sleep 2
      else
         cd "${asaveddefaults}"
         # Call routine to display saved files
      fi
   fi
   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo " >>> Function loadtestrun"
      if [ "${testdesc}" == "1" ] || [ "${testdesc}" == "2"tmptest ]; then
         testtype="1 or 2"
         mode="ioz.sh file not saved"
      fi
      echo "       Type of test: <${testtype}>"
      echo "    Test Descriptor: <${testdesc}>"
      echo "          Test Mode: <${mode}>"
      echo "          Targetdir: <$targetdir>"
      echo "         Source fie: <$targetdir/ioz.sh>"
      echo "       Auto Runfile: ${Asaverunfile}"
      echo "       Tput Runfile: ${Tsaverunfile}"
      echo "      Absolute path: ${savedrun}/"
      echo "  Default Auto file: ${Asavedefaultfile}"
      echo "  Default Tput file: ${Tsavedefaultfile}"
      echo "      Absolute path: ${saveddefaults}/"

      read -p "  << Press enter >>" z
      echo
   fi
}
# loadtestrun
# testdescr
##################################################################
# End of Load any of 2 test run filetypes to the appropriate dir #
##################################################################

start_test

##################################################
# Start of multi select menu for -i test options #
##################################################
if [ ${testtype} -eq 1 ] || [ ${testtype} -eq 3 ] || [ ${testtype} -eq 5 ] ; then # Throughput mode
   testparm=test-i
   default_select="-i 0 -i 1" ; current=
   ### Be careful - make sure OPTION or OPTIONS ###
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   # Test is for individual tests
   OPTIONS_VALUES=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12")
   OPTIONS_LABELS=("write/rewrite" "read/re-read" "random-read/write" "read-backwards" "re-write-record" \
                   "stride-read" "fwrite/re-fwrite" "fread/re-fread" "random mix" "pwrite/re-pwrite" \
                   "pread/re-pread" "pwritev/re-pwritev" "preadv/re-preadv")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Specify which tests to run using the -i option."
   MESSAGE3=" Default selection is [0 and 1]"
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   # If this is intended to be a single selection menu item set select_one to 1 else 0
   #select_one=1 # Single selection menu item
   select_one=0 # Multiple selection menu item

   for i in "${!OPTIONS_VALUES[@]}"; do
      OPTIONS_STRING+="${OPTIONS_VALUES[$i]} (${OPTIONS_LABELS[$i]});"
   done
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   prompt_for_select SELECTED "$OPTIONS_STRING"

   for i in "${!SELECTED[@]}"; do
	   if [ "${SELECTED[$i]}" == "true" ]; then
		   CHECKED+=("${OPTIONS_VALUES[$i]}")
	   fi
   done
   # Process each selected option into a string like "-i 0 -i 1 -i 2" etc
   # use sed and create a new var named iopts
   # This sed command accumulates each entry as it should for multiselect
   iopts=`echo ${CHECKED[@]} | sed -E 's/\<([[:digit:]])/-i \1/g'`
   ### Debug
   #echo
   # echo "Test options selected: ${iopts}"
   if [ -z $iopts ]; then
      iopts=${default_select}
      echo "Test options default to: [${iopts}]"
   fi
   ### Debug
   #echo
   #read -p " >>> Press <Enter> to continue" z
fi
# iopts
################################################
# End of multi select menu for -i test options #
################################################

########################################################
# Start of single select menu for threads test options #
########################################################
if [ ${testtype} -lt 7 ] ; then # Throughput mode
   default_select=4 ; current=
   # This is for individual tests
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("1 threads" "2 threads" "4 threads" "8 threads" "16 threads" "32 threads")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}]"
   MESSAGE3=" Select the maximum number of threads to run (-t option, threads)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   ### Debugging
   #echo " Test type is: ${testspec}" ; sleep 2
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to reasonable default by default if no chouce is made
      currstring="${default_select} Threads"
   else
      threads=${current}
   fi

   threads=${current}

   FileNumbers

fi
# threads
######################################################
# End of single select menu for threads test options #
######################################################

##################################################################################
# Start of single select Minimum/Maximum File and record Size menu for auto mode #
##################################################################################
if [ ${testtype} -eq 2 ] || [ ${testtype} -eq 4 ] || [ ${testtype} -eq 6 ]; then # Auto mode
   testparm="test_g" # maximum file size for auto mode
   default_select=4 ; current=
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("GB" "GB" "GB" "GB"  "GB" "GB")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}] must be less than or equal to ${threads}"
   MESSAGE3=" Choose the Maximum file size for this test (-g option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to default if no choice is made
      currstring="${default_select}GB"
#   else
#      testtype=${current}
   fi
   # -g option for maximum file size creates the string -g xx
   fmaxtmp=${current}
   #echo "Maximum file size: ${fmaxtmp}" ; sleep 5
   fmaxsize=`echo ${current} | sed 's/\(^[0-9]*\)/-g \1g/'`
   #echo "Maximum file size: ${fmaxsize}" ; sleep 5
####
   testparm="test_n" # minimum file size for auto mode
   default_select=2 ; current=
   current=
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("GB" "GB" "GB" "GB"  "GB" "GB")
   MESSAGE1=" Test selected: $testmode  $testlabel must be less than or equal to ${fmaxtmp}"
   MESSAGE2=" Default selection is [${default_select}]"
   MESSAGE3=" Choose the Minimum file size for this test (-n option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"

   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to default if no choice is made
      currstring="${default_select}GB"
#   else
#      testtype=${current}
   fi
   # -n option for minimum file size creates the string -g xx
   #echo "Minimum file size: ${current}" ; sleep 5
   fmintmp=${current}
   fminsize=`echo ${current} | sed 's/\(^[0-9]*\)/-n \1g/'`
   #echo "Minimum file size: ${fminsize}" ; sleep 5
###
   testparm="test_q" # maximum record size for auto mode
   default_select=4 ; current=
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
#CHECKED1="" ; SELECTED1=""
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("KB" "KB" "KB" "KB"  "KB" "KB")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}]"
   MESSAGE3=" Choose the Maximum Record size for this test (-q option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"

   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to default if no choice is made
      currstring="${default_select}KB"
#   else
#      testtype=${current}
   fi
   #echo "Maximum record size (current): ${current}" ; sleep 5
   rmaxtmp=${current}
   # -q option for maximum record size
   rmaxsize=`echo ${current} | sed 's/\(^[0-9]*\)/-q \1k/'`
   #echo "Maximum record size: ${rmaxsize}" ; sleep 5
###
   testparm="test_y" # minimum record size for auto mode
   default_select=2 ; current=
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("KB" "KB" "KB" "KB"  "KB" "KB")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}] must be less than or equal to ${rmaxtmp}"
   MESSAGE3=" Choose the Minimum Record size for this test (-y option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"

   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to default if no choice is made
      currstring="${default_select}KB"
#   else
#      testtype=${current}
   fi
   rmintmp=${current}
   # -y option for minimum record size
   rminsize=`echo ${current} | sed 's/\(^[0-9]*\)/-y \1k/'`
   #echo "Minimum record size: ${rminsize}" ; sleep 5

   switchstring="${fminsize} ${fmaxsize} ${rminsize} ${rmaxsize}"
   #echo "iozone command string:  ${switchstring}" ; sleep 5
fi
# rmaxsize
# switchstring
################################################################################
# End of single select Minimum/Maximum File and record Size menu for auto mode #
################################################################################

#################################################################
# Start of single select menu for high thread limit test option #
#################################################################
if [ ${testtype} -lt 7 ] ; then # Throughput mode
   default_select=4 ; current=
   current=
   # This is for individual tests
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("1 upper limit procs" "2 upper limit procs" "4 upper limit procs" "8 upper limit procs" "16 upper limit procs" "32 upper limit procs")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}] must be less than or equal to ${threads}"
   MESSAGE3=" Select the upper thread limit (-u option, uplim)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo

   # Call the function for select_single
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to reasonable default if no chouce is made
      currstring="${default_select} Processes"
   else
      uplim=${current}
   fi
   echo
   uplim=${current}

fi
# uplim
###############################################################
# End of single select menu for high thread limit test option #
###############################################################

##################################################################
# Start of single select menu for lower thread limit test option #
##################################################################
if [ ${testtype} -lt 7 ] ; then # Throughput mode
   default_select=2 ; current=
   current=
   # This is for individual tests
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("1 lower limit procs" "2 lower limit procs" "4 lower limit procs" "8 lower limit procs" "16 lower limit procs" "32 lower limit procs")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is [${default_select}] must be less than or equal to ${uplim}"
   MESSAGE3=" Select the lower thread limit (-l option, lowlim)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   # Call the function for single_select
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to reasonable default by default if no chouce is made
      currstring="${default_select} Processes"
   else
      lowlim=${current}
   fi
   echo

   lowlim=${current}

fi
# lowlim
################################################################
# End of single select menu for lower thread limit test option #
################################################################

###########################################################
# Start of single select File Size(s) for throughput mode #
###########################################################
if [ ${testtype} -eq 1 ] || [ ${testtype} -eq 3 ] || [ ${testtype} -eq 5 ] ; then # Throughput mode
   default_select=8 ; current=
   # This is for individual tests
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32")
   OPTION_LABELS=("1GB" "2GB" "4GB" "8GB" "16GB" "32GB")
   MESSAGE1=" Test selected: $testmode  $testlabel (fsize)"
   MESSAGE2=" Default selection is [${default_select}]"
   MESSAGE3=" Select the (single) filesize for this test (-s option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo

   # Call the function for single_select
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to reasonable default by default if no chouce is made
      currstring="${default_select}GB"
   fi
   fsize=${current}
   echo

   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
   echo "                    Test selected: $testmode"
   echo "                        Testlabel: $testlabel (fsize)"
   echo "                Current selection: <${current}>"
   echo "                   Current String: <${currstring}>"
   echo "  List of filenames to be created: $filelist"
   echo "       Size of file for Auto test: ${fsize}"
   echo "         Default output should be: -s 8g"
   read -p "press enter" z
   fi
fi
# fsize
######################################################
# End of single select File Size for throughput mode #
######################################################

####################################################
# Start of single select Record Size for auto mode #
####################################################             ### THD ###  is this right?
if [ ${testtype} -eq 2 ] || [ ${testtype} -eq 4 ] || [ ${testtype} -eq 6 ] ; then # Auto mode
#if [ ${testtype} -lt 7  ]; then # Throughput mode or Auto mode
   # Save these for use in the next routine
   #origtestmode=$testmode ;  origtestlabel=$testlabel
   default_select=4 ; current=
   current=
   # This is for individual tests
   OPTION_VALUES=(); OPTION_LABELS=(); OPTION_STRING=() # empty array
   OPTION_VALUES=("1" "2" "4" "8" "16" "32" "64" "128" "256" "512")
   OPTION_LABELS=("1KB" "2KB" "4KB" "8KB" "16KB" "32KB" "64KB" "128KB" "256KB" "512KB")
#   if [ ${testtype} -eq 1  ] ; then # Throughput mode
#     MESSAGE1=" Test selected: $testmode  $testlabel (recsize)"
#   else # Auto mode
#     MESSAGE1=" Test selected: $testmode  $testlabel (recsize)"
#   fi
   MESSAGE1=" Test selected: $testmode  $testlabel (recsize)"
   MESSAGE2=" Default selection is [${default_select}]"
   MESSAGE3=" Select the record size for this test (-r option)."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   # Call the function for single_select
   single_select
   if [ -z "${current}" ] ; then
      current=${default_select} # Set to reasonable default by default if no choice is made
      currstring="${default_select}KB"
   fi
   recsize=${current}
   echo
   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo " >>> testtype"
      echo "                         Testtype: ${testtype}"
      echo "                    Test selected: $testmode"
      echo "                        Testlabel: $testlabel (fsize)"
      echo "                Current selection: <${current}> | <${currstring}>"
      echo "  List of filenames to be created: $filelist"
      echo "       Size of file for Auto test: ${recsize}"
      read -p "press enter" z
   fi
fi
# recsize
##################################################
# End of single select Record Size for auto mode #
##################################################

###################################################
# Start of Multi select menu to disable all sorts #
# of OS and fiesystem cache mechanisms            #
###################################################
if [ ${testtype} -lt 7 ]; then # Throughput mode or Auto mode
### setcache=1
### if [ ${setcache} -eq 1 ] ; then
   default_select= ; current=
   ### Be careful - make sure OPTION or OPTIONS ###

   OPTIONS_VALUES=(); OPTIONS_LABELS=(); OPTIONS_STRING=() # empty array
   OPTIONS_VALUES=("0" "1" "2" "3" "4")
   OPTIONS_LABELS=("-I bypass the buffer cache." \
                   "-o This forces all writes to the file to go completely to disk." \
                   "-+w 1 Percent of dedup-able data in buffers." \
                   "-+y 1 Percent of dedup-able within & across files in buffers." \
                   "-+C 1 Percent of dedup-able within & not across files in buffers.")
   MESSAGE1=" Test selected: $testmode  $testlabel"
   MESSAGE2=" Default selection is Nothing Selected: -I -o -+w 1 -+y 1 -+C 1 options"
   MESSAGE3=" Specify which cacheing options to disable."
   MESSAGE4=" <Up> <Dn> move, <Spacebar> select, <Enter> finish"
   # The variable testmode stuffs up the selection so save it an restore later
   origtestmode="${testmode}"
   testmode=
   # If this is intended to be a single selection menu item set select_one to 1 else 0
   #select_one=1 # Single selection menu item
   select_one=0 # Multiple selection menu item
   for i in "${!OPTIONS_VALUES[@]}"; do
      OPTIONS_STRING+="${OPTIONS_VALUES[$i]} (${OPTIONS_LABELS[$i]});"
   done
   clear
   echo
   echo "$MESSAGE1"
   echo "$MESSAGE2"
   echo "$MESSAGE3"
   echo "$MESSAGE4"
   echo
   prompt_for_select SELECTED "$OPTIONS_STRING"

   for i in "${!SELECTED[@]}"; do
	   if [ "${SELECTED[$i]}" == "true" ]; then
		   CHECKED+=("${OPTIONS_VALUES[$i]}")
	   fi
   done
   ### Process each selected option into a string like "-I -o -+w 1 -+y 1 -+C 1" etc
   ### Process each individual option without the sed line above
#CHECKED=`${CHECKED} | xargs`
clist=""
   for j in "${OPTIONS_VALUES[@]}"; do
       ### Debugging (Not a GOTO but it will have to do)
       skip=yes       # yes no or empty
       if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then

          echo "Number of selection: |${j}|"
          echo "           SELECTED: |${SELECTED[$j]}|"
          echo "            CHECKED: |${CHECKED[$j]}|"
          echo "     OPTIONS_VALUES: |${OPTIONS_VALUES[$j]}|"
          echo "     OPTIONS_LABELS: |${OPTIONS_LABELS[$j]}|"
       fi
       if [ "${j}" == "0" ] && [ "${SELECTED[$j]}" == "true" ]; then
		   clist="${clist} -I"
       elif [ "${j}" == "1" ] && [ "${SELECTED[$j]}" == "true" ]; then
           clist="${clist} -o"
       elif [ "${j}" == "2" ] && [ "${SELECTED[$j]}" == "true" ]; then
           clist="${clist} -+w 1"
       elif [ "${j}" == "3" ] && [ "${SELECTED[$j]}" == "true" ]; then
           clist="${clist} -+y 1"
       elif [ "${j}" == "4" ] && [ "${SELECTED[$j]}" == "true" ]; then
           clist="${clist} -+C 1"
	   fi
   done

   #Restore from earlier save
   testmode="${origtestmode}"
   ### Debugging (Not a GOTO but it will have to do)
   skip=yes       # yes no or empty
   if [ "${skip}" != "yes" ] || [ -z ${skip} ]; then
      echo "                >>> clist options: ${clist}"
      if [  -z "${clist}" ]; then
         echo "        No clist options selected"
      else
         echo "           Clist options selected: [${clist}]"
      fi
      echo "                         SELECTED: ${SELECTED[@]}"
      echo "                          CHECKED: ${CHECKED[@]}"
      echo "                   OPTIONS_VALUES: ${!OPTIONS_VALUES[@]}"
      echo "                   OPTIONS_LABELS: ${!OPTIONS_LABELS[@]}"
      echo "                     Loop counter: $j"
      echo "                         Testtype: $testtype"
      echo "                    Test selected: $testmode"
      echo "                        Testlabel: $testlabel (fsize)"
      echo "                Current selection: <${current}> | <${currstring}>"
      echo "  List of filenames to be created: $filelist"
      echo "       Size of file for Auto test: $recsizeGB"
      read -p " >>> Press <Enter> to continue" z
   fi
fi

# clist
#################################################
# End of Multi select menu to disable all sorts #
# of OS and fiesystem cache mechanisms          #
#################################################

############################################################
# Start of Check for and create all the needed directories #
############################################################

cd "$basedir"
#echo
#echo "Basedir: ${basedir}"
#echo
thisdir=`pwd`
### Debugging
#echo " Current Dir: ${thisdir}"
#echo " Test Dir: ${targetdir}"
#echo

# Where the test results are saved
if [ ! -d "${testdir}" ] ; then
    mkdir "${testdir}"
fi

# The directory where the tests are performed using iozone
if [ ! -d "${targetdir}" ] ; then
    mkdir "${targetdir}"
fi
# The base directory hierarchy for saved ioztst.sh starts here
if [ ! -d "${savedtestbasedir}" ] ; then
    mkdir "${savedtestbasedir}"
fi

# The didectory that throughput and auto ioztst.sh files are saved
if [ ! -d "${savedrun}" ] ; then
    mkdir "${savedrun}"
fi

# The directory where the Default throughput and Auto test files go
# There can be only one (of each type)
if [ ! -d "${saveddefaults}" ] ; then
    mkdir "${saveddefaults}"
fi

# If you are on a server and your user doesn't have a Documents Dir
# the saved files will be dropped in your home directory
if [ ! -d "${resultdir}" ] ; then
    result=$HOME/${resultfile}
    scrncap=$HOME/${scrncapfile}
    echo " >>> You have no ${resultdir} directory. the result and screen capture files will be placed in $HOME"
fi

##########################################################
# End of Check for and create all the needed directories #
##########################################################
cd "${targetdir}"
thisdir=`pwd`

### Debugging
#echo " Current Dir: ${thisdir}"
#echo " Test Dir: ${targetdir}"
#echo

#-----------------------------------------------------------------
### If any of the test runs involve a file save, a test here
### should save the file and fall through to the runtest procedure
#-----------------------------------------------------------------
# [MenuItem : TestDescr]
# 3 [1 S] (Throughput test)
# 4 [2 S] (Auto test)
# 5 [1 D] (Default Throughput test)
# 6 [2 D] (Default Auto test)

if [ "${testdesc}" == "1 S" ] || [ "${testdesc}" == "1 D" ]; then
   origtest=${testtype}
   testtype=1
   # [1 S] (New Throughput test) - [2 S] (New Auto test)

elif [ "${testdesc}" == "2 S" ] || [ "${testdesc}" == "2 D" ]; then
   origtest=${testtype}
   testtype=2
   # [1 D] (Default Throughput test) - [2 D](Default Auto test)

fi
   ##### Call procedure "runtest"
   runtest

echo " End of run - exit 0"
# This line is here to ensure a clean exit
exit 0

cd ${basedir}
if [ -d "${testdir}" ] ; then
  cd "${testdir}"
  #rm testfile ; cd ${basedir}
  #rmdir "${testdir}"
fi
echo
echo " End of Run - Beyond exit 0"

exit 1

# EOF

Have to find a way of backing out of functions to return to the next level up

.
