# ioztst
Select the README.md and use the [Code] button above to get the 
formatting back.  Sorry I know virtually nothing about git as you'll
understand when you download and have to jump through hoops to extract
the files in their correct directories.
To download the actual package, hit the top left <>Code button and then
the bright Green Code button.  Select the zip file option and look in
your Downloads directory.

This is a bash script to help people unfamiliar with iozone to develop useful
disk/array performance data.

It is intended for people who are not familiar with the command line
and might even be long time linux users, but are mostly familiar with GUI
tools for their day to day workflow.

This was built for Linux Mint 21.x and 22. It should be simple enough
to install it on most other distros.  It requires a number of directories:
   $HOME/bin
   $HOME/Downloads
   $HOME/.config
   and of course your basedir directory (keep reading)
As long as you have these directories and know how to use your package
manager to install iozone (whatever version is available for your distro)
you shoild be golden.

Installing: In the downloads directory extract the Install.sh.tar.gz
            Copy the this file archive to your home directory and 
            unarchive it there.
            Next extract the ioztst-v0.90.6.tar.gz leave this file in
            the downloads directory.  do not extract anything from it.
            In the directory where you extracted the Install.sh file,
            ensure it is executable (chmod +x Install.sh)
            You should prepare to edit the config file to enter a
            directory that you will be using for your testing.  You will
            be given the opportunity to edit the config file while running
            the Install script. The modification you will need to make
            is termed the basedir and you will need to paste it into the
            config file where the entry looks something like this:
                  basedir=/mnt/$USER/devicerootdir
            Note that there is no '/' at the end of the directory name.
            There is already a sample entry you can overwrite:
                  # Basedir set to something innocuous
                  basedir=/EditThisString
            delete what follows the '=' and replace it with your directory
            path.
            Return to wherever you extracted the Install.sh script. You
            should have already made it executable, so run it by typing:
               ./Install.sh 
            ./ means it doesn't matter about what your $PATH is.  During the
            install you will be shown a page of text you must read, and at 
            the end of the page you will be offered the chance to edit the
            config file.  here are instructions at the bottom of the page
            about how to use the text editor, repeated here for you:
       Do you want to edit the config file now (y/n)  <Ctrl>C to exit"
       If you do, <Ctrl><O> <Enter> writes the file out, <Ctrl><X> exits the editor:
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
scripts, files and directories, look at the install script for the locations 
of everything you want to remove.

It's possible to run this script without installing iozone.  It will give you an
idea of the things it can do.  To run without calling iozone: ioztst.sh no
