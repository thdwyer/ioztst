# ioztst
This is a bash script to help people unfamiliar with iozone to develop useful
disk/array performance data.

It is intended for people who are not familiar with the command line
and might even be long time linux users, but are mostly familiar with GUI
tools for their day to day workflow.

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
