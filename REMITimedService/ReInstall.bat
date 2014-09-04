@ECHO OFF

Echo Uninstalling old service...
c:\windows\Microsoft.NET\framework\v4.0.30319\InstallUtil.exe /u remitimedservice.exe
Echo Old service uninstalled
Echo Installing new service...
c:\windows\Microsoft.NET\framework\v4.0.30319\InstallUtil.exe remitimedservice.exe
Echo New service installed.
sc start remitimedservice