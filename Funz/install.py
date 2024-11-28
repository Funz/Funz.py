#!/usr/bin/env python3

import re, os, requests, warnings, subprocess, sys

from Funz import FUNZ_HOME
from .inst.Funz.Funz import *

global _github_pattern
_github_pattern = "https://github.com/Funz/__TYPE__-__MODEL__/releases/download/v__MAJOR__-__MINOR__/__TYPE__-__MODEL__.zip"
def _github_release(_type,model,major,minor):
    return(
    re.sub("__TYPE__",_type,
        re.sub("__MODEL__",model,
            re.sub("__MAJOR__",major,
                re.sub("__MINOR__",minor,
                    _github_pattern)))))

global _github_repos
_github_repos = None
try:
    _github_repos = requests.get(f"https://api.github.com/orgs/Funz/repos?per_page=100", headers={}, params={}).json()
    if len(_github_repos)<=1:
        _github_repos = None
except:
    pass

############################ Models #################################

from .inst.Funz.Funz import _jclassFunz
from .inst.Funz.Funz import _JArrayToPArray
def installedModels():
    """ Get available Funz Models
    @return array of available Models in Funz environment.
    @export
    @examples
    installedModels()
    """
    return(_JArrayToPArray(_jclassFunz.getModelList()))

def availableModels(refresh_repo = False):
    """ List available models from Funz GitHub repository
    @param refresh_repo should we force refreshing GitHub Funz repositories content ?
    @return array of available models
    @export
    @examples
    availableModels()
    """
    global _github_repos
    if refresh_repo or (_github_repos is None):
        _github_repos = requests.get(f"https://api.github.com/orgs/Funz/repos?per_page=100", headers={}, params={}).json()
    if len(_github_repos)<=1:
        _github_repos = None

    if _github_repos is None:
        warnings.warn("Failed to acces GitHub Funz repo: "+str(requests.get(f"https://api.github.com/orgs/Funz/repos", headers={}, params={})))
        return(None)
    
    l = lambda r: re.sub("plugin-","",r['name'])
    return( [l(r) for r in _github_repos  if 'name' in r.keys() and re.subn("plugin-","",r['name'])[1]>0] )

import zipfile
from .inst.Funz import Funz
def install_fileModel(model_zip, force=False, edit_script=False):
    """ Install Funz model plugin from local zip file.
    @param model_zip zip file of plugin. Usually plugin-XYZ.zip
    @param force if already installed, reinstall.
    @param edit_script open installed script for customization.
    @param ... optional parameters to pass to unzip()
    @export
    """
    model=re.sub(".zip(.*)","",re.sub("(.*)plugin-","",model_zip))
    if model in installedModels():
        if not force:
            warnings.warn("Model "+model+" was already installed. Skipping new installation.")
            return(None)
        else:
            print("Model "+model+" was already installed. Forcing new installation...")
    
    with zipfile.ZipFile(model_zip, 'r') as zip_ref:
        zip_ref.extractall(FUNZ_HOME)

    # reload plugins in Funz env
    _jclassFunz.init()
    Funz._Funz_Models = installedModels()
  
    if not (model in installedModels()):
        raise Exception("Could not install model "+model+" from "+model_zip)
    else:
        print("Installed Funz model "+model)
    
    # .. in the end, configure model script
    setupModel(model=model, edit_script=edit_script)

import xml.etree.ElementTree as ElementTree
def setupModel(model, edit_script=False):
    """ Configure model calculation entry point
    @param model Name of model corresponding to given script
    @param edit_script open installed script for customization.
    @export
    """
    # Setup script file
    if sys.platform.startswith("win"):
        script = os.path.join(FUNZ_HOME,"scripts",model+".bat")
    else:
        script = os.path.join(FUNZ_HOME,"scripts",model+".sh")
    
    try:
        if not os.path.isfile(script):
            if sys.platform.startswith("win"):
                with open(script, "wb") as f:
                    f.write(("@echo off\n\nREM Fill this file to launch "+model+"\nREM First argument will be the main file").encode('utf8'))
            else:
                with open(script, "wb") as f:
                    f.write(("#!/bin/bash\n\n# Fill this file to launch "+model+"\n# First argument will be the main file").encode('utf8'))
    except:
        pass
    os.chmod(script,int(0o644))

    if edit_script:
        print("The script used to launch "+model+" is now opened in the editor.")
        if sys.platform.startswith("win"):
            os.system("start "+'"'+script+'"')
        elif sys.platform.startswith("dar"):
            subprocess.call(["open", '"'+script+'"'])
        else:
            if not os.getenv('EDITOR') is None:
                os.system('%s %s' % (os.getenv('EDITOR'), '"'+script+'"'))
            else:
               subprocess.call(["xdg-open", '"'+script+'"'])
    os.chmod(script,int(0o755))

    # Update calculator_xml
    calculator_xml = ElementTree.parse(os.path.join(FUNZ_HOME,"calculator.xml"))
    found = False
    for i in range(len(list(calculator_xml.getroot()))):
        node = list(calculator_xml.getroot())[i]
        if 'name' in node.keys():
            if node.attrib['name'] == model:
                found = True
                node.attrib['command'] = script
                cplugin = os.path.join(FUNZ_HOME,"plugins","calc",model+".cplugin.jar")
                if os.path.isfile(cplugin):
                    node.attrib['cplugin'] = "file://"+cplugin
            list(calculator_xml.getroot())[i] = node
            break
    # Add this CODE if not yet found
    if not found:
        node = ElementTree.SubElement(calculator_xml.getroot(),
        'CODE',
        name=model,
        command=script)
        cplugin = os.path.join(FUNZ_HOME,"plugins","calc",model+".cplugin.jar")
        if os.path.isfile(cplugin):
              node.attrib['cplugin'] = "file://"+cplugin
        list(calculator_xml.getroot()).append(node)

        with open(os.path.join(FUNZ_HOME,"calculator.xml"), "wb") as f:
            f.write(ElementTree.tostring(calculator_xml.getroot()))
        print("Funz model "+model+" added.")
    else:
        print("Funz model "+model+" already setup.")

def setupCalculator():
    print("The calculator.xml file is now opened in the editor: "+os.path.join(FUNZ_HOME,"calculator.xml"))
    if sys.platform.startswith("win"):
        os.system("start "+'"'+os.path.join(FUNZ_HOME,"calculator.xml")+'"')
    elif sys.platform.startswith("dar"):
        subprocess.call(["open", '"'+os.path.join(FUNZ_HOME,"calculator.xml")+'"'])
    else:
        if not os.getenv('EDITOR') is None:
            os.system('%s %s' % (os.getenv('EDITOR'), '"'+os.path.join(FUNZ_HOME,"calculator.xml")+'"'))
        else:
            subprocess.call(["xdg-open", '"'+os.path.join(FUNZ_HOME,"calculator.xml")+'"'])

import tempfile, importlib, importlib.metadata
def install_githubModel(model,force=False, edit_script=False):
    """ Install Funz model plugin from central GitHub repository.
    @param model model to install.
    @param force if already installed, reinstall.
    @param edit_script open installed script for customization.
    @export
    @examples
    \dontrun{
    install_githubModel('Modelica')
    }
    """
    major = re.sub(".post(.*)","",importlib.metadata.version('Funz'))
    model_zip = os.path.join(tempfile.gettempdir(),"plugin-"+model+".zip")
    for minor in range(11)[::-1]:
        print(".", end = '')
        z = requests.get(_github_release("plugin",model,major,str(minor)))
        if z.ok: 
            with open(model_zip, "wb") as f:
                f.write(z.content)
            break
    
    if not z.ok: raise Exception("Could not download model "+model)
    
    install_fileModel(model_zip=model_zip, force=force, edit_script=edit_script)

def installModel(model, force=False, edit_script=False):
    """ Install Funz model from local file or GitHub central repository
    @param model model to install.
    @param force if already installed, reinstall.
    @param edit_script open installed script for customization.
    @export
    @examples
    \dontrun{
    installModel('Modelica')
    }
    """
    if os.path.isfile(model):
        install_fileModel(model_zip=model, force=force, edit_script=edit_script)
    else:
        if model in availableModels():
            install_githubModel(model, force=force, edit_script=edit_script)
        else:
            raise Exception("Model "+model+" is not available.")


############################ Designs #################################

from .inst.Funz.Funz import _jclassFunz
from .inst.Funz.Funz import _JArrayToPArray
def installedDesigns():
    """ Get available Funz Designs
    @return array of available Designs in Funz environment.
    @export
    @examples
    installedDesigns()
    """
    return(_JArrayToPArray(_jclassFunz.getDesignList()))

def availableDesigns(refresh_repo = False):
    """ List available designs from Funz GitHub repository
    @param refresh_repo should we force refreshing GitHub Funz repositories content ?
    @return array of available designs
    @export
    @examples
    availableDesigns()
    """
    global _github_repos
    if refresh_repo or (_github_repos is None):
        _github_repos = requests.get(f"https://api.github.com/orgs/Funz/repos?per_page=100", headers={}, params={}).json()
    if len(_github_repos)<=1:
        _github_repos = None
    
    if _github_repos is None:
        warnings.warn("Failed to acces GitHub Funz repo: "+str(requests.get(f"https://api.github.com/orgs/Funz/repos", headers={}, params={})))
        return(None)
    
    l = lambda r: re.sub("algorithm-","",r['name'])
    return( [l(r) for r in _github_repos  if 'name' in r.keys() and re.subn("algorithm-","",r['name'])[1]>0] )

import zipfile
from .inst.Funz import Funz
def install_fileDesign(design_zip, force=False):
    """ Install Funz design plugin from local zip file.
    @param design_zip zip file of algorithm. Usually algorithm-XYZ.zip
    @param force if already installed, reinstall.
    @param ... optional parameters to pass to unzip()
    @export
    @examples
    \dontrun{
    install_fileDesign('algorithm-GradientDescent_zip')
    }
    """
    design=re.sub(".zip(.*)","",re.sub("(.*)algorithm-","",design_zip))
    if design in installedDesigns():
        if not force:
            warnings.warn("Design "+design+" was already installed. Skipping new installation.")
            return(None)
        else:
            print("Design "+design+" was already installed. Forcing new installation...")
    
    with zipfile.ZipFile(design_zip, 'r') as zip_ref:
        zip_ref.extractall(FUNZ_HOME)
    
    # reload plugins in Funz env
    _jclassFunz.init()
    Funz._Funz_Designs = installedDesigns()

    if not (design in installedDesigns()):
        raise Exception("Could not install design "+design+" from "+design_zip)
    else:
        print("Installed Funz design "+design)

import tempfile, importlib, importlib.metadata
def install_githubDesign(design,force=False):
    """ Install Funz design plugin from central GitHub repository.
    @param design design to install.
    @param force if already installed, reinstall.
    @export
    @examples
    \dontrun{
    install_githubDesign('GradientDescent')
    }
    """
    major = re.sub(".post(.*)","",importlib.metadata.version('Funz'))
    design_zip = os.path.join(tempfile.gettempdir(),"algorithm-"+design+".zip")
    for minor in range(11)[::-1]:
        print(".", end = '')
        z = requests.get(_github_release("algorithm",design,major,str(minor)))
        if z.ok:
            with open(design_zip, "wb") as f:
                f.write(z.content)
            break
    
    if not z.ok: raise Exception("Could not download design "+design)
    
    install_fileDesign(design_zip=design_zip, force=force)

def installDesign(design,force=False):
    """ Install Funz design from local file or GitHub central repository
    @param design design to install.
    @param force if already installed, reinstall.
    @export
    @examples
    \dontrun{
    installDesign('GradientDescent')
    }
    """
    if os.path.isfile(design):
        install_fileDesign(design_zip=design, force=force)
    else:
        if design in availableDesigns():
            install_githubDesign(design, force=force)
        else:
            raise Exception("Model "+design+" is not available.")
