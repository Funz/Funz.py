#!/usr/bin/env python3
import os, inspect, sys

# print(os.getcwd())
global FUNZ_HOME
FUNZ_HOME = os.path.join(
    os.path.realpath(os.path.abspath(os.path.split(inspect.getfile( inspect.currentframe() ))[0])),
    "inst","Funz")

from .inst.Funz.Funz import *
# exec(open(os.path.join(FUNZ_HOME,"Funz.py")).read())
verb=os.getenv("FUNZ_verbosity")
try:
  verb=int(verb)
except:
  verb=0
Funz_init(FUNZ_HOME,verbosity=verb)

from .client import *
from .client import _Last_run
from .client import _Last_design
from .client import _Last_rundesign
from .calculator import *
from .install import *


