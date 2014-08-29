Imports System.ComponentModel
Imports System.Configuration.Install

Public Class ProjectInstaller

    Public Sub New()
        MyBase.New()

        'This call is required by the Component Designer.
        InitializeComponent()

        'Add initialization code after the call to InitializeComponent

    End Sub

  
    Private Sub mainServiceProcessInstaller_AfterInstall(ByVal sender As System.Object, ByVal e As System.Configuration.Install.InstallEventArgs) Handles mainServiceProcessInstaller.AfterInstall

    End Sub

    Private Sub mainServiceInstaller_AfterInstall(ByVal sender As System.Object, ByVal e As System.Configuration.Install.InstallEventArgs) Handles mainServiceInstaller.AfterInstall

    End Sub
End Class
