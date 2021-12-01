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

def startCalculators(n=1, stdout=None,stderr=None):
    """ Start calculator instances (also named as "funz daemons")
    @param n number of calculators to start
    @param stdout calculators output stream: None (default) or "|"
    @param stderr calculators error stream: None (default) or "|"
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
    if stdout is None:
        stdout = subprocess.DEVNULL
    if stdout == "|":
        stdout = subprocess.PIPE
    if stderr is None:
        stderr = subprocess.DEVNULL
    if stderr == "stdout":
        stderr = subprocess.STDOUT
    if stderr == "|":
        stderr = subprocess.PIPE
    if sys.platform.startswith("win"):
        CREATE_NEW_PROCESS_GROUP = 0x00000200  # note: could get it from subprocess
        DETACHED_PROCESS = 0x00000008  
        for i in range(n):
            p.append(subprocess.Popen([os.path.abspath(os.path.join(FUNZ_HOME,"FunzDaemon.bat"))],
            cwd=FUNZ_HOME, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
            creationflags=DETACHED_PROCESS|CREATE_NEW_PROCESS_GROUP, close_fds=True))
    else:
        for i in range(n):
            p.append(subprocess.Popen(os.path.join(FUNZ_HOME,"FunzDaemon.sh"), preexec_fn=os.setsid,
            cwd=FUNZ_HOME, stdout=stdout, stderr=stderr))
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
