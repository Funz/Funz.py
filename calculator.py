#!/usr/bin/env python3

import sys, subprocess, signal

from .inst.Funz.Funz import *
from Funz import FUNZ_HOME

def Grid():
    """ Display Funz grid
    @return Funz grid status
    @export
    @examples
    \dontrun{
    Grid() # ..Will display no calculator
    # This will start 5 instances of calculator (waiting for a "Run()" call)
    calcs = startCalculators(5)
    Grid() # ...Will now display the 5 calculators started.
    stopCalcualtors(calcs)
    Grid() # ...Will now display no calculator.
    }
    """
    return(Funz_GridStatus())

def startCalculators(n=1):
    """ Start calculator instances (also named as "funz daemons")
    @param n number of calculators to start
    @return subprocess objects of started calculators
    @export
    @import subprocess
    @examples
    \dontrun{
    # This will start 5 instances of calculator waiting for a "Run()" call
    startCalculators(5)
    }
    """
    p=[]
    n=int(n)
    if sys.platform.startswith("win"):
        for i in range(n):
            p.append(subprocess.Popen(os.path.join(FUNZ_HOME,"FunzDaemon.bat"),preexec_fn=os.setsid,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL))
    else:
        for i in range(n):
            p.append(subprocess.Popen(os.path.join(FUNZ_HOME,"FunzDaemon.sh"), preexec_fn=os.setsid,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL))
    return(p)

def stopCalculators(px):
    """ Shutdown calculator instances (also named as "funz daemons")
    @param px array of subprocess objects to stop (returned values of startCalculators()^)
    @export
    @examples
    \dontrun{
    calcs = startCalculators(5)
    # ...
    stopCalculators(calcs)
    }
    """
    for p in px:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)
