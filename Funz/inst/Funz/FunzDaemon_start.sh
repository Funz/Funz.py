#!/bin/bash

cd `dirname $0`

MAIN=org.funz.calculator.Calculator

LIB=`find -L lib -name "funz-core-*.jar"`:`find -L lib -name "funz-calculator-*.jar"`:`find -L lib -name "commons-io-2.4.jar"`:`find -L lib -name "commons-exec-*.jar"`:`find -L lib -name "commons-lang-*.jar"`:`find -L lib -name "ftpserver-core-*.jar"`:`find -L lib -name "ftplet-api-*.jar"`:`find -L lib -name "mina-core-*.jar"`:`find -L lib -name "sigar-*.jar"`:`find -L lib -name "slf4j-api-*.jar"`:`find -L lib -name "slf4j-nop-*.jar"`

CALCULATOR=file:calculator.xml

if [ -e calculator-`hostname`.xml ]
then
CALCULATOR=file:calculator-`hostname`.xml
fi

FUNZ_HOME=${FUNZ_HOME:-$HOME/.Funz}
if [ ! -d $FUNZ_HOME ]
then
mkdir $FUNZ_HOME
fi
if [ ! -d $FUNZ_HOME/log ]
then
mkdir $FUNZ_HOME/log
fi

HOSTNAME=`hostname`

for n in `seq 1 $1`
do
        nohup java -Dapp.home=. -classpath $LIB $MAIN $CALCULATOR > $FUNZ_HOME/log/funzd.$HOSTNAME.$n.out &
        PID=$!
        echo $PID > $FUNZ_HOME/log/funzd.$HOSTNAME.$n.pid
done
