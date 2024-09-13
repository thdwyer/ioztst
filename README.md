# ioztst
Select the README.md and use either the [Code] or the [Raw] button above
to get the formatting back.  Sorry I know virtually nothing about git as
you'll understand when you download and have to jump through hoops to extract
the files in their correct directories.

There is a new version of the install script that auto detects and
performs an update after asking the owner's permission.  If there 
is a previous install it will update the new config file with the
user supplied basedir parameter from the existing config file.

Included in the archive is a perl script that can be used to produce 
graphs when iozone is run in a specific mode: The full auto mode may be
selected from Option 8 at the main menu the perl script is named report.pl
and instructions (from the author) are included at the top of the file.
The file to use with this script is scrncap.txt which, at the moment
will be dropped in your Documents directory along with the xls file 
produced by iozone.  In order to this script to produce a set of graphs
the gnuplot package must be installed on your system. It should be
available, like iozone, for almost every linux distro
Until I get around to doing some further work on the Install script,
you'll have to work out how to use it.
Both the Install and ioztst files now have some command line switches
that can be used with -[x] -h for help.

For users with servers:  It's likely you won't have the usual home directory
structure thet desktop machines have.  The installation of ioztst is predicated
on a pattial desktop environment in your home directory - NOT root's home dir
you need four directories, Downloads Documents .config and bin all in the case 
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
   
As long as you have these directories and know how to use your package
manager to install iozone (whatever version is available for your distro)
you shoild be golden.

The following directories will be created;
   $HOME/tempiozextract  where the package files will be extracted to
   $HOME/.config/ioztst  Base directory for the config and iozone files
   $HOME/.config/ioztst/Default  / These two directories hold the
   $HOME/.config/ioztst/Run      \ definition files that run iozone
   $basedir/temptest     The filesystem you specify where the tests 
                         will be performed

Installing: In the downloads directory, extract the .sh file from the 
            Install.sh.tar.gz.  Copy the this file to your home or 
            $HOME/bin directory
            Leave the ioztst-v0.90.6.tar.gz in the downloads directory.
            Do not extract anything from it.
            In the directory where you extracted the Install.sh file,
            ensure it is executable (chmod +x Install.sh)
            You should prepare to edit the config file to enter a
            directory that you will be using for your testing.  You will
            be given the opportunity to edit the config file while running
            the Install script. The modification you will need to make
            is termed the basedir and you will need to paste it into the
            config file where the entry should look something like this:
                  basedir=/mnt/$USER/devicerootdir
            Note that there is no '/' at the end of the directory name.
            There is already a sample entry you can overwrite:
                  # Basedir set to something innocuous
                  basedir=/EditThisString
            delete what follows the '=' and replace it with your directory
            path.
            Return to wherever you extracted the Install.sh script. You
            should have already made it executable, so run it by typing:
               Install.sh 
            If you see: 'Install.sh: command not found', This means it isn't
            in your path  In the directory where the Install.sh is located type:
               ./Install.sh 
            ./ will force the script to run whatever your $PATH is.  During
            the install you will be shown a page of text you must read, and
            at the end of the page you will be offered the chance to edit 
            the config file.  here are instructions at the bottom of the page
            about how to use the text editor, repeated here for you:
                                 ---======---
       Do you want to edit the config file now (y/n)  <Ctrl>C to exit"
       If you do, <Ctrl><O> <Enter> writes the file out, <Ctrl><X> exits the editor:
                                  ---======---      
            Begin the edit by typing 'y' and press <Enter>.  Look for the
            word [/EditThisString] and replace it by pasting your selected
            directory in it's place.  The line is not commented, so once you
            have pasted the new value into the file save it <Ctrl><O> & <Enter>
            then exit the editor <Ctrl><X>.  The script will finish and the
            ioztst.sh script will be in your $HOME/bin directory.
            The next thing to do is install the iozone package:
                sudo apt install iozone3
            After this is done you can run the ioztst.sh and start testing
            To run it without installing or using iozone to run the tests
                ioztst.sh no
            This will prevent iozone from actually being run although you can
            still step through the menus and see what script files are produced
            in your $basedir/tmptest directory and for the saved files in 
            /home/tdwyer/.config/ioztst/[Default|Run]

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

Please note that none of these bash scripts delete files or directories, only 
copy, move or create them, so there should be little or no danger to your system.
There is no uninstall script for the same reason.  If you want to uninstall the
scripts, files and directories, look at the install script or use this document
for the locations of everything you want to remove.

It's possible to run this script without installing iozone.  It will give you an
idea of the things it can do.  To run without calling iozone: ioztst.sh no
