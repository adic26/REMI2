Imports System.Timers
Imports System.Net.Mail
Imports System.Diagnostics
Imports System.Threading
Imports System.Configuration

Public Class REMIBatchTasks
    Inherits System.ServiceProcess.ServiceBase

    Private Shared _runTimedThreadFlag As Boolean ' used to control the thread spawned by the service to run tasks
    Private Shared _runNotAssigned As Boolean = True
    Private Shared _dontRun As Boolean = True
    Private Shared _syncCount As Int32 = 0
    Private _sendSuccessEmails As Boolean
    Private _sendNotAssignedEmails As Boolean
    Private Shared _configIntervalMinutes As Integer = My.MySettings.Default.IntervalMinutes

    Public Sub New()
        InitializeComponent()
    End Sub

    Protected Overrides Sub OnStart(ByVal args() As String)
        _runTimedThreadFlag = True
        Dim t As Thread = New Thread(New ThreadStart(AddressOf TimedLoop))
        t.Start()
    End Sub

    Private Sub TimedLoop()
        _runNotAssigned = True
        Dim dayOfWeek As DayOfWeek = DateTime.Now.DayOfWeek

        While _runTimedThreadFlag
            Dim dateValue As Date = DateTime.Now

            If ((dateValue.Hour >= 3 And dateValue.Hour <= 6) Or (dateValue.Hour >= 19 And dateValue.Hour <= 23)) Then 'Don't synce between 3 AM and 6 AM or between 7 and 11
                _dontRun = True
            Else
                _dontRun = False
            End If

            If (dayOfWeek <> dateValue.DayOfWeek) Then
                _runNotAssigned = True
                dayOfWeek = dateValue.DayOfWeek
            End If

            If (Not (_dontRun)) Then
                RunTasks(_runNotAssigned)
            End If

            _runNotAssigned = False
            'Don't set the time here. Use the config interval above!
            Thread.Sleep(_configIntervalMinutes * 60000)
        End While

        SendMail("Remi Timed Task Stopping.", "Auto Message")
    End Sub

    Protected Overrides Sub OnStop()
        _runTimedThreadFlag = False
    End Sub

    Private Shared Sub SendMail(ByVal subject As String, ByVal message As String)
        Try
            remi.GetInstance.SendMail(ConfigurationManager.AppSettings("DestinationEmails").ToString(), ConfigurationManager.AppSettings("FromEmail").ToString(), subject, message)
        Catch ex As Exception
            _runTimedThreadFlag = False
            Throw
        End Try
    End Sub

    ''' <summary>
    ''' This is a list of the tasks that are run
    ''' </summary>
    ''' <remarks></remarks>
    Private Sub RunTasks(ByVal runNotAssigned As Boolean)
        Dim sb As New System.Text.StringBuilder
        Dim currentQRA As String = String.Empty
        Try
            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - Check Interval: {1}", DateTime.Now, _configIntervalMinutes.ToString()))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, My.MySettings.Default.REMITimedService_RemiAPI_RemiAPI))
            sb.AppendLine(DateTime.Now + " - Batch check starting...")
            sb.AppendLine(DateTime.Now + " - Retrieving Active Jobs...")

            Dim batches As String() = remi.GetInstance.GetActiveBatchList
            Dim dtDepartments As DataTable = remi.GetInstance.GetLookups(RemiAPI.LookupType.Department)

            For Each department As DataRow In dtDepartments.Rows.Cast(Of DataRow)()
                If (department.Field(Of String)("LookupType").ToString() <> "All Test Centers") Then
                    Try
                        sb.AppendLine(String.Format("{0} - Retrieving TRS Batches For {1}...", DateTime.Now, department.Field(Of String)("LookupType").ToString()))
                        batches.Concat((From r As DataRow In remi.GetInstance.GetRequestsNotInREMI(department.Field(Of String)("LookupType").ToString()) Select r.Field(Of String)("RequestNumber")).ToList())
                    Catch ex As Exception
                        sb.AppendLine(String.Format("{0} - Error Retrieving Request Batches For {1}...", DateTime.Now, department.Field(Of String)("LookupType").ToString()))
                    End Try
                End If
            Next

            Dim counter As Integer = 0
            Dim succeeded As Boolean = True
            Dim retry As Int32 = 1
            _sendSuccessEmails = remi.GetInstance().HasAccess("RemiTimedServiceSendSuccessEmails")
            _sendNotAssignedEmails = remi.GetInstance().HasAccess("RemiTimedServiceSendNotAssignedEmails")

            If batches IsNot Nothing Then
                sb.AppendLine(DateTime.Now.ToString + " - Done. " + batches.Length.ToString + " batches retreived.")
                sb.AppendLine(DateTime.Now + " - Starting checks...")

                For Each s As String In batches
                    currentQRA = s
                    retry = 1

                    Do
                        Try
                            remi.GetInstance.CheckBatchForStatusUpdates(currentQRA, "remi@blackberry.com")

                            counter += 1
                            If counter Mod 50 = 0 Then
                                sb.AppendFormat("{0} - Last batch checked ({1}) : {2}", DateTime.Now, counter, currentQRA)
                                sb.Append(Environment.NewLine)
                            End If
                            retry = 5
                        Catch ex As Exception
                            retry += 1
                            succeeded = False
                            sb.Append(Environment.NewLine)
                            Dim message As String = String.Format("{0} - BATCH CHECK FAILED FOR: {1}{2}Error Message: {3}{4}Stack Trace: {5}", DateTime.Now, currentQRA, Environment.NewLine, ex.Message, Environment.NewLine, ex.StackTrace)
                            sb.Append(message)
                            sb.Append(Environment.NewLine)
                        End Try

                        If (runNotAssigned And _sendNotAssignedEmails) Then
                            Try
                                If (remi.GetInstance.BatchStartedBeforeAssigned(currentQRA)) Then
                                    SendMail(String.Format("BatchStartedBeforeAssigned For {0}...", currentQRA), currentQRA)
                                End If
                            Catch ex As Exception
                                sb.Append(Environment.NewLine)
                                sb.Append(String.Format("{0} - BatchStartedBeforeAssigned Failed For {1} with Error {2}{3}Stack Trace: {4}", DateTime.Now, currentQRA, ex.Message.ToString(), Environment.NewLine, ex.StackTrace))
                            End Try
                        End If
                    Loop While (retry < 5 And succeeded = False) 'The batch check failed. So retry while failed for 4 attempts
                Next
            Else
                sb.AppendLine(DateTime.Now + " - No active batches.")
            End If

            sb.AppendLine(DateTime.Now + " - Batch check complete. Total " + counter.ToString + " batches checked.")

            If (Not (succeeded) Or _sendSuccessEmails) Then
                SendMail(String.Format("Batch Check Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        Catch ex As Exception
            SendMail("Batch Check Failed.", ex.Message + Environment.NewLine + ex.StackTrace + Environment.NewLine + "Current Batch: " + currentQRA + Environment.NewLine + "Work Done: " + sb.ToString)
        End Try
    End Sub
End Class