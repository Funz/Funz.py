#!/bin/bash

FUNZ_PATH="$( cd "$(dirname "$0")" ; pwd -P )" #absolute `dirname $0`

_complete_Funz() 
{
    local cur prev opts
    COMPREPLY=()
    #first="${COMP_WORDS[1]}" Should be used to use only suitable opts according to COMMAND used
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmds="Run Design RunDesign ParseInput CompileInput ReadOutput GridStatus"
    opts_long="--help --design --model --archive_dir --help --function --run_control --print --input_variables --function_args --input_files --monitor_control --function_parallel --design_options --print_filter --output_expression --verbosity"
    #opts_short="-h -d -m -ad -h -f -rc -p -iv -fa -if -mc -fp -do -pf -oe -v"

    if [[ ${prev} == *Funz.sh ]] ; then
        COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
        return 0
    fi
    if [[ ${prev} == funz ]] ; then
        COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
        return 0
    fi
    if [[ ${cur} == --* ]]  ; then
        COMPREPLY=( $(compgen -W "${opts_long}" -- ${cur}) )
        return 0
    fi
    #if [[ ${cur} == -* ]] ; then
    #    COMPREPLY=( $(compgen -W "${opts_short}" -- ${cur}) )
    #    return 0
    #fi
}
export -f _complete_Funz
alias funz='$FUNZ_PATH/Funz.sh'
complete -F _complete_Funz funz
complete -F _complete_Funz Funz.sh
complete -F _complete_Funz ./Funz.sh
complete -F _complete_Funz $FUNZ_PATH/Funz.sh