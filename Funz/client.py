#!/usr/bin/env python3

import os

from .inst.Funz.Funz import *
from Funz import FUNZ_HOME

def Run(model=None,input_files=None,
                input_variables=None,all_combinations=False,
                output_expressions=None,
                run_control={'force_retry':2,'cache_dir':None},
                monitor_control={'sleep':5,'display_fun':None},
                archive_dir=None,out_filter=None,verbosity=1):
    """ Call an external code wrapped through Funz.
    @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
    @param input_files list of files to give as input for the code.
    @param input_variables data.frame of input variable values. If more than one experiment (i.e. nrow >1), experiments will be launched simultaneously on the Funz grid.
    @param all_combinations if False, input_variables variables are grouped (default), else, if True experiments are an expaanded grid of input_variables
    @param output_expressions list of interest output from the code. Will become the names() of return list.
    @param run_control list of control parameters:
      'force.retry' is number of retries before failure,
      'cache.dir' setup array of directories to search inside before real launching calculations.
    @param monitor_control list of monitor parameters: sleep (delay time between two checks of results), display.fun (function to display project cases status).
    @param archive_dir define an arbitrary output directory where results (cases, csv files) are stored.
    @param out_filter what output(s) to retreive in returned object.
    @param verbosity 0-10, print information while running.
    @return list of array results from the code, arrays size being equal to input_variables arrays size.
    @export
    @examples
    \dontrun{
    # Basic response surface of Branin function. R is used as the model, for testing purpose.
    calcs = Funz.startCalculators(5) # Will start calculator instances later used by Run()
    Funz.Run(model = "Python",
      input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
      input_variables = {'x1':numpy.arange(0,1,0.1),'x2':numpy.arange(0,1,0.1)},
      all_combinations=True,
      output_expressions = "z")
    fig = matplotlib.pyplot.figure() #import matplotlib.pyplot
    ax = mpl_toolkits.mplot3d.Axes3D(fig) #import mpl_toolkits.mplot3d
    fig.add_axes(ax)
    ax.scatter(Funz._Last_run()['results']['x1'],Funz._Last_run()['results']['x2'],Funz._Last_run()['results']['z'])
    matplotlib.pyplot.show()
    Funz.stopCalculators(calcs) # Shutdown calculators (otherwise stay in background)
    # More realistic case using Modelica. Assumes that (Open)Modelica is already installed.
    installModel("Modelica") # Install Modelica plugin
    calcs = Funz.startCalculators(5) # Will start calculator instances later used by Run()
    NewtonCooling = Funz.Run(model = "Modelica",
      input_files = os.path.join(Funz.FUNZ_HOME,"samples","NewtonCooling.mo.par"),
      input_variables = {'convection':numpy.arange(0,2,0.1)},
      output_expressions = "min(T)")
    matplotlib.pyplot.scatter(NewtonCooling['convection'], NewtonCooling['min(T)']) #import matplotlib.pyplot
    Funz.stopCalculators(calcs) # Shutdown calculators (otherwise stay in background)
    }
    """
    if input_files is None: raise Exception("Input files has to be defined")
    return(Funz_Run(model=model,input_files=input_files,
             input_variables=input_variables,all_combinations=all_combinations,output_expressions=output_expressions,
             run_control=run_control,monitor_control=monitor_control,
             archive_dir=archive_dir,out_filter=out_filter,verbosity=verbosity,log_file=(not archive_dir is None)))

def _Last_run():
    """ Get last Funz Run(...) call
    @return last Funz Run(...) call
    @export
    """
    return(Funz_Last_run())

def Design(fun, design, options=None,
                   input_variables=None,
                   fun_control={'cache':False,'vectorize':"fun",'vectorize_by':1,'foreach_options':None},
                   monitor_control={'results_tmp':True},
                   archive_dir=None,out_filter=None,verbosity=1,*vargs):
    """ Apply a design of experiments through Funz environment on a response surface.
    @param design Design of Experiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
    @param input_variables list of variables definition in a String (for instance x1="[-1,1]")
    @param options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
    @param fun response surface as a target (say objective when optimization) function of the DoE. This should include calls to Funz_Run() function.
    @param fun_control list of fun usage options:
      'cache' set to True if you wish to search in previous evaluations of fun before launching a new experiment. Sometimes useful when design asks for same experiments many times. Always False if fun is not repeatible.
      'vectorize' set to "fun" (by default) if fun accepts nrows>1 input. Set to "foreach" if delegating to 'foreach' loop the parallelization of separate 'fun' calls (packages foreach required, and some Do* needs to be registered and started before, and shutdown after). Set to "parallel" if delegating to 'parallel' the parallelization of separate 'fun' calls. Set to False or "apply" means apply() will be used for serial launch of experiments.
      'vectorize.by' set the number of parallel execution if fun_control$vectorize is set to "foreach" or "parallel". By default, set to the number of core of your computer (if known by R, otherwise set to 1).
      'foreach_options optional parameters to pass to the foreach DoPar. Should include anything needed for 'fun' evaluation.
    @param monitor_control list of control parameters: 'results.tmp' list of design results to display at each batch. True means "all", None/False means "none".
    @param archive_dir define an arbitrary output directory where results (log, images) are stored.
    @param out_filter what output(s) to retreive in returned object.
    @param verbosity print (lot of) information while running.
    @param ... optional parameters passed to 'fun'
    @return list of results from this DoE.
    @export
    @examples
    \dontrun{
    # Download on github the GradientDescent algorithm, and install it:
    Funz.installDesign("GradientDescent")
    Funz.Design(fun = lambda X: abs(X['x1']*X['x2']),
      fun_control={'vectorize':'for'},
      design = "GradientDescent", options = {'max_iterations':10},
      input_variables = {'x1':"[0,1]",'x2':"[1,2]"})
    }
    """
    if input_variables is None: raise Exception("Input variables 'input_variables' must be specified.")
    return(Funz_Design(fun=fun,design=design,options=options,
                input_variables=input_variables,
                fun_control=fun_control,monitor_control=monitor_control,
                archive_dir=archive_dir,out_filter=out_filter,verbosity=verbosity,log_file=(not archive_dir is None),*vargs))

def _Last_design():
    """ Get last Funz Design(...) call
    @return last Funz Design(...) call
    @export
    """
    return(Funz_Last_design())

def RunDesign(model=None,input_files=None,
                      input_variables=None,output_expressions=None,
                      design=None,design_options=None,
                      run_control={'force_retry':2,'cache_dir':None},
                      monitor_control={'results_tmp':True,'sleep':5,'display_fun':None},
                      archive_dir=None,out_filter=None,verbosity=1):
    """ Call an external (to R) code wrapped through Funz environment.
    @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
    @param input_files list of files to give as input for the code.
    @param input_variables list of variables definition in a String (for instance x1="[-1,1]"), or array of fixed values (will launch a design for each combination).# @param all_combinations if False, input_variables variables are grouped (default), else, if True experiments are an expaanded grid of input_variables
    @param output_expressions list of interest output from the code. Will become the names() of return list.
    @param design Design of Experiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
    @param design_options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
    @param run_control list of control parameters:
      'force.retry' is number of retries before failure,
      'cache.dir' setup array of directories to search inside before real launching calculations.
    @param monitor_control list of monitor parameters: sleep (delay time between two checks of results), display.fun (function to display project cases status).
    @param archive_dir define an arbitrary output directory where results (cases, csv files) are stored.
    @param out_filter what output(s) to retreive in returned object.
    @param verbosity 0-10, print information while running.
    @return list of array design and results from the code.
    @export
    @examples
    \dontrun{
    # Search for minimum of Branin function, taken as the model (test case)
    Funz.installDesign("GradientDescent") # Download on github the GradientDescent algorithm
    Funz.startCalculators(5) # start calculator instances to run model
    Funz.RunDesign(model="Python",
              input_files=os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
              output_expressions="z", design = "GradientDescent",
              design_options = {'max_iterations'=10},input_variables = {'x1':"[0,1]",'x2':"[0,1]"})
    # More realistic case using inversion of Modelica:
    #  find convection coefficient that gives minimal temperature of 40 degrees.
    Funz.installModel("Modelica") # Install Modelica plugin (Assumes that Modelica is already installed)
    Funz.installDesign("Brent")   # Install Brent algorithm for inversion
    calcs = Funz.startCalculators(5) # Will start calculator instances, later used by Run()
    NewtonCooling = Funz.RunDesign(model = "Modelica",
      input_files = os.path.join(Funz.FUNZ_HOME,"samples","NewtonCooling.mo.par"),
      input_variables = {convection="[0.0001,1]"}, output_expressions = "min(T)",
      design="Brent",design_options={'ytarget':40.0})
    matplotlib.pyplot.scatter(NewtonCooling$convection[[1]], NewtonCooling$`min(T)`[[1]])
    abline(h=40.0)
    abline(v=NewtonCooling$analysis.root)
    Funz.stopCalculators(calcs) # Shutdown calculators (otherwise stay in background)
    }
    """
    if input_files is None: raise Exception("Input files has to be defined")
    return(Funz_RunDesign(model=model,input_files=input_files,output_expressions=output_expressions,
                   design=design,input_variables=input_variables,design_options=design_options,
                               run_control=run_control,monitor_control=monitor_control,
                               archive_dir=archive_dir,out_filter=out_filter,verbosity=verbosity,log_file=(not archive_dir is None)))
                     
def _Last_rundesign():
    """ Get last Funz RunDesign(...) call
    @return last Funz RunDesign(...) call
    @export
    """
    return(Funz_Last_rundesign())


def ParseInput(model,input_files):
    """ Convenience method to find variables & related info. in parametrized file.
    @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
    @param input_files files to give as input for the code.
    @return list of variables & their possible default value
    @export
    @examples
    Funz.ParseInput(model = "Python",
               input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"))
    """
    return(Funz_ParseInput(model=model,input_files=input_files))

def CompileInput(model,input_files,input_values,output_dir="."):
    """ Convenience method to compile variables in parametrized file.
    @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
    @param input_files files to give as input for the code.
    @param input_values list of variable values to compile.
    @param output_dir directory where to put compiled files.
    @export
    @examples
    Funz.CompileInput(model = "Python",
                 input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
                 input_values = {'x1':0.5, 'x2':0.6})
    Funz.CompileInput(model = "Python",
                 input_files = os.path.join(Funz.FUNZ_HOME,"samples","branin.py"),
                 input_values = {'x1':[0.5,.55], b=[0.6,.7]})
    """
    return(Funz_CompileInput(model=model,input_files=input_files,input_values=input_values,output_dir=output_dir))

def ReadOutput(model, input_files, output_dir, out_filter=None):
    """ Convenience method to find variables & related info. in parametrized file.
    @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
    @param input_files files given as input for the code.
    @param output_dir directory where calculated files are.
    @param out_filter what output(s) to retreive in returned object.
    @return list of outputs & their value
    @export
    @examples
    \dontrun{
    Funz.ReadOutput(model = "Python", input_files = "branin.py",output_dir=".")
    }
    """
    return(Funz_ReadOutput(model=model, input_files=input_files, output_dir=output_dir, out_filter=out_filter))
