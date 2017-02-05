@echo off
if exist npl_packages pause
if not exist npl_packages mkdir npl_packages
cd npl_packages
if exist main goto _mainUpdate
if not exist main goto _main
if exist paracraft goto _paracraftUpdate
if not exist paracraft goto _paracraft

:_main
rem You can replace the url with your forked url
git clone https://github.com/NPLPackages/main

:_mainUpdate
pushd main
git pull
popd

:_paracraft
rem You can replace the url with your forked url
git clone https://github.com/NPLPackages/paracraft

:_paracraftUpdate
pushd paracraft
git pull
popd

