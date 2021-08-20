## This file holds the R wrapper using the Funz API.
## It allows Funz to be used directly from R.
## Funz_Run(...) to launch remote calculations (providing input files + code name).
## Funz_Design(...) to call Funz DoE plugin.
## Funz_RunDesign(...) to call Funz DoE plugin over remote calculations.
##
## License: BSD
## Author: Y. Richet

################################# Imports ######################################

if (!("rJava" %in% utils::installed.packages()))
    stop("rJava package must be installed.")

if (!require(rJava)) {
    if (Sys.info()[['sysname']]=="Windows") system("echo JAVA_HOME=%JAVA_HOME%") else system("echo JAVA_HOME=$JAVA_HOME")
    stop("rJava package is required.")
}

rJava.version = utils::packageDescription('rJava')$Version
if (utils::compareVersion(rJava.version, "0.9-0") < 0)
    stop(paste("rJava version (",rJava.version,") is too old. Please update to >0.9"))


################################# .Internals ######################################

options(OutDec= ".")

#' Java class shortcuts
.JNI.Void = "V"
.JNI.boolean = "Z"
.Object = "java/lang/Object"
.JNI.Object = "Ljava/lang/Object;"
.File = "java/io/File"
.JNI.File.array = "[Ljava/io/File;"
.String = "java/lang/String"
.JNI.String = "Ljava/lang/String;"
.JNI.String.array = "[Ljava/lang/String;"
.Map = "java/util/Map"
.JNI.Map = "Ljava/util/Map;"

.asJObject <- function(string) {
    if(is.na(string)) return(NA)
    jo <- NULL
    try(jo <- .jclassData$asObject(string),silent=TRUE)
    if (is.jnull(jo)) return(NULL)
    array <- NULL
    try(array <- .jevalArray(jo),silent=TRUE)
    if (!is.null(array)) return(array)
    else return(jo)
}

#' @test .RFileArrayToJFileArray(c(".","./Funz.R","Funz.py"))
.RFileArrayToJFileArray <- function(files) {
    jlist.files = c()
    for (i in files) {
        if (.is.absolute(i))
            files.i = i
        else
            files.i = file.path(getwd(),i)
        jfiles.i = new(.jclassFile,files.i)
        found = jfiles.i$isFile() | jfiles.i$isDirectory()
        if (!found)
            stop(paste("File/dir ",files.i," not found.",sep=""))
        jlist.files = c(jlist.files,jfiles.i)
    }
    return(.jcastToArray(.jarray(jlist.files),signature=.JNI.File.array))
}

#' @test m = new(.jclassHashMap);m$put("a","b");.JMapToRDataFrame(m)
#' @test m = new(.jclassHashMap);m$put("a",.jclassData$asObject("[0,1,2,3]"));.JMapToRDataFrame(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(c(.jcast(new(J("java/lang/Double"),0.5)),.jcast(new(J("java/lang/Double"),0.6)))));m$put("aa",.jarray(c(.jcast(new(J("java/lang/Double"),0.55)),.jcast(new(J("java/lang/Double"),0.56)))));.JMapToRDataFrame(m)
.JMapToRDataFrame <- function(x,...){
    l = list()
    if (is.null(x)) return(l)
    vars = .jclassData$keys(x)
    for (v in vars) {
        l[[v]] = x$get(v)
        if (!is.null(l[[v]]) && !is.jnull(l[[v]]))
            if (inherits(x$get(v), "jobjRef") && x$get(v)$getClass()$isArray())
                l[[v]] = unlist(lapply(x$get(v),.jsimplify))
    }
    return(as.data.frame(l,...))
}

#' @test m = new(.jclassHashMap);m$put("a","b");.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",NULL);.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jnull());.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(c(.jnull(),.jnull())));.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(c(.jnew("java/lang/Double",1),.jnull(),.jnull())));.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",NULL);.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jnew("java.lang.Double",3));.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(runif(10)));.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(c(.jarray(runif(10)),.jarray(runif(10)))));.JMapToRList(m)
#' @test m = new(.jclassHashMap);m$put("a",.jarray(c(.jarray("abc"),.jarray("def"))));.JMapToRList(m)
.JMapToRList <- function(m){
    l = list()
    if (is.null(m)) return(l)
    vars = .jclassData$keys(m)
    for (v in vars) {
        vals = m$get(v)
        try(vals <- .jevalArray( m$get(v),simplify=T),silent=T)
        if (is.null(vals)) {
            l[[v]] = NA
        } else if (all(unlist(lapply(FUN = is.null,vals)))) {
            l[[v]] = rep(NA,length(vals))
        } else if( is.jnull(vals)) {
            l[[v]] = NA
        } else if( all(unlist(lapply(FUN = is.jnull,vals)))) {
            l[[v]] = rep(NA,length(vals))
        } else {
            if (is.character(vals) | is.numeric(vals)) {
                l[[v]] = vals
            } else {
                val = list()
                if (length(vals)>0) {
                    for (i in 1:length(vals)) {
                        if (is.null(vals[[i]]))
                            val[[i]] = NA
                        else
                            val[[i]] = vals[[i]]

                        # if (length(val)>=i) {
                            try(val[[i]] <- .jevalArray( vals[[i]],simplify=T),silent=T)

                            if (is.list(val[[i]])) {
                                try(val[[i]] <- lapply(FUN=.jevalArray,val[[i]]),silent=T)
                            }

                            if (length(val)<i || is.null(val[[i]]) || !is.vector(val[[i]])) {
                                try(val[[i]] <- .jsimplify(.jclassData$asObject(vals[[i]])),silent=T)
                            }
                            if (length(val)<i || is.null(val[[i]]) || !is.vector(val[[i]])) {
                                try(val[[i]] <- .jsimplify(vals[[i]]),silent=T) #.jsimplify(vals[[i]]$toString())
                            }
                            if (length(val)<i || is.null(val[[i]]) || !is.vector(val[[i]])) {
                                try(val[[i]] <- .jsimplify(.jclassData$asString(vals[[i]])),silent=T) #.jsimplify(vals[[i]]$toString())
                            }
                            if (length(val)<i || is.null(val[[i]])) { # Anyway, do not allow to push a NULL in the list (it will remove the element)
                                try(val[[i]] <- NA,silent=T)
                            }
                        # }
                    }
                }
                l[[v]] = val
            }
            #try(l[[v]] <- .jclassData$asObject(l[[v]]),silent=TRUE)
        }
    }
    return(l)
}

#' @test .RListToJArrayMap(list(a=1,b=2))
#' @test .RListToJArrayMap(list(a="abc",b="cde"))
#' @test .RListToJArrayMap(list(a=c(1,2),b=1))
#' @test .RListToJArrayMap(list(a=c(1,2),b=1))
#' @test .RListToJArrayMap(list(a="[1,2]",b=c(1,2)))
#' @test .RListToJArrayMap(list(b=c(1,2),c="abc"))
#' @test .RListToJArrayMap(list(a="[1,2]",g=list(b=c(1,2),c="abc")))
.RListToJArrayMap <- function(l){
    m = new(.jclassHashMap)
    if (is.null(l)) return(m)
    vars = names(l)
    for (v in vars) {
        val = l[[v]]
        if (is.null(val))
            m$put(new(J(.String),v),.jnull())
        else if (is.list(val))
            m$put(new(J(.String),v),.RListToJArrayMap(val))
        else
            m$put(new(J(.String),v),.jarray(val))
    }
    return(m)
}

#' @test .RListToJStringMap(list(a=1,b=2))
#' @test .RListToJStringMap(list(a="abc",b="cde"))
#' @test .RListToJStringMap(list(a=c(1,2),b=1))
#' @test .RListToJStringMap(list(a="[1,2]",b=c(1,2)))
#' @test .RListToJStringMap(list(b=c(1,2),c="abc"))
#' @test .RListToJStringMap(list(a="[1,2]",g=list(b=c(1,2),c="abc")))
.RListToJStringMap <- function(l){
    m = new(.jclassHashMap)
    if (is.null(l)) return(m)
    vars = names(l)
    for (v in vars) {
        val = l[[v]]
        if (is.null(val))
            m$put(new(J(.String),v),.jnull())
        else if (is.list(val))
            m$put(new(J(.String),v),.RListToJStringMap(val))
        else if (is.vector(val) && length(val)>1)
            m$put(new(J(.String),v),.jarray(paste(val)))
        else
            m$put(new(J(.String),v),paste(val))
        #else if (is.character(val))
        #    m$put(new(J(.String),v),J(.jclassData,"asObject",new(J(.String),val),simplify=F))
        #else
        #    m$put(new(J(.String),v),J(.jclassData,"asObject",new(J(.String),paste(val)),simplify=F))
    }
    return(m)
}

#' @test .RVectorToJArray(1)
#' @test .RVectorToJArray(c(1,2,3))
.RVectorToJArray <- function(y) {
    if (is.null(y) | length(y)==0)
        return(.jcastToArray(.jnull()))

    .jcastToArray(y)
}

#' @test .RVectorToJStringArray(1)
#' @test .RVectorToJStringArray(c(1,2,3))
.RVectorToJStringArray <- function(y) {
    if (is.null(y) | length(y)==0)
        return(.jcastToArray(""))#.jcast(.jarray(.jnew(class=.String,"")),new.class=.JNI.String.array, convert.array =TRUE))

    .jcastToArray(as.character(y))
}

#' @test .JStringArrayToRVector(.RVectorToJStringArray(1))
#' @test .JStringArrayToRVector(.RVectorToJStringArray(c(1,2,3)))
.JStringArrayToRVector <- function(string.array) {
    l = c()
    if (is.null(string.array)) return(l)
    if (length(string.array)>0)
        for (i in 1:length(string.array)) {
            if (is.character(string.array[[i]]))
                l = c(l,as.numeric(string.array[[i]]))
            else
                l = c(l,as.numeric(string.array[[i]]$toString()))
        }
    return(l)
}

.jdelete <- function(jo){
    .jclassUtils$delete(.jcast(jo,new.class=.Object))
}

.is.absolute <- function(pathname) {
    path = unlist(strsplit(pathname, "[/\\]"))
    !(length(path) == 0) && (path[1] == "" || regexpr("^.:$", path[1]) != -1);
}

.rightpad <- function(txt,n) {
    paste0(txt,paste0(collapse='',rep(" ",max(0,n-nchar(txt)))))
}

##################################### Init ###################################
.dir = ""
if (exists("FUNZ_HOME")) .dir=FUNZ_HOME
if (.dir=="") .dir = Sys.getenv("FUNZ_HOME") # if not set, returns ""
if (.dir=="") try(.dir <- dirname(sys.frame(1)$ofile),silent=T) # Try to detect directory of this script
if (.dir=="") .dir=NULL

#' Initialize Funz environment.
#' @param FUNZ_HOME set to Funz installation path.
#' @param verbosity verbosity of Funz workbench.
#' @param verbose.level deprecated verbosity
#' @param java.control list of JVM startup parameters (like -D...=...).
#' @param ... optional parameters passed to '.jinit' call.
#' @example Funz.init()
Funz.init <- function(FUNZ_HOME=.dir, java.control=if (Sys.info()[['sysname']]=="Windows") list(Xmx="512m",Xss="256k") else list(Xmx="512m"), verbose.level=0, verbosity=verbose.level, ...) {
    if (is.null(FUNZ_HOME))
        stop("FUNZ_HOME environment variable not set.\nPlease setup FUNZ_HOME to your Funz installation path.")

    .FUNZ_HOME <<- normalizePath(FUNZ_HOME)

    if (!file.exists(.FUNZ_HOME))
        stop(paste("FUNZ_HOME environment variable not correctly set: FUNZ_HOME=",FUNZ_HOME,"\nPlease setup FUNZ_HOME to your Funz installation path.\n(you can get Funz freely at https://funz.github.io/)",sep=""))

    parameters = c(paste("-Dapp.home",.FUNZ_HOME,sep="="),"-Duser.language=en","-Duser.country=US",paste(sep="","-Dverbosity=",verbosity)) #,"-Douterr=.Funz")
    for (p in names(java.control)) {
        if(substr(p,1,1)=="X") parameters = c(parameters,paste("-",p,java.control[[p]],sep=""))
        else parameters = c(parameters,paste("-D",p,"=",java.control[[p]],sep=""))
    }
    parameters = c(parameters,"-Djava.awt.headless=true") #,'-Dnashorn.args="--no-deprecation-warning"')

    if (verbosity>3) cat(paste0("  Initializing JVM ...\n    ",paste0(parameters,collapse="\n    "),"\n"))
    .jinit(parameters=parameters, ...)

    if (Sys.getlocale("LC_NUMERIC")!="C") Sys.setlocale(category="LC_NUMERIC",locale="C") # otherwise, the locale may be changed by Java, so LC_NUMERIC is no longer "C"

    if (verbosity>3) cat("  Loading java/lang/System ...\n")
    .jclassSystem <<- J("java/lang/System")

    if (verbosity>3) cat(paste("Java ",.jclassSystem$getProperty("java.runtime.name"),"\n version ",.jclassSystem$getProperty("java.version"),"\n from path ",.jclassSystem$getProperty("java.home"),"\n",sep=""))

    for (f in list.files(file.path(.FUNZ_HOME,"lib"),pattern=".jar")) {
        if (verbosity>3) cat(" using",f,"\n")
        .jaddClassPath(path=file.path(.FUNZ_HOME,"lib",f))
    }

    if (verbosity>3) cat("  Loading org/funz/Constants ...\n")
    .jclassConstants <<- J("org/funz/Constants")

    # if (verbosity>0) cat(paste("Funz ",.jclassConstants$APP_VERSION," <build ",.jclassConstants$APP_BUILD_DATE,">\n",sep=""))

    if (verbosity>3) cat("  Loading org/funz/api/Funz_v1 ...\n")
    .jclassFunz <<- J("org/funz/api/Funz_v1")

    if (!is.null(verbosity)) .jclassFunz$setVerbosity(as.integer(verbosity))

    .Funz.Models <<- NULL
    .Funz.Designs <<- NULL

    if (verbosity>3) cat("  Initializing Funz...\n")
    .jclassFunz$init()

    .Funz.Models <<- .jclassFunz$getModelList()
    # if (verbosity>0) {cat("  Funz models (port ",.jclassFunz$POOL$getPort(),"):",paste(.Funz.Models),"\n")}
    .Funz.Designs <<- .jclassFunz$getDesignList()
    # if (verbosity>0) {cat("  Funz designs (engine ",.jclassFunz$MATH$getEngineName(),"):",paste(.Funz.Designs),"\n")}

    # pre-load some class objects from funz API
    .jclassData <<- J("org/funz/util/Data")
    .jclassFormat <<- J("org/funz/util/Format")
    .jclassUtils <<- J("org/funz/api/Utils")
    .jclassPrint <<- J("org/funz/api/Print")
    .jclassDesignShell <<- J("org/funz/api/DesignShell_v1")
    .jclassRunShell <<- J("org/funz/api/RunShell_v1")
    .jclassShell <<- J("org/funz/api/Shell_v1")

    .jclassLinkedHashMap <<- J("java/util/LinkedHashMap") # in order to guarantee order of keys
    .jclassHashMap <<- J("java/util/HashMap")

    .jclassFile <<- J("java/io/File")

    if (Sys.info()[['sysname']]!="Windows")
        .jSIGPIPE <<- J("org/funz/util/SignalCatcher")$install("PIPE",FALSE) # because R has problems to support SIGPIPE raised by java (may occur when some socket are closed not gracefully) on unix.
}


##################################### Design ###################################

#' Apply a design of experiments through Funz environment on a response surface.
#' @param design Design of Experiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
#' @param input.variables list of variables definition in a String (for instance x1="[-1,1]")
#' @param options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
#' @param fun response surface as a target (say objective when optimization) function of the DoE. This should include calls to Funz_Run() function.
#' @param fun.control$cache set to TRUE if you wish to search in previous evaluations of fun befaore launching a new experiment. Sometimes useful when design asks for same experiments many times. Always FALSE if fun is not repeatible.
#' @param fun.control$vectorize Set to "fun" (by default) if fun accepts nrows>1 input. Set to "foreach" if delegating to 'foreach' loop the parallelization of separate 'fun' calls (packages foreach required, and some Do* needs to be registered and started before, and shutdown after). Set to "parallel" if delegating to 'parallel' the parallelization of separate 'fun' calls. Set to FALSE or "apply" means apply() will be used for serial launch of experiments.
#' @param fun.control$vectorize.by set the number of parallel execution if fun.control$vectorize is set to "foreach" or "parallel". By default, set to the number of core of your computer (if known by R, otherwise set to 1).
#' @param fun.control$foreach.options optional parameters to pass to the foreach DoPar. Should include anything needed for 'fun' evaluation.
#' @param monitor.control$results.tmp list of design results to display at each batch. TRUE means "all", NULL/FALSE means "none".
#' @param archive.dir define an arbitrary output directory where results (log, images) are stored.
#' @param verbosity print (lot of) information while running.
#' @param verbose.level deprecated verbosity
#' @param ... optional parameters passed to 'fun'
#' @return list of results from this DoE.
#' @example Funz_Design(design = "GradientDescent", options = list(nmax=10),input.variables = list(x1="[0,1]",x2="[1,2]"), fun = function(X){abs(X$a*X$b)})
Funz_Design <- function(fun,design,options=NULL,input.variables,fun.control=list(cache=FALSE,vectorize="fun",vectorize.by=1,foreach.options=NULL),monitor.control=list(results.tmp=TRUE),archive.dir=NULL,verbose.level=0,verbosity=verbose.level,log.file=TRUE,...) {
    .Funz.Last.design <<- list(design=design,options=options,fun=fun,
                               input.variables=input.variables,
                               fun.control=fun.control,monitor.control=monitor.control,
                               archive.dir=archive.dir,verbosity=verbosity,log.file=log.file,optargs=list(...))

    if (is.null(design))
        stop(paste("Design 'design' must be specified.\n Available: ",.Funz.Designs))

    if (exists(".Funz.Designs"))
        if (!is.element(el=design,set=.Funz.Designs))
            stop(paste("Design",design,"is not available in this Funz workbench (",paste0(.Funz.Designs,collapse=","),")"))

    if (is.null(input.variables))
        stop(paste("Input variables 'input.variables' must be specified."))

    if (is.null(fun))
        stop(paste("Function 'fun' must be specified."))

    if (!is.null(fun.control$vectorize)) {
        if (fun.control$vectorize=="foreach") {
            if (!("foreach" %in% utils::installed.packages()))
                stop("foreach package is required.")
            if (!foreach::getDoParRegistered())
                stop("no foreach backend registered.")
        } else if (fun.control$vectorize=="parallel") {
            if (!("parallel" %in% utils::installed.packages()))
                stop("parallel package is required.")
        }
        if (is.null(fun.control$vectorize.by)) fun.control$vectorize.by=4
    }

    init = Funz_Design.init(design,options,input.variables,archive.dir,verbosity,log.file)
    X=init$X
    designshell=init$designshell

    designshell$setCacheExperiments(isTRUE(fun.control$cache))

    it = 1
    .Funz.done <<- FALSE;
    while (TRUE) {
        utils::flush.console()

        X = Funz_Design.next(designshell,X,fun,fun.control,verbosity,...)

        if (is.null(X)) break;

        if (!is.null(monitor.control$results.tmp)) {
            jresultstmp = designshell$loopDesign$getResultsTmp()
            if (!is.jnull(jresultstmp )) {
                resultstmp = .JMapToRList(jresultstmp )
                .Funz.Last.design$resultstmp <<- resultstmp
                if (verbosity>0) {
                    if (isTRUE(monitor.control$results.tmp))
                        for (i in names(resultstmp)) {
                            cat(i,paste("\n  ",resultstmp[[i]],"\n"))
                        }
                    else if (is.character(monitor.control$results.tmp))
                        for (i in monitor.control$results.tmp) {
                            cat(i,paste("\n  ",resultstmp[[i]],"\n"))
                        }
                }
            }
        }

        #cat(.jcall(designshell,JNI.String,"finishedExperimentsInformation"));
        if (verbosity>0) {
            cat(paste(it,"th iteration\n",sep=""))
            cat(designshell$loopDesign$nextExperimentsInformation());
        }
        it = it+1;
    }
    .Funz.done <<- TRUE

    return(Funz_Design.results(designshell))
}


#' Initialize a design of experiments through Funz environment.
#' @param design Design of Expetiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
#' @param input.variables list of variables definition in a String (for instance x1="[-1,1]")
#' @param options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
#' @param archive.dir define an arbitrary output directory where results (log, images) are stored.
#' @param verbosity print (lot of) information while running.
#' @return list of experiments to perform ("X"), and Java shell obejct.
Funz_Design.init <- function(design,options=NULL,input.variables,archive.dir=NULL,verbosity=0,log.file=TRUE) {
    if (!exists(".Funz.Last.design")) .Funz.Last.design <<- list()

    # Build input as a HashMap<String, String>
    jinput.variables <- new(.jclassLinkedHashMap,length(input.variables))
    for (key in names(input.variables)) {
        if (is.null(input.variables[[key]]))
            values = "[0,1]"
        else
            values = input.variables[[key]]
        jinput.variables$put(key, values)
    }

    # Set design options
    joptions <- new(.jclassHashMap,length(options))
    if(!is.null(options)) {
        for (key in names(options)) {
            joptions$put(key, paste(options[[key]]))
        }
    } else if (verbosity>0) {
        cat("Using default options\n")
    }

    # Let's instanciate the workbench
    designshell = new(.jclassDesignShell,.jnull(),design,jinput.variables,joptions)
    .Funz.Last.design$designshell <<- designshell
    designshell$setVerbosity(as.integer(verbosity))

    # If no output dir is provided, use current one
    if(is.null(archive.dir)) archive.dir = getwd()
    if (!.is.absolute(archive.dir)) archive.dir = file.path(getwd(),archive.dir)
    designshell$setArchiveDirectory(archive.dir)
    if (verbosity>0) {
        cat("Using archive directory: ")
        cat(archive.dir)
        cat("\n")
    }

    if (isTRUE(log.file)) {
        # Then redirect output/error streams in the archive dir
        designshell$redirectOutErr() # to keep log of in/err streams
    } else if (is.character(log.file)) {
        designshell$redirectOutErr(new(.jclassFile,log.file))
    }

    if(exists("joptions")) {
        designshell$setDesignOptions(joptions)
    }

    #if (verbosity>0) {
    #    cat(designshell$information())
    #    cat("\n")
    #}

    designshell$buildDesign()
    jX = designshell$loopDesign$initDesign()
    .Funz.Last.design$initDesign <<- jX
    if (verbosity>0) {
        cat("Initial design\n")
        cat(designshell$loopDesign$nextExperimentsInformation());
    }

    if (is.jnull(jX)) X = NULL else X = apply(.JMapToRDataFrame(jX),2,as.numeric)
    .Funz.Last.design$X <<- X

    return(list(X=X,designshell=designshell))
}


#' Continue a design of experiments through Funz environment on a response surface.
#' @param designshell Java shell object holding the design of expetiments.
#' @param fun response surface as a target (say objective when optimization) function of the DoE. This should include calls to Funz_Run() function.
#' @param fun.control$cache set to TRUE if you wish to search in previous evaluations of fun before launching a new experiment. Sometimes useful when design asks for same experiments many times. Always FALSE if fun is not repeatible.
#' @param fun.control$vectorize Set to "fun" (by default) if fun accepts nrows>1 data.frame input. Set to "foreach" if delegating to 'foreach' loop the parallelization of separate 'fun' calls (packages foreach required, and a DoPar needs to be registered and started before, and shutdown after). Set to "parallel" if delegating to 'parallel' the parallelization of separate 'fun' calls. Set to FALSE or "apply" means apply() will be used for serial launch of experiments.
#' @param fun.control$vectorize.by set the number of parallel execution if fun.control$vectorize is set to "foreach" or "parallel". By default, set to the number of core of your computer (if known by R, otherwise set to 4).
#' @param fun.control$foreach.options optional parameters to pass to foreach. Should include anything needed for 'fun' evaluation.
#' @param verbosity print (lot of) information while running.
#' @param ... optional parapeters passed to 'fun'
#' @return next experiments to perform in this DoE, NULL if the design is finished.
Funz_Design.next <- function(designshell,X,fun,fun.control=list(cache=FALSE,vectorize="fun",vectorize.by=1,foreach.options=NULL),verbosity=0,...) {
    if (!exists(".Funz.Last.design")) .Funz.Last.design <<- list()

    designshell$prj$addDesignCases(designshell$loopDesign$nextExperiments, designshell, as.integer(0))

    n = nrow(X)
    if(n>0) {
        if (is.null(fun.control$vectorize) || fun.control$vectorize==FALSE || fun.control$vectorize=="apply") {
            Y = apply(X=X,FUN=fun,MARGIN=1,...)
        } else if (fun.control$vectorize=="fun") {
            Y = fun(as.data.frame(X),...)
        } else if (fun.control$vectorize=="foreach") {
            if (!is.null(fun.control$foreach.options)) {
                Y = foreach::foreach(ix = 1:nrow(X), .combine = c, .options = fun.control$foreach.options) %dopar% fun(X[ix,],...)
            } else {
                Y = foreach::foreach(ix = 1:nrow(X), .combine = c) %dopar% fun(X[ix,],...)
            }
        } else if (fun.control$vectorize=="parallel") {
            Y <- array(unlist(parallel::mclapply(X=split(X, 1:nrow(X)),FUN=fun,mc.cores=fun.control$vectorize.by,...)))
        } else {
            stop(paste("fun.control$vectorize type '",fun.control$vectorize,"' not supported.",sep=""))
        }
    } else Y = c()

    f = list()
    f[[designshell$output]] = Y
    Y = f
    .Funz.Last.design$Y <<- Y

    if (is.null(Y$f) || length(Y$f) != n) stop(paste("Failed to evaluate 'fun' on experiment sample X: ",paste(Y$f,collapse = ",")))

    jX = NULL
    jX = designshell$loopDesign$nextDesign(.RListToJArrayMap(c(Y,as.list(as.data.frame(X)))))
    .Funz.Last.design$nextDesign <<- jX
    if (verbosity>0) {
        cat("Next design\n")
        cat(designshell$loopDesign$nextExperimentsInformation());
    }

    if (is.jnull(jX)) X = NULL else X = apply(.JMapToRDataFrame(jX),2,as.numeric)
    .Funz.Last.design$X <<- X

    return(X)
}


#' Analyze a design of experiments through Funz environment.
#' @param designshell Java shell object holding the design of expetiments.
#' @return HTML analysis of the DoE.
Funz_Design.results <- function(designshell) {
    if (!exists(".Funz.Last.design")) .Funz.Last.design <<- list()

    results = .JMapToRList(designshell$loopDesign$getResults())
    .Funz.Last.design$results <<- results

    experiments = designshell$loopDesign$finishedExperimentsMap()
    .Funz.Last.design$experiments <<- experiments

    results$design = .JMapToRDataFrame(experiments)

    .jdelete(designshell)

    return(results)
}


#' Convenience method giving information about a design available as Funz_Design() arg.
#' @return information about this design.
Funz_Design.info <- function(design, input.variables) {
    if (is.null(design))
        stop(paste("Design 'design' must be specified.\n Available: ",.Funz.Designs))

    if (exists(".Funz.Designs"))
        if (!is.element(el=design,set=.Funz.Designs))
            stop(paste("Design",design,"is not available in this Funz workbench."))

    # Build input as a HashMap<String, String>
    if (is.null(input.variables))
        stop(paste("Input variables 'input.variables' must be specified."))
    jinput.variables<-new(.jclassLinkedHashMap)
    for (key in names(input.variables)) {
        if (is.null(input.variables[[key]]))
            values = "[0,1]"
        else
            values = input.variables[[key]]
        jinput.variables$put(key, values)
    }

    # Let's instanciate the workbench
    designshell = new(.jclassDesignShell,design,jinput.variables)

    info = designshell$information()

    .jdelete(designshell)

    return(info)
}


##################################### Run ######################################

#' Call an external (to R) code wrapped through Funz environment.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files list of files to give as input for the code.
#' @param input.variables data.frame of input variable values. If more than one experiment (i.e. nrow >1), experiments will be launched simultaneously on the Funz grid.
#' @param all.combinations if FALSE, input.variables variables are grouped (default), else, if TRUE experiments are an expaanded grid of input.variables
#' @param output.expressions list of interest output from the code. Will become the names() of return list.
#' @param run.control$force.retry is number of retries before failure.
#' @param run.control$cache.dir setup array of directories to search inside before real launching calculations.
#' @param monitor.control$sleep delay time between two checks of results.
#' @param monitor.control$display.fun a function to display project cases status. Argument passed to is the data.frame of DoE state.
#' @param archive.dir define an arbitrary output directory where results (cases, csv files) are stored.
#' @param verbosity print (lot of) information while running.
#' @param verbose.level deprecated verbosity
#' @return list of array results from the code, arrays size being equal to input.variables arrays size.
#' @example Funz_Run(model = "R", input.files = file.path(FUNZ_HOME,"samples","branin.R"),input.variables = list(x1=runif(10), b=runif(10)), output.expressions = "z")
Funz_Run <- function(model=NULL,input.files,input.variables=NULL,all.combinations=FALSE,output.expressions=NULL,run.control=list(force.retry=2,cache.dir=NULL),archive.dir=NULL,verbose.level=0,verbosity=verbose.level,log.file=TRUE,monitor.control=list(sleep=5,display.fun=NULL)) {
    .Funz.Last.run <<- list(model=model,input.files=input.files,
                            input.variables=input.variables,output.expressions=output.expressions,
                            run.control=run.control,monitor.control=monitor.control,
                            archive.dir=archive.dir,verbosity=verbosity,log.file=log.file)

    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench (",paste0(.Funz.Models,collapse=","),")"))

    if (is.null(model)) {
        model <- ""
        if (verbosity>0) cat("Using default model.\n")
    }

    runshell = Funz_Run.start(model,input.files,input.variables,all.combinations,output.expressions,run.control,archive.dir,verbosity,log.file)

    #runshell$setRefreshingPeriod(.jlong(1000*monitor.control$sleep))

    finished = FALSE
    pointstatus = "-"
    new_pointstatus = "-"
    while(!finished) {
        utils::flush.console()

        tryCatch(expr={
        .Funz.done <<- FALSE;
        Sys.sleep(monitor.control$sleep)
        state = runshell$getState()
        if (grepl("Failed!",state))
            stop(paste0(sep="","Run failed:\n", .jclassFormat$ArrayMapToMDString(runshell$getResultsArrayMap())))

        finished = (grepl("Over.",state) | grepl("Failed!",state) | grepl("Exception!!",state))

        if (verbosity>0) cat(paste("\r",.rightpad(gsub("\n"," | ",state),80)))

        if (is.function(monitor.control$display.fun)) {
            new_pointstatus = runshell$getCalculationPointsStatus()
            if (new_pointstatus!=pointstatus){
                monitor.control$display.fun(.JMapToRList(new_pointstatus))
                pointstatus=new_pointstatus
            }
        }
        .Funz.done <<- TRUE
        }, interrupt = function(i) {
            if (verbosity>0) cat("Interrupt !\n")
            runshell$stopComputation()
        }
        #,finally={
        # if(!.Funz.done) {
        #    cat("Terminating run...")
        #    runshell$shutdown()
        #    cat(" ok.\n")
        #  }
        #}
        )
    }

    results = Funz_Run.results(runshell,verbosity)

    try(runshell$shutdown(),silent=TRUE)
    .jdelete(runshell)

    return(results)
}


#' Initialize a Funz shell to perform calls to an external code.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files list of files to give as input for the code.
#' @param input.variables data.frame of input variable values. If more than one experiment (i.e. nrow >1), experiments will be launched simultaneously on the Funz grid.
#' @param all.combinations if FALSE, input.variables variables are grouped (default), else, if TRUE experiments are an expanded grid of input.variables
#' @param output.expressions list of interest output from the code. Will become the names() of return list.
#' @param run.control$force.retry is number of retries before failure.
#' @param run.control$cache.dir setup array of directories to search inside before real launching calculations.
#' @param archive.dir define an arbitrary output directory where results (cases, csv files) are stored.
#' @param verbosity print (lot of) information while running.
#' @return a Java shell object, which calculations are started.
Funz_Run.start <- function(model,input.files,input.variables=NULL,all.combinations=FALSE,output.expressions=NULL,run.control=list(force.retry=2,cache.dir=NULL),archive.dir=NULL,verbosity=0,log.file=TRUE) {
    if (!exists(".Funz.Last.run")) .Funz.Last.run <<- list()

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    # First, process the input design, because if it includes a call to Funz itself (compisition of Funz functions), it will lock Funz as long as nothing is returned.
    if(!is.null(input.variables)) {
        if(!is.list(input.variables)) input.variables = as.list(input.variables)
        JMapinput.variables <- new(.jclassLinkedHashMap)
        for (key in names(input.variables)) {
            JMapinput.variables$put(key, .RVectorToJStringArray(input.variables[[key]]))
        }
    } else if (verbosity>0) cat("Using default input design.\n")

    # Let's instanciate the workbench
    if (exists(".Funz.Last.run")) if(!is.jnull(.Funz.Last.run$runshell)) {
        if (verbosity>0) cat("Terminating previous run...")
        try(.Funz.Last.run$runshell$shutdown(),silent=TRUE)
        if (verbosity>0) cat(" ok.\n")
    }
    runshell <- .jnew("org/funz/api/RunShell_v1",model,.jcast(JArrayinput.files,new.class=.JNI.File.array),.jcastToArray("",.JNI.String.array)) #new(.jclassRunShell,model,JArrayinput.files)
    runshell$setVerbosity(as.integer(verbosity))
    .Funz.Last.run$runshell <<- runshell
    #try(runshell$trap("INT")) # to not allow ctrl-c to stop whole JVM, just this runshell

    # Manage the output : if nothing is provided, use default one from plugin
    if(is.null(output.expressions)) {
        output.expressions = runshell$getOutputAvailable()
        if (verbosity>0) {
            cat("Using default output expressions: ")
            cat(output.expressions)
            cat("\n")
        }
    }
    runshell$setOutputExpressions(.jcastToArray(output.expressions,.JNI.String.array))
    .Funz.Last.run$output.expressions <<- output.expressions


    # If no output dir is provided, use current one
    if(is.null(archive.dir)) archive.dir = getwd()
    if (!.is.absolute(archive.dir)) archive.dir = file.path(getwd(),archive.dir)
    runshell$setArchiveDirectory(archive.dir)
    if (verbosity>0) {
        cat("Using archive directory: ")
        cat(archive.dir)
        cat("\n")
    }

    if (isTRUE(log.file)) {
        # Then redirect output/error streams in the archive dir
        runshell$redirectOutErr() # to keep log of in/err streams
    } else if (is.character(log.file)) {
        runshell$redirectOutErr(new(.jclassFile,log.file))
    }

    # Now, if input design was provided, use it. Instead, default parameters values will be used.
    if(exists("JMapinput.variables")) {
        if (!all.combinations)
            runshell$setInputVariablesGroup(".g",JMapinput.variables)
        else
            runshell$setInputVariables(JMapinput.variables)
    }

    # load project properties, retries, cacheDir, minCPU, ...
    for (rc in names(run.control)) {
        if (rc=="force.retry") # Set number of retries
            runshell$setProjectProperty("retries",as.character(run.control$force.retry))
        else if (rc=="cache.dir") {# Finally, adding cache if needed
            if(!is.null(run.control$cache.dir)) {
                for (dir in run.control$cache.dir) {
                    runshell$addCacheDirectory(.jnew(class=.File,dir))
                }
            }
        } else {
            runshell$setProjectProperty(rc,as.character(run.control[[rc]]))
        }
    }

    # Everything is ok. let's run calculations now !
    runshell$startComputation()

    return(runshell)
}


#' Parse a Java shell object to get its results.
#' @param runshell Java shell object to parse.
#' @param verbosity print (lot of) information while running.
#' @return list of array design and results from the code, arrays size being equal to input.variables arrays size.
Funz_Run.results <- function(runshell,verbosity) {
    if (!exists(".Funz.Last.run")) .Funz.Last.run <<- list()

    results <- .JMapToRList(runshell$getResultsArrayMap())
    .Funz.Last.run$results <<- results

    return(results)
}


#' Convenience test & information of Funz_Run model & input.
#' @return general information concerning this model/input combination.
Funz_Run.info <- function(model=NULL,input.files=NULL) {
    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench."))

    if (is.null(model)) {
        model <- ""
    }

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    # Let's instanciate the workbench
    shell = .jnew("org/funz/api/RunShell_v1",model,.jcast(JArrayinput.files,new.class=.JNI.File.array),.jcastToArray("",.JNI.String.array)) #new(.jclassRunShell,model,JArrayinput.files)

    # Get default variables & results from plugin
    info = .jclassPrint$projectInformation(shell)
    input = shell$getInputVariables()
    output = shell$getOutputAvailable()

    .jdelete(shell)

    return(list(info=info,input=input,output=output))
}


################################# Grid #################################

#' Convenience overview of Funz grid status.
#' @return String list of all visible Funz daemons running on the network.
Funz_GridStatus <- function() {
    utils::read.delim(textConnection(gsub("\t","",.jclassPrint$gridStatusInformation())),sep="|")[,2:10]
}


################################# Utils #################################

#' Convenience method to find variables & related info. in parametrized file.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files files to give as input for the code.
#' @return list of variables & their possible default value
#' @example Funz_ParseInput(model = "R", input.files = file.path(FUNZ_HOME,"samples","branin.R"))
Funz_ParseInput <- function(model,input.files) {
    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench (",paste0(.Funz.Models,collapse=","),")"))

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    .JMapToRList(.jcall(.jclassUtils,.JNI.Map,"findVariables",ifelse(is.null(model),"",model),.jcast(JArrayinput.files,.JNI.File.array)))
    #.JMapToRList(.jclassUtils$findVariables(model,.jcast(JArrayinput.files,new.class=.JNI.File.array)))
}

#' Convenience method to compile variables in parametrized file.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files files to give as input for the code.
#' @param input.values list of variable values to compile.
#' @param output.dir directory where to put compiled files.
#' @example Funz_CompileInput(model = "R", input.files = file.path(FUNZ_HOME,"samples","branin.R"),input.values = list(x1=0.5, b=0.6))
#' @example Funz_CompileInput(model = "R", input.files = file.path(FUNZ_HOME,"samples","branin.R"),input.values = list(x1=c(0.5,.55), b=c(0.6,.7)))
Funz_CompileInput <- function(model,input.files,input.values,output.dir=".") {
    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench (",paste0(.Funz.Models,collapse=","),")"))

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    # Process the input values
    JMapinput.values <- new(.jclassLinkedHashMap)
    for (key in names(input.values)) {
        JMapinput.values$put(key, as.character(input.values[[key]]))
    }

    if (!.is.absolute(output.dir)) output.dir = file.path(getwd(),output.dir)

    .jcall(.jclassUtils,.JNI.Void,"compileVariables",ifelse(is.null(model),"",model),.jcast(JArrayinput.files,new.class=.JNI.File.array),.jcast(JMapinput.values,.Map),new(.jclassFile,output.dir))
    #.jclassUtils$compileVariables(model,.jcast(JArrayinput.files,new.class=.JNI.File.array),JMapinput.values,new(.jclassFile,output.dir))
}

#' Convenience method to find variables & related info. in parametrized file.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files files given as input for the code.
#' @param output.dir directory where calculated files are.
#' @return list of outputs & their value
#' @example Funz_ReadOutput(model = "R", input.files = "branin.R",output.dir=".")
Funz_ReadOutput <- function(model, input.files, output.dir) {
    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench (",paste0(.Funz.Models,collapse=","),")"))

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    .JMapToRList(.jcall(.jclassUtils,.JNI.Map,"readOutputs",ifelse(is.null(model),"",model),.jcast(JArrayinput.files,.JNI.File.array),new(.jclassFile,output.dir)))
    #.JMapToRList(.jclassUtils$findVariables(model,.jcast(JArrayinput.files,new.class=.JNI.File.array)))
}


################################# Run & Design #################################

#' Call an external (to R) code wrapped through Funz environment.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files list of files to give as input for the code.
#' @param design Design of Experiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
#' @param design.options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
#' @param input.variables list of variables definition in a String (for instance x1="[-1,1]"), or array of fixed values (will launch a design for each combination).
#' @param output.expressions list of interest output from the code. Will become the names() of return list.
#' @param run.control$force.retry is number of retries before failure.
#' @param run.control$cache.dir setup array of directories to search inside before real launching calculations.
#' @param monitor.control$sleep delay time between two checks of results.
#' @param monitor.control$display.fun a function to display project cases status. Argument passed to is the data.frame of DoE state.
#' @param archive.dir define an arbitrary output directory where results (cases, csv files) are stored.
#' @param verbosity print (lot of) information while running.
#' @param verbose.level deprecated verbosity
#' @return list of array design and results from the code.
#' @example Funz_RunDesign(model="R", input.files=file.path(FUNZ_HOME,"samples","branin.R"), output.expressions="cat", design = "GradientDescent", design.options = list(nmax=5),input.variables = list(x1="[0,1]",x2="[0,1]"))
#' @example Funz_RunDesign(model="R", input.files=file.path(FUNZ_HOME,"samples","branin.R"), output.expressions="cat", design = "GradientDescent", design.options = list(nmax=5),input.variables = list(x1="[0,1]",x2=c(0,1)))
Funz_RunDesign <- function(model=NULL,input.files,design=NULL,design.options=NULL,input.variables=NULL,output.expressions=NULL,run.control=list(force.retry=2,cache.dir=NULL),monitor.control=list(results.tmp=TRUE,sleep=5,display.fun=NULL),archive.dir=NULL,verbosity=0,log.file=TRUE) {
    .Funz.Last.rundesign <<- list(model=model,input.files=input.files,
                                  design=design,design.options=design.options,
                                  input.variables=input.variables,output.expressions=output.expressions,
                                  monitor.control=monitor.control,run.control=run.control,
                                  archive.dir=archive.dir,verbosity=verbosity,log.file=log.file)

    if (exists(".Funz.Models"))
        if (!is.null(model) && (!is.element(el=model,set=.Funz.Models)))
            stop(paste("Model",model,"is not available in this Funz workbench (",paste0(.Funz.Models,collapse=","),")"))

    if (is.null(model)) {
        model <- ""
        if (verbosity>0) cat("Using default model.\n")
    }

    if (is.null(design))
        stop(paste("Design argument 'design' must be specified (",paste0(.Funz.Designs,collapse=","),")"))

    if (!is.null(design))
        if (exists(".Funz.Designs"))
            if (!is.element(el=design,set=.Funz.Designs))
                stop(paste("Design",design,"is not available in this Funz workbench (",paste0(.Funz.Designs,collapse=","),")"))

    if (is.null(input.variables))
        stop(paste("Input variables 'input.variables' must be specified."))

    shell = Funz_RunDesign.start(model,input.files,output.expressions,design,input.variables,design.options,run.control,archive.dir,verbosity,log.file)

    #shell$setRefreshingPeriod(.jlong(1000*monitor.control$sleep))

    finished = FALSE
    state=""
    status = "-"
    new_status = "-"
    while(!finished) {
        utils::flush.console()

        tryCatch(expr={
        .Funz.done <<- FALSE;
        Sys.sleep(monitor.control$sleep)
        state <- shell$getState()

        if (grepl("Failed!",state))
            stop(paste0(sep="","Run failed:\n", .jclassFormat$ArrayMapToMDString(shell$getResultsArrayMap())))

        finished = (grepl("Over.",state) | grepl("Failed!",state) | grepl("Exception!!",state))

        if (verbosity>0) cat(paste("\r",.rightpad(gsub("\n"," | ",state),80)))

        if (is.function(monitor.control$display.fun)) {
            new_status = shell$getCalculationPointsStatus()
            if (new_status!=status){
                monitor.control$display.fun(.JMapToRList(new_status))
                status=new_status
            }
        }
        .Funz.done <<- TRUE
        }, interrupt = function(i) {
            if (verbosity>0) cat("Interrupt !\n")
            shell$stopComputation()
        }#,finally={
        # if(!.Funz.done) {
        #    cat("Terminating run...")
        #    shell$shutdown()
        #    cat(" ok.\n")
        #  }
        #}
        )
    }

    Sys.sleep(1)
    results = Funz_RunDesign.results(shell,verbosity)

    #try(shell$shutdown(),silent=TRUE)
    #.jdelete(shell)

    return(results)
}

#' Initialize a Funz shell to perform calls to an external code.
#' @param model name of the code wrapper to use. See .Funz.Models global var for a list of possible values.
#' @param input.files list of files to give as input for the code.
#' @param design Design of Experiments (DoE) given by its name (for instance ""). See .Funz.Designs global var for a list of possible values.
#' @param design.options list of options to pass to the DoE. All options not given are set to their default values. Note that '_' char in names will be replaced by ' '.
#' @param input.variables list of variables definition in a String (for instance x1="[-1,1]"), or array of fixed values (will launch a design for each combination).
#' @param output.expressions list of interest output from the code. Will become the names() of return list.
#' @param run.control$force.retry is number of retries before failure.
#' @param run.control$cache.dir setup array of directories to search inside before real launching calculations.
#' @param archive.dir define an arbitrary output directory where results (cases, csv files) are stored.
#' @param verbosity print (lot of) information while running.
#' @param verbose.level deprecated verbosity
#' @return a Java shell object, which calculations are started.
#' @example Funz_RunDesign.start(model = "R", input.files = file.path(FUNZ_HOME,"samples","branin.R"),output.expressions = "z",design = "Conjugate Gradient",input.variables = list(x1=runif(10), b="[0,1]"),design.options = list(Maximum_iterations=10))
Funz_RunDesign.start <- function(model,input.files,output.expressions=NULL,design=NULL,input.variables=NULL,design.options=NULL,run.control=list(force.retry=2,cache.dir=NULL),archive.dir=NULL,verbosity=0,log.file=TRUE) {
    if (!exists(".Funz.Last.rundesign")) .Funz.Last.rundesign <<- list()

    # Check (and wrap to Java) input files.
    JArrayinput.files = .RFileArrayToJFileArray(input.files)

    # First, process the input design, because if it includes a call to Funz itself (compisition of Funz functions), it will lock Funz as long as nothing is returned.
    if(!is.null(input.variables)) {
        if(!is.list(input.variables)) input.variables = as.list(input.variables)
        JMapinput.variables <- .RListToJStringMap(input.variables)
    } else if (verbosity>0) cat("Using default input values.\n")

    if (is.null(design)) design="No design of experiments"
    # Set design options
    joptions <- new(.jclassHashMap)
    if(!is.null(design.options)) {
        for (key in names(design.options)) {
            joptions$put(key, paste(design.options[[key]]))
        }
    } else if (verbosity>0) {
        cat("Using default design options\n")
    }

    # Let's instanciate the workbench
    if (exists(".Funz.Last.rundesign")) if(!is.jnull(.Funz.Last.rundesign$shell)) {
        if (verbosity>0) cat("Terminating previous run...")
        try(.Funz.Last.rundesign$shell$shutdown(),silent=TRUE)
        if (verbosity>0) cat(" ok.\n")
    }
    shell <- .jnew("org/funz/api/Shell_v1",model,.jcast(JArrayinput.files,.JNI.File.array), .jnull(.String), design, .jcast(JMapinput.variables,new.class=.Map), .jcast(joptions,new.class=.Map)) #new(.jclassRunShell,model,JArrayinput.files)
    shell$setVerbosity(as.integer(verbosity))
    .Funz.Last.rundesign$shell <<- shell
    #try(shell$trap("INT")) # to not allow ctrl-c to stop whole JVM, just this runshell

    # Manage the output : if nothing is provided, use default one from plugin
    if(is.null(output.expressions)) {
        output.expressions = shell$getOutputAvailable()
        if (verbosity>0) {
            cat("Using default output expressions: ")
            cat(output.expressions)
            cat("\n")
        }
    }
    shell$setOutputExpression(output.expressions[1])
    .Funz.Last.rundesign$output.expressions <<- output.expressions

    # If no output dir is provided, use current one
    if(is.null(archive.dir)) archive.dir = getwd()
    if (!.is.absolute(archive.dir)) archive.dir = file.path(getwd(),archive.dir)
    shell$setArchiveDirectory(archive.dir)
    if (verbosity>0) {
        cat("Using archive directory: ")
        cat(archive.dir)
        cat("\n")
    }

    if (isTRUE(log.file)) {
        # Then redirect output/error streams in the archive dir
        shell$redirectOutErr() # to keep log of in/err streams
    } else if (is.character(log.file)) {
        shell$redirectOutErr(new(.jclassFile,log.file))
    }

    # load project properties, retries, cacheDir, minCPU, ...
    for (rc in names(run.control)) {
        if (rc=="force.retry") # Set number of retries
            shell$setProjectProperty("retries",as.character(run.control$force.retry))
        else if (rc=="cache.dir") {# Finally, adding cache if needed
            if(!is.null(run.control$cache.dir)) {
                for (dir in run.control$cache.dir) {
                    shell$addCacheDirectory(.jnew(class=.File,dir))
                }
            }
        } else {
            shell$setProjectProperty(rc,as.character(run.control[[rc]]))
        }
    }

    # Everything is ok. let's run calculations now !
    shell$startComputation()

    return(shell)
}

#' Parse a Java shell object to get its results.
#' @param shell Java shell object to parse.
#' @param verbosity print (lot of) information while running.
#' @return list of array design and results from the code.
#' @example TODO
Funz_RunDesign.results <- function(shell,verbosity) {
    if (!exists(".Funz.Last.rundesign")) .Funz.Last.rundesign <<- list()

    results <- .JMapToRList(shell$getResultsArrayMap())
    for (io in c(names(.Funz.Last.rundesign$input.variables),.Funz.Last.rundesign$output.expressions)) # Try to cast I/O values to R numeric
        for (i in 1:length(results[[io]]))
            results[[io]][[i]] = lapply(unlist(results[[io]][[i]]),.jsimplify)
    .Funz.Last.rundesign$results <<- results

    return(results)
}
