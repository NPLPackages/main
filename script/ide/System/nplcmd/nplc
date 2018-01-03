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

function join { local IFS="$1"; shift; echo "$*"; }

binder="+"

options=$(join $binder $*)

npl bootstrapper="(gl)script/ide/System/nplcmd/cmd.npl" i="true" servermode="true" nplcmd="$options"
