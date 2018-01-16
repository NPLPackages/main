#!/bin/bash
#---------------------------------------------------
# npl command line
# author: chenqh
# email: placeintime.qh@gmail.com
#---------------------------------------------------
# usage:
# nplc => open npl console
# nplc sum.npl 1 2 => load sum.npl and call the run function with params 1 2
#---------------------------------------------------

if [ $1 ] && ([ $1 == "-D" ] || [ $1 == "-d" ]); then
    option = $1
    shift
fi

function join { local IFS="$1"; shift; echo "$*"; }

binder="+"

options=$(join $binder $*)

if [ ! -d $HOME/.nplc ]; then
    mkdir $HOME/.nplc
fi

if [ ! -d $HOME/.nplc/log ]; then
    mkdir $HOME/.nplc/log
fi

npl $option bootstrapper="(gl)script/ide/System/nplcmd/cmd.npl" i="true" servermode="true" nplcmd="$options" cmd_path="$PWD" logfile="$HOME/.nplc/log/cmd.log"
