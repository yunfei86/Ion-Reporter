#!/bin/bash


usage()
{
cat << EOF
USAGE  : $0 options
OPTIONS:
   -h      Show this message
   -s      Mandatory. Servername or ip address
   -n      Optional. The n th latest build. Default 1
   -f      Optional. Turn on this flag leads to use "Freshly Install" mode instead of default "Upgrade" mode
   
EXAMPLE: ir16fetcher jagger 2 -f
EXAMPLE: ir16fetcher 167.116.6.155
REQUIRE: Please make sure there is a CORRECT and COMPLETE conf file on target server installation folder: ~/IRinstall/ir16 & ~/IRinstall/irmanager
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
IR16_LOC=/home/iruser/IRinstall/ir16
IRMANAGER_LOC=/home/iruser/IRinstall/irmanager

echo "################################################################"
echo "                Ion Reportor Build Fetcher "
echo "################################################################"

#check ip
ping -c1 -W1 $SERVER >$DOWNLOAD_LOG 2>&1 || { echo "Unreachable IP address. Please double check";exit; }

#searching for new build
echo "=> Start looking for latest build..."

url=http://167.116.6.182/builds/IonReporter16/TAR
if [ $COUNT -eq 1 ]; then
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporter16-v16 | sed 's/.*\>\(IonReporter16-v16-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r`
else
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporter16-v16 | sed 's/.*\>\(IonReporter16-v16-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r | head -$COUNT | tail -n1`
fi

for i in $builds
do
    IR_TARBALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "tar.gz" | sed 's/.*\>\(IonReporter16-.*-[0-9]*_[0-9]*.tar.gz\).*/\1/'` 
    IR_INSTALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "install.sh" | sed 's/.*\>\(install.sh\).*/\1/'`
    if [ -n "$IR_INSTALL" ] && [ -n "$IR_TARBALL" ] && [ `curl -L $url/$i 2>$DOWNLOAD_LOG | grep "<tr><td valign=\"top\">" | wc -l` -eq 3 ];then
        echo "*** Find ${COUNT}th latest IR build: $i"  
        break  
    fi
done

url=http://167.116.6.182/builds/IonReporterManager16/TAR
if [ $COUNT -eq 1 ]; then
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporterManager16-vIRManager16 | sed 's/.*\>\(IonReporterManager16-vIRManager16-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r`
else
    builds=`curl -L $url 2>$DOWNLOAD_LOG | grep IonReporterManager16-vIRManager16 | sed 's/.*\>\(IonReporterManager16-vIRManager16-r0_[0-9]*_[0-9]*\).*/\1/' | sort -r | head -$COUNT | tail -n1`
fi
for i in $builds
do
    IRMANAGER_TARBALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "tar.gz" | sed 's/.*\>\(IonReporterManager16-.*-[0-9]*_[0-9]*.tar.gz\).*/\1/'`
    IRMANAGER_INSTALL=$url/$i/`curl -L $url/$i 2>$DOWNLOAD_LOG | grep "install.sh" | sed 's/.*\>\(install.sh\).*/\1/'`
    if [ -n "$IRMANAGER_INSTALL" ] && [ -n "$IRMANAGER_TARBALL" ] && [ `curl -L $url/$i 2>$DOWNLOAD_LOG | grep "<tr><td valign=\"top\">" | wc -l` -eq 3 ];then
        echo "*** Find ${COUNT}th latest IRM build: $i"  
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

NUM=\`hadoop job -list | head -1 | cut -d\" \" -f1\`
if [ \$NUM -gt 0 ];then
    while true; do
      echo \" *** Checking for analysis running on server - \"\`hadoop job -list | head -1\`\" ---- \" 
	STDOUT=\`hadoop job -list\`
        #echo
        echo -e \" => WARNING: There are \$NUM analysis still running on server. Analysis currently on server:\n\$STDOUT\"
        #echo
        echo -n \" => Do you want to continue? [y/n]\"
        read -p \"[y/n]\" yn
        case \$yn in
            [Yy]* ) break;;
            [Nn]* ) exit 55;;
            * ) echo ' Please answer yes or no.';;
        esac
    done    
else
    echo \" *** Checking for analysis running on server - \"\`hadoop job -list | head -1\`\" ---- PASS\"
fi


echo
echo \" ########################\"
echo \"    Fetching build ...\"
echo \" ########################\"
#Log into target server and download build
IR16_LOC=$IR16_LOC
IRMANAGER_LOC=$IRMANAGER_LOC

mkdir -p \$IR16_LOC
cd \$IR16_LOC
rm -f install.sh IonReporter16_*.log IonReporter16-16.r0*tar.gz
wget -q $IR_INSTALL; chmod +x install.sh
wget -q $IR_TARBALL

mkdir -p \$IRMANAGER_LOC
cd \$IRMANAGER_LOC
rm -f install.sh IonReporterManager_*.log IonReporterManager16-IRManager16.r0*tar.gz;
wget -q $IRMANAGER_INSTALL; chmod +x install.sh
wget -q $IRMANAGER_TARBALL
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
echo " ir16 build     : $IR16_LOC"
echo " irmanager build: $IRMANAGER_LOC"
echo
echo
echo

#echo -e "\n######################   Install Ion Reporter ######################\n" >> $DOWNLOAD_LOG



echo "################################################################"
echo "                   Ion Reportor Installer "
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
export IR16_LOC=$IR16_LOC
export IRMANAGER_LOC=$IRMANAGER_LOC
export IONREPORTERMANAGERROOT=/share/apps/IR/ionreportermanager
export FRESH=$FRESH
"

read -d "" INSTALL_CMD << "BLOCK"

#echo $IR16_LOC
#echo $IRMANAGER_LOC

#check install.conf existance#
if [ ! -f $IRMANAGER_LOC/install.conf ];then
    echo "Oops, need install.conf file for irmanager installation"
    echo "Need: $IRMANAGER_LOC/install.conf"
    exit 55
else
    if [ -n "$FRESH" ]; then
        sed 's/lifescope.db.upgrade=upgrade/lifescope.db.upgrade=fresh/g' $IRMANAGER_LOC/install.conf > /tmp/install.conf
    else
        sed 's/lifescope.db.upgrade=fresh/lifescope.db.upgrade=upgrade/g' $IRMANAGER_LOC/install.conf > /tmp/install.conf
    fi
    /bin/cp /tmp/install.conf $IRMANAGER_LOC/install.conf 
fi

if [ ! -f $IR16_LOC/install.conf ];then
    echo "Oops, need install.conf file for ir installation"
    echo "Need: $IR16_LOC/install.conf"
    exit 55
else
    if [ -n "$FRESH" ]; then
        sed 's/lifescope.db.upgrade=upgrade/lifescope.db.upgrade=fresh/g' $IR16_LOC/install.conf > /tmp/install.conf
    else
        sed 's/lifescope.db.upgrade=fresh/lifescope.db.upgrade=upgrade/g' $IR16_LOC/install.conf > /tmp/install.conf
    fi
    /bin/cp /tmp/install.conf $IR16_LOC/install.conf 
fi

echo
echo "==> Start to install Ion Reporter Manager ... "
echo "Installation Stdout:"

#install manager#
cd $IRMANAGER_LOC

$IRMANAGER_LOC/install.sh -s

CMD=`cat $IRMANAGER_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess'`
if [ -n "$CMD" ];then
    echo "Oops, error found during Install IR mamager ... check LOG for details"
    exit 55
else
    echo "==> Successfully installed irmamager ..."
fi

echo
echo "==> Start to install Ion Reporter ... "
echo "Installation Stdout:"

#install ir#
cd $IR16_LOC

$IR16_LOC/install.sh -s

CMD=`cat $IR16_LOC/*log | grep -wi 'error\\|failed' | grep -v 'Tomcat\\|INSERT\\|dataaccess'`
if [ -n "$CMD" ];then
    echo "Oops, error found during Install IR ... check LOG for details"
    exit 55
else
    echo "Successfully installed ion reporter 1.6 ..."
fi


echo "post installation steps"
#post installation steps#
#//kill tomcat instance
kill -9 `ps x | grep tomcat | grep -v grep | awk {'print $1'}`
  
#//copy .war files over
rm -rf /share/apps/apache-tomcat/current/webapps/*
cp /share/apps/IR/ionreporter16/grws/grws_1_2.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/irms/irms.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/ui/irmgc.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter16/ui/ir16.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/ui/lifeApp.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreportermanager/ui/indexProcessor.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter16/igv/IgvServlet.war /share/apps/apache-tomcat/current/webapps
cp /share/apps/IR/ionreporter16/compendia-servlet/compendia-ir.war /share/apps/apache-tomcat/current/webapps
rm -rf /share/apps/apache-tomcat/current/logs/*
  
#//start tomcat
/etc/init.d/tomcat start

BLOCK


INSTALL_CMD="$PASS_ENVAR""$INSTALL_CMD"

#echo "$INSTALL_CMD"
echo "=> Start to install builds ... "
echo "ssh iruser@$SERVER ... "
echo "Please input your installation server password if needed"
ssh iruser@$SERVER "$INSTALL_CMD" 2> ${INSTALL_LOG} #2>&1

if [ $? == 55 ];then
    exit
fi


if [ $? != 0 ];then
    echo "Oops error found during installing latest build ... check $INSTALL_LOG for details"
    exit
fi


echo
echo
echo "=> Congratulation! Latest IR build has been installed successfully"

