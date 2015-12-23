Ion Reporter Auto Installer 1.7
=============================

1. prerequisites.
-------------

-  config file for ir16 and irmanager at folder "~/IRinstall"::

    /home/iruser/IRinstall/ir16/install.conf
    /home/iruser/IRinstall/irmananger/install.conf 


2. usage. 
-------------

-  command::

    USAGE  : /Users/liy15/bin/ir16installer.sh options
    OPTIONS:
       -h      Show this message
       -s      Mandatory. Servername or ip address
       -n      Optional. The n th latest build. Default 1
       -f      Optional. Turn on this flag leads to use "Freshly Install" mode instead of default "Upgrade" mode
   
    $EXAMPLE: ir16installer.sh -s jagger 2 -f
    $EXAMPLE: ir16installer.sh -s 167.116.6.155
    $REQUIRE: Please make sure there is a CORRECT and COMPLETE conf file on target server installation folder: ~/IRinstall/ir16 & ~/IRinstall/irmanager16


3. manual installation procedure         
-------------
-  JIRA page: https://iontorrent.jira.com/wiki/display/IR/IR1.6+Installation+manual+steps


