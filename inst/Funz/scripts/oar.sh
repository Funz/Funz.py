#!/bin/bash

trap "abort" INT
trap "abort" TERM

abort() {
  echo "Abort queued process..."
  oardel $qid
  echo "Queued process aborted."
}

cmd=$1
input=${@:2}
cwd=`pwd`

qname="_"$$
export pid=$cwd/node.PID

export RUN_OPT="-l memnode=4196/nodes=1/core=1,walltime=01:00:00"
RUN_OPT_in=`grep "RUN_OPT=" * | cut -d'=' -f2 | tr -d '\n' | tr -d '\r'`
  echo "parse RUN_OPT_in "$RUN_OPT_in >> out.txt
if [ ! "$RUN_OPT_in""zz" = "zz" ] ; then
  export RUN_OPT=$RUN_OPT_in
fi
echo "RUN_OPT: <"$RUN_OPT">"

sub=$(oarsub $RUN_OPT -d $cwd -n $qname $cmd $input | grep OAR_JOB_ID)
qid=${sub#*=}

while [ "`oarstat | grep $qid | wc -l`" == "1" ]; do echo "."; sleep 1; done



