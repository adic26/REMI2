Imports System.ServiceProcess

<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class REMIBatchTasks
    Inherits System.ServiceProcess.ServiceBase

    'UserService overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    ' The main entry point for the process
    <MTAThread()> _
    <System.Diagnostics.DebuggerNonUserCode()> _
    Shared Sub Main()
        Dim ServicesToRun() As System.ServiceProcess.ServiceBase

        ' More than one NT Service may run within the same process. To add
        ' another service to this process, change the following line to
        ' create a second service object. For example,
        '
        '   ServicesToRun = New System.ServiceProcess.ServiceBase () {New Service1, New MySecondUserService}
        '
        ServicesToRun = New System.ServiceProcess.ServiceBase() {New REMIBatchTasks}
        AddHandler AppDomain.CurrentDomain.UnhandledException, AddressOf uhException
        System.ServiceProcess.ServiceBase.Run(ServicesToRun)
    End Sub
    Public Shared Sub uhException(ByVal sender As Object, ByVal e As UnhandledExceptionEventArgs)
        Dim ex As Exception = DirectCast(e.ExceptionObject, Exception)
        remi.GetInstance.SendMail("reliabilityinfrastructure@blackberry.com", "remiTimedService@blackberry.com", "unhandled exception!", ex.Message + Environment.NewLine + ex.StackTrace)

    End Sub
    'Required by the Component Designer
    Private components As System.ComponentModel.IContainer

    ' NOTE: The following procedure is required by the Component Designer
    ' It can be modified using the Component Designer.  
    ' Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        components = New System.ComponentModel.Container()
        Me.ServiceName = "Service1"
    End Sub

End Class
