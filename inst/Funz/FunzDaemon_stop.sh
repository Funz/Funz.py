#!/bin/bash

FUNZ_HOME=$HOME/.Funz

HOSTNAME=`hostname`

for n in `ls $FUNZ_HOME/log/funzd.$HOSTNAME.*.pid`
do
        cat $n | xargs kill -9
        rm -f $n
done

