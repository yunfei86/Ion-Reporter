#!/bin/bash

set -e

usage()
{
cat << EOF
USAGE  : $0 options
OPTIONS:
   -h      Show this message
   -s      Mandatory. Servername or ip address
   -n      Optional. The n th latest build. Default 1
   -f      Optional. Turn on this flag leads to use "Freshly Install" mode instead of default "Upgrade" mode
   
EXAMPLE: ir40installer.sh think1 -n 2 -f
EXAMPLE: ir40installer.sh 167.116.6.218
REQUIRE: Please make sure there is a CORRECT and COMPLETE conf file on target server installation folder: ~/IRinstall/ir40 & ~/IRinstall/irmanager40
EOF
}

SERVER=
COUNT=1
FRESH=
while getopts "h:s:n:f" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
             SERVER=$OPTARG
             ;;
         n)
             COUNT=$OPTARG
             ;;
         f)
             FRESH=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z $SERVER ]
then
     usage
     exit 1
fi

DOWNLOAD_LOG=/tmp/irfetcher_download.log
INSTALL_LOG=/tmp/irfetcher_install.log
IR40_LOC=/home/iruser/IRinstall/ir40
IRMANAGER40_LOC=/home/iruser/IRinstall/irmanager40
echo "# version - v4"
echo "################################################################"
echo "              Ion Reportor 4.0 Build Fetcher "
echo "################################################################"

#check ip
ping -c1 -W1 $SERVER >$DOWNLOAD_LOG 2>&1 || { echo "Unreachable IP address. Please double check";exit; }

#searching for new build
echo "=> Start looking for latest build..."

url=http://167.116.6.115/builds/IonReporter40/TAR
if [ $COUNT -eq 1 ]; then
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporter40-v40 | sed 's/.*\(IonReporter40-v40-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r`
else
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporter40-v40 | sed 's/.*\(IonReporter40-v40-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r | head -$COUNT | tail -n1`
fi

for i in $builds
do
    IR_TARBALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "tar.gz" | sed 's/.*\(IonReporter40-.*-[0-9]*_[0-9]*.tar.gz\).*/\1/'` 
    IR_INSTALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "install.sh" | sed 's/.*\(install.sh\).*/\1/'`
    if [ -n "$IR_INSTALL" ] && [ -n "$IR_TARBALL" ] && [ `curl -L $url/$i 2>$DOWNLOAD_LOG | grep "<tr><td valign=\"top\">" | wc -l` -eq 3 ];then
        echo "*** Find ${COUNT}th latest IR build: $i"  
        break  
    fi
done

url=http://167.116.6.115/builds/IonReporterManager40/TAR
if [ $COUNT -eq 1 ]; then
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporterManager40-vIRManager40 | sed 's/.*\(IonReporterManager40-vIRManager40-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r`
else
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporterManager40-vIRManager40 | sed 's/.*\(IonReporterManager40-vIRManager40-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r | head -$COUNT | tail -n1`
fi
for j in $builds
do
    IRMANAGER_TARBALL=$url/$j/`curl -L $url/$j 2>$DOWNLOAD_LOG | grep "tar.gz" | sed 's/.*\(IonReporterManager40-.*-[0-9]*_[0-9]*.tar.gz\).*/\1/'`
    IRMANAGER_INSTALL=$url/$j/`curl -L $url/$j 2>$DOWNLOAD_LOG | grep "install.sh" | sed 's/.*\(install.sh\).*/\1/'`
    if [ -n "$IRMANAGER_INSTALL" ] && [ -n "$IRMANAGER_TARBALL" ] && [ `curl -L $url/$j 2>$DOWNLOAD_LOG | grep "<tr><td valign=\"top\">" | wc -l` -eq 3 ];then
        echo "*** Find ${COUNT}th latest IRM build: $j"  
        break  
    fi
done




#echo IRMANAGER_INSTALL=$IRMANAGER_INSTALL
#echo IRMANAGER_TARBALL=$IRMANAGER_TARBALL
#echo IR_INSTALL=$IR_INSTALL
#echo IR_TARBALL=$IR_TARBALL

GET_BUILD="#double check machine
     
echo
echo \" ########################\"
echo \"  Sanity Check on Server\"
echo \" ########################\"

if [ \${HOSTNAME%%.*} != \"$SERVER\" ]; then
    while true; do
        echo -n \" *** Checking for ServerName. Is this correct server? *** \${HOSTNAME%%.*} *** [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
else
    echo \" *** Checking for server IP ----- PASS\"
fi

echo

NUM=\`ps -ef | grep tomcat | grep -v grep | wc -l\`
if [ \$NUM -gt 1 ] || [ \$NUM -eq 0 ]; then
    while true; do
        echo \" *** Checking for Tomcat ----- \"
	STDOUT=\`ps -ef | grep tomcat | grep -v grep\`
        #echo
        echo -e \" ----> WARNING: Tomcat seems not working properly\n => Tomcat related proccess currently on server\n\$STDOUT\"
        #echo
        echo -n \" => Is Tomcat works fine? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo \" *** Checking for Tomcat ----- PASS\"
fi

echo

NUM=\`ps -ef | grep mysql | grep -v grep | wc -l\`
if [ \$NUM -gt 2 ] || [ \$NUM -eq 0 ]; then
    while true; do
        echo \" *** Checking for MySQL -----\"    
	STDOUT=\`ps -ef | grep mysql | grep -v grep\`
        #echo
        echo -e \" ----> WARNING: MySQL seems not working properly\n => MySQL related proccess currently on server\n\$STDOUT\"
        #echo
        echo -n \" => Is MySQL works fine? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo \" *** Checking for MySQL ----- PASS\"
fi

echo

NUM=\`ps -ef | grep mongo | grep -v grep | wc -l\`
if [ \$NUM -gt 2 ] || [ \$NUM -eq 0 ]; then
    while true; do
        echo \" *** Checking for MongoDB ----- \"
	STDOUT=\`ps -ef | grep mongo | grep -v grep\`
        #echo
        echo -e \" =>  WARNING: MongoDB seems not working properly. MongoDB related proccess currently on server:\n\$STDOUT\"
        #echo
        echo -n \" => Is mongodb works fine? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo \" *** Checking for MongoDB ----- PASS\"
fi

echo

##########################
###### job checker #######
##########################


echo \" ########################\"
echo \"    Fetching build ...\"
echo \" ########################\"
#Log into target server and download build
IR40_LOC=$IR40_LOC
IRMANAGER40_LOC=$IRMANAGER40_LOC

IR_TAR_L=\`echo $IR_TARBALL | xargs -n1 basename\`
IRMANAGER_TAR_L=\`echo $IRMANAGER_TARBALL | xargs -n1 basename\`
IR_TAR_C=\`ls -1 \$IR40_LOC/*gz | xargs -n1 basename\`
IRMANAGER_TAR_C=\`ls -1 \$IRMANAGER40_LOC/*gz | xargs -n1 basename\`

#echo \"LAT \"\$IR_TAR_L
#echo \"LAT \"\$IRMANAGER_TAR_L
#echo \"CUR \"\$IR_TAR_C
#echo \"CUR \"\$IRMANAGER_TAR_C

echo \" => Downloading IR40\"
if [ \"\$IR_TAR_L\" == \"\$IR_TAR_C\" ];
then
    while true; do
        echo -n \" *** Already latest IR40 build. Download anyway? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* )     mkdir -p \$IR40_LOC;
                        cd \$IR40_LOC;
                        rm -f install.sh IonReporter40_*.log IonReporter40-40.r0*tar.gz;
                        wget -q $IR_INSTALL; chmod +x install.sh;
                        wget -q $IR_TARBALL;
                        break;;
            [Nn]* ) echo ' Continue...';break;;
            * ) echo ' Please answer yes or no.';;
        esac
    done   
else
    mkdir -p \$IR40_LOC;
    cd \$IR40_LOC;
    rm -f install.sh IonReporter40_*.log IonReporter40-40.r0*tar.gz;
    wget -q $IR_INSTALL; chmod +x install.sh;
    wget -q $IR_TARBALL;
fi

echo \" => Downloading IRMANAGER40\"
if [ \"\$IRMANAGER_TAR_L\" == \"\$IRMANAGER_TAR_C\" ];
then
    while true; do
        echo -n \" *** Already latest irmanager build. Download anyway? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* )         mkdir -p \$IRMANAGER40_LOC;
                            cd \$IRMANAGER40_LOC;
                            rm -f install.sh IonReporterManager_*.log IonReporterManager40-IRManager40.r0*tar.gz;
                            wget -q $IRMANAGER_INSTALL; chmod +x install.sh;
                            wget -q $IRMANAGER_TARBALL;
                            break;;
            [Nn]* ) echo ' Continue...';break;;
            * ) echo ' Please answer yes or no.';;
        esac
    done
else
    mkdir -p \$IRMANAGER40_LOC;
    cd \$IRMANAGER40_LOC;
    rm -f install.sh IonReporterManager_*.log IonReporterManager40-IRManager40.r0*tar.gz;
    wget -q $IRMANAGER_INSTALL; chmod +x install.sh;
    wget -q $IRMANAGER_TARBALL;
fi
"   

echo "=> Start downloading lateset build ... "
echo " login to intallation server ... "
echo " Please input your installation server password if needed"
#echo "$GET_BUILD"
ssh iruser@$SERVER "$GET_BUILD" 2> $DOWNLOAD_LOG #2>&1

if [ $? == 55 ];then
    exit
fi

if [ $? != 0 ];then
    echo "Oops error found during downloading latest build ... check $DOWNLOAD_LOG for details"
    exit
fi

echo " => Complete: Latest IR build has been fetched"
echo " server         : $SERVER"
echo " IR40 build     : $IR40_LOC"
echo " irmanager build: $IRMANAGER40_LOC"
echo
echo
echo
echo
#echo -e "\n######################   Install Ion Reporter 4.0 ######################\n" >> $DOWNLOAD_LOG



echo "################################################################"
echo "                 Ion Reportor 4.0 Installer "
echo "################################################################"

if [ -n "$FRESH" ]; then
    echo "*** You chose: ===> Fresh Installation <===="
else
    echo "*** You chose: ===> Upgrade Installation <===="
fi

while true; do
    read -p "Do you wish to continue install Ion Reporter on server [y/n]?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


PASS_ENVAR="
export IR40_LOC=$IR40_LOC
export IRMANAGER40_LOC=$IRMANAGER40_LOC
export IONREPORTERMANAGERROOT=/share/apps/IR/ionreportermanager
export FRESH=$FRESH
"

read -d "" INSTALL_CMD << "BLOCK"

#echo $IR40_LOC
#echo $IRMANAGER40_LOC

#check install.conf existance#
if [ ! -f $IRMANAGER40_LOC/install.conf ];then
    echo "Oops, need install.conf file for irmanager installation"
    echo "Need: $IRMANAGER40_LOC/install.conf"
    exit 55
else
    if [ -n "$FRESH" ]; then
        sed 's/lifescope.db.upgrade=upgrade/lifescope.db.upgrade=fresh/g' $IRMANAGER40_LOC/install.conf > /tmp/install.conf
    else
        sed 's/lifescope.db.upgrade=fresh/lifescope.db.upgrade=upgrade/g' $IRMANAGER40_LOC/install.conf > /tmp/install.conf
    fi
    /bin/cp /tmp/install.conf $IRMANAGER40_LOC/install.conf 
fi

if [ ! -f $IR40_LOC/install.conf ];then
    echo "Oops, need install.conf file for ir installation"
    echo "Need: $IR40_LOC/install.conf"
    exit 55
else
    if [ -n "$FRESH" ]; then
        sed 's/lifescope.db.upgrade=upgrade/lifescope.db.upgrade=fresh/g' $IR40_LOC/install.conf > /tmp/install.conf
    else
        sed 's/lifescope.db.upgrade=fresh/lifescope.db.upgrade=upgrade/g' $IR40_LOC/install.conf > /tmp/install.conf
    fi
    /bin/cp /tmp/install.conf $IR40_LOC/install.conf 
fi

echo
echo "==> Start to install Ion Reporter Manager ... "
echo "Installation Stdout:"

#install manager#
cd $IRMANAGER40_LOC

$IRMANAGER40_LOC/install.sh -s
echo \`ls\`

#check error
if [ 1 -eq 2 ];then
CMD=`cat $IRMANAGER40_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess\\|\)\,'`
if [ -n "$CMD" ];then
    echo "Oops, error found during Install IR mamager ... check LOG for details"
    exit 55
else
    echo "==> Successfully installed irmamager ..."
fi
fi
CMD=`cat $IRMANAGER40_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess\\|\)\,'`
if [ -n "$CMD" ];then
    while true; do
        echo -e "ERROR:\n$CMD"
        echo -n " => Is installation good? [y/n]"
        read -p "[y/n]" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo "==> Successfully installed irmamager ..."
fi



echo
echo "==> Start to install Ion Reporter ... "
echo "Installation Stdout:"

#install ir#
cd $IR40_LOC

$IR40_LOC/install.sh -s
echo \`ls\`


#check error
if [ 1 -eq 2 ];then
CMD=`cat $IR40_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess'`
if [ -n "$CMD" ];then
    echo "Oops, error found during Install IR ... check LOG for details"
    exit 55
else
    echo "Successfully installed ion reporter 1.6 ..."
fi
fi
CMD=`cat $IR40_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess'`
if [ -n "$CMD" ];then
    while true; do
        echo -e "ERROR:\n$CMD"
        echo -n " => Is installation good? [y/n]"
        read -p "[y/n]" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo "==> Successfully installed ion reporter 4.0 ..."
fi




echo "post installation steps"
#post installation steps#
#//kill tomcat instance
kill -9 `ps x | grep tomcat | grep -v grep | awk {'print $1'}`
  
#//Copy war files
rm -rf /share/apps/apache-tomcat/current/webapps/ir
rm -rf /share/apps/apache-tomcat/current/webapps/lifeApp
rm -rf /share/apps/apache-tomcat/current/webapps/irms
rm -rf /share/apps/apache-tomcat/current/webapps/indexProcessor
rm -rf /share/apps/apache-tomcat/current/webapps/webservices_40
rm -rf /share/apps/apache-tomcat/current/webapps/webservices_mgc
rm -rf /share/apps/apache-tomcat/current/webapps/grws_1_2
rm -rf /share/apps/apache-tomcat/current/webapps/*war

#From IonReporterManager:
cp /share/apps/IR/ionreportermanager/irms/irms.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/ui/lifeApp.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/ui/indexProcessor.war /share/apps/apache-tomcat/current/webapps
#From IonReporter:
cp /share/apps/IR/ionreporter40/lib/java/shared/webservices_mgc/webservices_mgc.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter40/lib/java/shared/webservices_40/webservices_40.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter40/ui/ir.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter40/grws/grws_1_2.war /share/apps/apache-tomcat/current/webapps
  
#//start tomcat
/etc/init.d/tomcat start

BLOCK


INSTALL_CMD="$PASS_ENVAR""$INSTALL_CMD"

#echo "$INSTALL_CMD"
echo "=> Start to install builds ... "
echo "ssh iruser@$SERVER ... "
echo "Please input your installation server password if needed"
ssh iruser@$SERVER "$INSTALL_CMD" 2>${INSTALL_LOG} #2>&1

if [ $? == 55 ];then
    exit
fi


if [ $? != 0 ];then
    echo "Oops error found during installing latest build ... check ${INSTALL_LOG} for details"
    exit
fi


echo
echo

