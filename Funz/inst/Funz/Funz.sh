#!/bin/bash -f
# -f is there to disable the pattern matching of files using [] delimiters (which are also used inside vaiables bounds expression !)

if [ $# -le 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then 
  echo "Usage: Funz.sh COMMAND [ARGS]"
  echo ""
  echo "  Run ...             Launch (remote) calculations, replacing variables by given values"
  echo "  Design ...          Apply an algorithm on an executable program returning target output value"
  echo "  RunDesign ...       Apply an algorithm and launch required calculations"
  echo "  ParseInput ...      Find variables inside parametrized input file"
  echo "  CompileInput ...    Replace variables inside parametrized input file"
  echo "  ReadOutput ...      Read output files content"
  echo "  GridStatus          Display calculators list and status" 
  exit 0
fi


FUNZ_PATH="$( cd "$(dirname "$0")" ; pwd -P )" #absolute `dirname $0`

MAIN=org.funz.main.$1

LIB=`find $FUNZ_PATH/lib -name '*.jar' | xargs echo | tr ' ' ':'`

java -Dcharset=ISO-8859-1 -Xmx512m -Dapp.home=$FUNZ_PATH -classpath $LIB $MAIN $*
# -Douterr=.$1

if [ $? -ne 0 ]; then 
  echo "See log file: "$1".log" >&2
  echo "See help: Funz.sh "$1" -h"
fi