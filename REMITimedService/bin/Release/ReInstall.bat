REM *** Used to reinstall the windows service. Must be in the same directory as the service
REM *** Darragh O'Riordan RIM May 2010

@ECHO OFF

Echo Uninstalling old service...
c:\windows\Microsoft.NET\framework\v2.0.50727\InstallUtil.exe /u remitimedservice.exe
Echo Old service uninstalled
Echo Installing new service...
c:\windows\Microsoft.NET\framework\v2.0.50727\InstallUtil.exe remitimedservice.exe
Echo New service installed.
sc start remitimedservice