@echo off
@rem ---------------------------------------------------
@rem npl command line
@rem author: chenqh
@rem email: placeintime.qh@gmail.com
@rem ---------------------------------------------------
@rem usage:
@rem nplc ==# open npl console
@rem nplc sum.npl 1 2 ==# load sum.npl and call the run function with params 1 2
@rem ---------------------------------------------------

setlocal
set binder=+
set options=%1
shift

:loop
if "%1"=="" goto run_npl
set options=%options%%binder%%1
shift
goto loop

:run_npl

npl bootstrapper="(gl)script/ide/System/nplcmd/cmd.npl" i="true" servermode="true" nplcmd=%options% cmd_path=%cd%

endlocal
