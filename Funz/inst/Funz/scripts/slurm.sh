#!/bin/bash
# This script is intended to wrap common sh command beahviour upon SLURM srun.
# Especially, the kill or ctrl-c will correctly cancel the SLURM job using scancel.

abort() {
  echo "Abort SLURM process: "$qname
  scancel -n $qname
  echo "SLURM process aborted."
}
trap "abort" INT
trap "abort" TERM 

SUBMIT="salloc"
if [ $1 == "--srun" ]; then
  SUBMIT="srun"
  shift
fi
if [ $1 == "--salloc" ]; then
  SUBMIT="salloc"
  shift
fi

cmd=$1
input=${@:2}
cwd=`pwd`

qname="_"$$
export pid=$cwd/node.PID

export SBATCH_OPT=""
SBATCH_OPT_in=`grep "SBATCH " * | sed 's/.*SBATCH //' | tr '\n' ' ' | tr -d '\r'`
  echo "parse SBATCH "$SBATCH_OPT_in >> log.txt
if [ ! "$SBATCH_OPT_in""zz" = "zz" ] ; then
  export SBATCH_OPT=$SBATCH_OPT_in
fi
echo "SBATCH: "$SBATCH_OPT >> log.txt

echo "SUBMIT: "$SUBMIT >> log.txt
$SUBMIT -J $qname $SBATCH_OPT --chdir=$cwd $cmd $input >> out.txt &
mid=$!

sleep 1

if [ `grep "Unable to allocate resources" err.txt | wc -w` != 0 ] ; then
  echo "Not enought resources. Waiting 10s before restart." >> err.txt
  sleep 10
  exit 1
elif [ `grep "Stale file handle" err.txt | wc -w` != 0 ] ; then
  echo "NFS latency. Waiting 10s before restart." >> err.txt
  sleep 10
  exit 2
else
  wait $mid
fi
