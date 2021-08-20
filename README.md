---
title: "Funz from Python"
author: "Y. Richet"
date: "30/07/2021"
output:
  pdf_document: default
  html_document: default
---

```{python setup}
# requirements
import sys
import subprocess
import os
import json

libs = ["math","numpy","matplotlib"]
for l in libs:
   if l not in sys.modules.keys():
      subprocess.check_call([sys.executable, "-m", "pip", "install", l])
```


## Install

Just use the standard 'pip install Funz' command:
```{python}
# install Funz if needed
if "Funz" not in sys.modules.keys():
   subprocess.check_call([sys.executable, "-m", "pip", "install", "Funz"])

import Funz
Funz.installDesign("GradientDescent") # required for later example
```

## Usage: Funz from Python console

Once installed, Funz Python module allows to access almost all features of Funz through command line.

#### Starting calculations back-end

It is mandatory to launch calculation back-end which will be used to perform parametric calculations, later.

___Note: it is also possible to start this back-end on another computer/server/cluster, which will be usable by all computer which IP is declared in 'calculator.xml' file (by default, it just contains "127.0.0.1" local address).___

```{python}
# This will start 5 calculators, in background
calcs = Funz.startCalculators(5)
```

You can check all available calculators from your computer using:
```{python}
Funz.Grid()
```


### Parametric modelling

This main feature of Funz allows to evaluate a parametric model, built from parameterized files (like following ' branin.py' file including variables starting with a reserved character '?'):
```{python echo=F, comment=''}
with open(os.path.join(Funz.FUNZ_HOME,"samples","branin.py"), 'r') as f:
    print(f.read())
```
___Note: usually, a parametric model is based on heavy simulation software, not callable easily like a function. In practice, this example with a Python function may be easier to evaluate directly, of course.___

Once calculators (eg. started from back-end) are available, you can launch this parametric model for given variables (x1 and x2) values:
```{python results=F}
import numpy

Funz.Run(model = "Python",
    input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
    input_variables = {'x1':numpy.arange(0,1,0.1),'x2':numpy.arange(0,1,0.1)},
    all_combinations = True,
    output_expressions = "z")
```

... get and display results (using the 'Funz._Last_run' global variable, if 'Run()' was not assigned):
```{python}
r = Funz._Last_run()['results']

for s in r.keys(): print(s+": "+str(r[s][:10])+" ...") # print head
```

... or plot model response surface :
```{python}
# Response surface of previous Run
import matplotlib.pyplot
fig = matplotlib.pyplot.figure()
import mpl_toolkits.mplot3d
ax = mpl_toolkits.mplot3d.Axes3D(fig)
fig.add_axes(ax)
ax.scatter(Funz._Last_run()['results']['x1'],Funz._Last_run()['results']['x2'],Funz._Last_run()['results']['z'])
matplotlib.pyplot.show()
```


### Applying algorithm on function

The other main feature of Funz consists in applying an algorithm/analysis on a function:
```{python results=F}
import math

def branin(x):
    x1 = numpy.array(x['x1'])*15-5
    x2 = numpy.array(x['x2'])*15
    return ((x2 - 5/(4*math.pi**2)*(x1**2) + 5/math.pi*x1 -6 )**2 + 10*(1-1/(8*math.pi))*numpy.cos(x1) +10).tolist()

Funz.Design(fun = branin,
       design = "GradientDescent", options = {'max_iterations':15},
       input_variables = {'x1':"[0,1]",'x2':"[0,1]"})
```

which solves the targeted issue (here an optimization):
```{python}
x = numpy.arange(0,1.01,1/40)
xx = numpy.array([[x1, x2] for x1 in x for x2 in x]).reshape(-1,2)
xx = {'x1':xx[:,0].tolist(),'x2':xx[:,1].tolist()}
import matplotlib.pyplot
matplotlib.pyplot.contour(x,x,numpy.array(branin(xx)).reshape(-1,41))
  
d = Funz._Last_design()['results']
argmin = json.loads(d['analysis.argmin'])
matplotlib.pyplot.plot(argmin[0],argmin[1],color='red')
```


### Applying algorithm on parametric modelling

These two main features may also be coupled to apply an algorithm directly on the parametric model:
```{python results=F}
Funz.RunDesign(model = "Python",
          input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
          design = "GradientDescent", design_options = {'max_iterations':15},
          input_variables = {'x1':"[0,1]",'x2':"[0,1]"},
          output_expressions = "z")
```

... and returns the algorithm analysis:
```{python}
x = numpy.arange(0,1.01,1/40)
xx = numpy.array([[x1, x2] for x1 in x for x2 in x]).reshape(-1,2)
xx = {'x1':xx[:,0].tolist(),'x2':xx[:,1].tolist()}

import matplotlib.pyplot
fig = matplotlib.pyplot.figure()
import mpl_toolkits.mplot3d
ax = mpl_toolkits.mplot3d.Axes3D(fig)
fig.add_axes(ax)
ax.scatter(xx['x1'],xx['x2'],numpy.array(branin(xx)),color='gray')

rd = Funz._Last_rundesign()['results']
# plot all evaluated points
ax.scatter(rd['x1'],rd['x2'],rd['z'],color='blue')
# plot min/argmin searched
argmin = json.loads(rd['analysis.argmin'][0])
min = json.loads(rd['analysis.min'][0])
ax.scatter([argmin[0]],[argmin[1]],[min],color='red')

matplotlib.pyplot.show()
```

Once finished, it is recommended to shutdown calculators in back-end:
```{python}
# This will stop the 5 calculators started earlier
Funz.stopCalculators(calcs)
```

## Setup algorithms & models

After a fresh install of Funz, is is commonplace to add useful models or algorithms.
Such a plugin is a 'zip' file, which may be installed locally, or directly from GitHub Fuz repository.

### Install new model

Get already installed models:
```{python}
Funz.installedModels()
```

Get available models from GitHub:
```{python}
Funz.availableModels()
```

Install a new model from GitHub:
```{python}
Funz.installModel("Modelica")
```

... or from a local file:
```{python eval=F}
Funz.install_fileModel("plugin-Modelica.zip")
```

### Install new algorithm

Get already installed models:
```{python}
Funz.installedDesigns()
```

Get available models from GitHub:
```{python}
Funz.availableDesigns()
```

Install a new model from GitHub:
```{python}
Funz.installDesign("Brent")
```

... or from a local file:
```{python eval=F}
Funz.install_fileDesign("algorthm-Brent.zip")
```
