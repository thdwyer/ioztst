# ioztst

Select the README.md and use either the [Code] or the [Raw] button above
to get the formatting back.  Sorry I know virtually nothing about git as
you'll understand when you download and have to jump through hoops to extract
the files in their correct directories.

Important: Do NOT install and run these scripts with sudo or if you are
logged in as root.  The scripts are intended to be run as a normal user
you should not even be required to be in the adm (administrator) group
except to install iozone and gnuplot.

The current version of the install script auto detects and performs an 
update after asking the owner's permission.  If there is a previous 
install it will update the new config file with the user supplied basedir 
parameter from the existing config file.  There is also an uninstall script
see the warnings about it's use near the end of this document.

Included in the archive is a perl script that can be used to produce 
graphs when iozone is run in a specific mode: The full auto mode may be
selected from Option 8 at the main menu.  The perl script is named report.pl
and instructions (from the author) are included at the top of the file.
In can now handle iozone output files for four separate plots.
Why four?  anyone with more than 4 machines to tweak performance on will
be able to add as many instances as they like 8)  
The files to use with this script are labelled:
   [hostname]-[date-time]-scrncap[ |1|2].txt 
and will be dropped in your $HOME/Documents/Iozone_Auto_Plots directory along with
the [hostname]-[date-time]-result[ |1|2].xls file and [hostname]-[date-time]-scale[ |1|2].xls
produced by iozone.  In order to use this script to produce a set of graphs
Naming for the results files: [ |1|2] indicates 
                      [nothing|digit1|digit2]
the 'nothing' is for files produced by anything BUT the Full Auto, Option [8]
test.  the 1 is for the iozone run that does the first half of the Full Auto Option [8]
test.  The 2 is for the second run producing results for the last part of the
Full Auto test.
In order to produce graphs using the files tou'll need to install gnuplot.
The gnuplot package should be available, like iozone, for almost every linux 
distro.

Both the Install and ioztst files now have some command line switches
that can be used with -h for help.

For users with servers:  It's likely you won't have the usual home directory
structure thet desktop machines have.  The installation of ioztst is predicated
on a partial desktop environment in your home directory - NOT root's home dir
you need four directories, Downloads, Documents, .config and bin all in the case 
shown here If these are not present the script and it's dependent dirs and files
will fail and not be installed.  The Install.sh script will create all these 
directories if they are not present.  The ioztst-vx.xx.x.tar.gz should be left
in the Downloads directory.  A separate directory will be created to extract
and keep a copy of the current archived files.  This is necessary for any
downloads of later versions that will attempt to do an auto upgrade.
see the user guide in the Documents directory (after installation) for 
instructions on how to include your /user/[$USER}/bin directory in your path. 

The best way to download the parts of the repository you need is to select
the two tar.gz files one at a time anywhere you see the list of files 
available. In the right hand panel near the top there are a number of icons,
Look for the one that looks like a tray with a down arrow pointing into
it.  Click on this icon to download that file.  After you've downloaded both
tar.gz files you have all you'll need to do the install.  See below for
instructions.

This is a bash script to help people unfamiliar with iozone to develop useful
disk/array performance data.

It is intended for people who are not familiar with the command line
and might even be long time linux users, but are mostly familiar with GUI
tools for their day to day workflow.

Please do not install or run these scripts using sudo. They are not
intended to be installed or run as root.

This was built for Linux Mint 21.x and 22. It should be simple enough
to install it on most other distros.  It requires a number of directories:
   $HOME/bin          This will be created if you don't have it
   $HOME/Downloads    You this directory should already be present.
   $HOME/Documents    This is the preferred location for iozone's output files
   $HOME/.config
   and of course your basedir directory (keep reading)

If these required directories are not already there the install script will 
create them
As long as you have these directories and know how to use your package
manager to install iozone and gnuplot (whatever versions are available 
for your distro) and gnuplot you should be golden.

The following directories will be created;
   $HOME/tempiozextract  where the package files will be extracted to
   $HOME/.config/ioztst  Base directory for the config and iozone files
   $HOME/Documents/Iozone_Auto_Plots  report.xls and scrncap.txt files go here
   $HOME/.config/ioztst/Default  / These two directories hold the
   $HOME/.config/ioztst/Run      \ definition files that run iozone
   $basedir/temptest     The filesystem you specify where the tests 
                         will be performed

Installing: In the downloads directory, extract the .sh file from the 
            Install.sh.tar.gz.  Copy this file to your $HOME/bin directory
            Leave the ioztst-vx.xx.x.tar.gz in the downloads directory.
            Do not extract anything from it.
            In the directory where you copied the Install.sh file to,
            ensure it is executable (chmod +x Install.sh)
            You should prepare to edit the config file to enter a
            directory that you will be using for your testing.  You will
            be given the opportunity to edit the config file while running
            the Install script.
                                ---======--- 
            Configuring for your test directory:
            You don't do this until you run the Install.sh script.  It will
            ask you if you want to edit the config file during th installation.
            This is the most difficult thing you will need to do while installing.
                                 ---======---
            There a number of examples in the iozconf file.
            The modification you will need to make is termed the 'basedir' 
            and you will need to paste or type it into the config file where
            the entry should look something like this:
                  basedir=/media/$USER/usbarray
            In case you are unfamiliar with how to do this, use your file 
            manager and navigate to the directory you want to use for testing.
            In nemo, the directory name is in the address bar near the top of 
            the window.  If you use a different file manager, I'm sure it will
            have something similar.  Just copy and paste from the address bar 
            into the line on the config file.
            when editing in nano:
            USE THE ARROW KEYS TO MOVE THE CURSOR TO THE POINT YOU WANT TO PASTE
            or you will quite likely paste into a section of the file you
            don't want to, so be careful.
            Note that THERE IS NO '/' at the end of the directory name.
            There is already a sample entry you can overwrite:
                  # Basedir set to something innocuous
                  basedir=EditThisString
            delete what follows the '=' and replace it with your directory
            path.  Paste from your file manager's adderss bar.
                                 ---======---
            In the directory you extracted the Install.sh script that you
            should have already made executable.  Execute it by typing:
               Install.sh 
            If you see: 'Install.sh: command not found', This means it isn't
            in your path  In the directory where the Install.sh is located type:
               ./Install.sh 
            ./ will force the script to run no matter what your $PATH is.  During
            the install you will be shown a page of text you must read, and
            at the end of the page you will be offered the chance to edit 
            the config file (see above).  There are instructions at the bottom 
            of the page about how to use the text editor, repeated here for you:
                                 ---======---
       Do you want to edit the config file now  <Ctrl>C to exit"
       If yes, <Ctrl><O> <Enter> writes the file out, <Ctrl><X> (y/n) exits the editor:
                                 ---======---      
            Begin the edit by typing 'y' and press <Enter>.  Look for the
            word [EditThisString] and replace it by pasting your selected
            directory in it's place.  The line is not commented, so once you
            have pasted the new value into the file save it <Ctrl><O> & <Enter>
            then exit the editor <Ctrl><X>.  The script will finish and the
            ioztst.sh script will be in your $HOME/bin directory.
            The next thing to do is install the iozone package:
                sudo apt install iozone3
            After this is done you can run the ioztst.sh and start testing
            To run it without installing or using iozone to run the tests
                ioztst.sh -n
            This will prevent iozone from actually being run although you can
            still step through the menus and see what script files are produced
            in your $basedir/tmptest directory and for the saved files in 
            /home/$USER/.config/ioztst/[Default|Run]

Hopefully this will introduce people who want to see how their disk system performs
via an easy introduction to a complex tool designed for high level sysadmins for
benchmarking a filesystem. This provides a new user with a way that
should limit the mistakes in command line configuration that might provide
only confusing error messages that are not very helpful.  An additional major
benefit is that you won't have to download and spend ages trying to understand
what switches and options go together and are mutually exclusive.
That will all come later. 8)  This script will enable you to run performance
tests on any storage device you have access to, and as you become familiar
with iozone you can experiment with any of the multitude of options iozone
offers.

Other GUI disk performance tools I found only used devices, not filesystems.
This is important for anyone with a disk array.
Iozone allows tests on a filesystem inside a directory, and that is the reason
I started to develop the script.  It grew way beyond my original intent before
I knew it.  I intend to provide the ability to use some of the functions iozone
provides for the more complex requirements of larger arrays used for example in
home media servers.

Please note that neither the Install.sh or ioztst.sh bash scripts delete files or
directories, only copy, move or create them, so there should be little or no danger
to your system.  There is now an uninstall script for the package.  If you want to
uninstall the scripts, files and directories, look at the iozcln.sh script.
I've done extensive testing and improvement on this script, and I'm confident
that there will be no problems with the ininstall as long as no after install
fiddling has been done with the config file or the directory and file names and
locations.  If you absolutely must change any of the above, the only change should
be a different $basedir and that can be done quite safely.  All that must be done
after the change is a quick throughput test to ensure it points to the right place
Please pay attention to the instructions on the screen when you run the iozcln.sh
script It uses paths as absolute as I could make them. for most of the individual
delete options you have to agree to the only variable used is the $HOME directory
because not being a mind reader I have no idea what the absolute path to the files
and directories will be.
There is one exception to the variables rule, and that is the $basedir which could
point anywhere including to a mount point for a filesystem on another machine.
So in order to eliminate (or at least minimise) the potential for problems,
during the deletion of the tmptest directory, the script attempts to cd to
$basedir and do an 'ls -Ad tmptest'. If the directory exists, it must be in the
right place and the directory can be deleted.

It's possible to run ioztst script without installing iozone.  It will give you an
idea of the things it can do.  To run without calling iozone: ioztst.sh -n
