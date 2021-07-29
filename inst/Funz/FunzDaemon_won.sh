#!/bin/bash
# Funz daemon Wake on Network (WoN)
# This script will update calculator.xml with new HOSTs, when a netcat command is sent from a remote client:
#  * to add    the client in calculator.xml [& start daemons]: 
#    * using netcat:       echo "hi"| nc myserver -w1 19000
#    * using curl (win10): echo "hi"| curl -m 1 telnet://myserver:19000
# * to remove the client in calculator.xml [& stop daemons]:
#    * using netcat:       echo "bye"| nc myserver -w1 19000
#    * using curl (win10): echo "bye"| curl -m 1 telnet://myserver:19000

LISTEN_PORT="19000"
FUNZ_HOME=`dirname $0`
CALCULATORS=10
PORTS=( "19001" "19002" "19003" "19004" ) # May be read from message, also

# Uncomment your NetCat version:
#NCAT="nc -nvFl" ## OpenBSD NetCat
#GET_IP="sed 's/\(.*\)Connection received on \(.*\)/\2/' | cut -d' ' -f1"
#GET_SAY="sed 's/\(.*\)Connection received on \(.*\)/\2/' | cut -d'_' -f2"
NCAT="ncat -nvl" ## NMap NetCat
GET_IP="sed 's/\(.*\)Connection from \(.*\)/\2/' | cut -d':' -f1"
GET_SAY="sed 's/\(.*\)Connection from \(.*\)/\2/' | cut -d'_' -f2"


# Stop daemons & restore calculator.xml
cp $FUNZ_HOME/calculator.xml $FUNZ_HOME/calculator-bak.xml
function _stop {
  $FUNZ_HOME/FunzDaemon_stop.sh
  mv $FUNZ_HOME/calculator-bak.xml $FUNZ_HOME/calculator.xml
}
trap _stop INT
trap _stop TERM
trap _stop EXIT


funz_clients=""
while true; do 
  # Get & read netcat message
  message="$($NCAT $LISTEN_PORT 2>&1 | tr '\n' '_')"
  ip=`eval "echo \"$message\" | $GET_IP"`
  echo "ip:"$ip
  say=`eval "echo \"$message\" | $GET_SAY"`
  echo "say:'"$say"'"

  # Update calculator.xml
  if [[ $say == "hi" ]]; then
    cp $FUNZ_HOME/calculator.xml $FUNZ_HOME/calculator-tmp.xml
    for p in "${PORTS[@]}"; do
      sed -i -- "s_</CALCULATOR>_<HOST name='$ip' port='$p'/>\n</CALCULATOR>_g" $FUNZ_HOME/calculator-tmp.xml
    done
    mv $FUNZ_HOME/calculator-tmp.xml $FUNZ_HOME/calculator.xml

    if [[ ${#funz_clients} == "0" ]]; then $FUNZ_HOME/FunzDaemon_start.sh $CALCULATORS; fi  # just added the first client, so start daemons
    funz_clients=$funz_clients","$ip
    echo "++ "$ip
  else
    cp $FUNZ_HOME/calculator.xml $FUNZ_HOME/calculator-tmp.xml
    for p in "${PORTS[@]}"; do
      sed -i -- "s_<HOST name='$ip' port='$p'/>\$__g" $FUNZ_HOME/calculator-tmp.xml
    done      
    sed -i -- '/^$/N;/^\n$/D' $FUNZ_HOME/calculator-tmp.xml # cleanup blank lines
    mv $FUNZ_HOME/calculator-tmp.xml $FUNZ_HOME/calculator.xml

    funz_clients=$(echo "$funz_clients" | sed "s/,$ip//g")
    echo "-- "$ip
    if [[ ${#funz_clients} == "0" ]]; then $FUNZ_HOME/FunzDaemon_stop.sh; fi # No remaining clients, so stop daemons
  fi
done
