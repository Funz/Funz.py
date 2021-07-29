#!/bin/bash
# This script is intended to wrap common sh command beahviour upon SGE qrsh.
# Especially, the kill or ctrl-c will correctly cancel the SGE job using qdel.

trap "abort" INT
trap "abort" TERM

abort() {
  echo "Abort queued process..."
  qdel $qid
  echo "Queued process aborted."
}

cmd=$1
input=${@:2}
cwd=`pwd`

qname="_"$$
export pid=$cwd/node.PID

export RUN_OPT="-q std -l mem_free=4G -pe smp 1"
RUN_OPT_in=`grep "RUN_OPT=" * | cut -d'=' -f2 | tr -d '\n' | tr -d '\r'`
  echo "parse RUN_OPT_in "$RUN_OPT_in >> out.txt
if [ ! "$RUN_OPT_in""zz" = "zz" ] ; then
  export RUN_OPT=$RUN_OPT_in
fi
echo "RUN_OPT: <"$RUN_OPT">"

qrsh -V -N $qname $RUN_OPT -cwd $cmd $input >> out.txt &
mid=$!

sleep 1

if [ `grep "request could not be scheduled" out.txt | wc -w` != 0 ] ; then
  exit -1
fi

lastq=`qstat | grep $qname | tail -1`
qid=`echo ${lastq/ /} | cut -d" " -f1`

wait $mid
