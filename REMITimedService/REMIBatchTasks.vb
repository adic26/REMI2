Imports System.Timers
Imports System.Net.Mail
Imports System.Diagnostics
Imports System.Threading
Imports System.Configuration
Imports System.Text
Imports System.Net
Imports System.IO
Imports System.Web.Script.Serialization
Imports System.Text.RegularExpressions
Imports REMITimedService.RemiTimedService

Public Class REMIBatchTasks
    Inherits System.ServiceProcess.ServiceBase

#Region "Declaration"
    Private _sendSuccessEmails As Boolean
    Private _sendNotAssignedEmails As Boolean
    Private tcbJIRA As TimerCallback = New TimerCallback(AddressOf JIRASync)
    Private jiraTimer As Threading.Timer
    Private tcbStarted As TimerCallback = New TimerCallback(AddressOf BatchStartedBeforeAssigned)
    Private startedTimer As Threading.Timer
    Private tcbCheckUpdates As TimerCallback = New TimerCallback(AddressOf CheckBatchForStatusUpdates)
    Private checkUpdateTimer As Threading.Timer
#End Region

    Public Sub New()
        InitializeComponent()
    End Sub

#Region "Service Methods"
    Protected Overrides Sub OnStart(ByVal args() As String)
        _sendSuccessEmails = remi.GetInstance().HasAccess("RemiTimedServiceSendSuccessEmails")
        _sendNotAssignedEmails = remi.GetInstance().HasAccess("RemiTimedServiceSendNotAssignedEmails")

        Dim now As Date = DateTime.Now
        Dim dueTime As Integer
        dueTime = 3600000 - (now.Minute Mod 60) * 60000 - now.Second * 1000 - now.Millisecond
        jiraTimer = New System.Threading.Timer(tcbJIRA, Nothing, dueTime, 3600000)

        'Timer is set in milliseconds so we set it to run every 1000 (millisecond => second) * 60 (second => minute) * 60 (minute => hour) * 24 (hour => day)
        startedTimer = New System.Threading.Timer(tcbStarted, Nothing, 0, (1000 * 60 * 60 * 24))

        Dim interval As Int32 = My.MySettings.Default.IntervalMinutes
        dueTime = (interval * 60000)
        checkUpdateTimer = New System.Threading.Timer(tcbCheckUpdates, Nothing, 0, dueTime)
    End Sub

    Protected Overrides Sub OnStop()
        checkUpdateTimer = Nothing
        startedTimer = Nothing
        jiraTimer = Nothing
    End Sub
#End Region

#Region "Methods"
    Private Sub CheckBatchForStatusUpdates()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 6 And now.Hour <= 18)) Then 'Don't run if not between 7am and 5pm
            Return
        End If

        Dim sb As New System.Text.StringBuilder
        Dim counter As Integer = 0
        Dim succeeded As Boolean = True
        Dim retry As Int32 = 1

        Try
            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - Check Interval: {1}", DateTime.Now, My.MySettings.Default.IntervalMinutes))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, My.MySettings.Default.REMITimedService_RemiAPI_RemiAPI))
            sb.AppendLine(DateTime.Now + " - Batch check starting...")
            sb.AppendLine(DateTime.Now + " - Retrieving Active Jobs...")

            Dim requests As New List(Of String)
            Dim dtDepartments As DataTable = remi.GetInstance.GetLookups(RemiAPI.LookupType.Department)
            Dim ebs As RemiAPI.BatchSearchBatchStatus() = New RemiAPI.BatchSearchBatchStatus() {RemiAPI.BatchSearchBatchStatus.Complete, RemiAPI.BatchSearchBatchStatus.Rejected, RemiAPI.BatchSearchBatchStatus.Held, RemiAPI.BatchSearchBatchStatus.NotSavedToREMI, RemiAPI.BatchSearchBatchStatus.Quarantined, RemiAPI.BatchSearchBatchStatus.Received}
            Dim bv As RemiAPI.BatchView() = remi.GetInstance.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, RemiAPI.TrackingLocationFunction.NotSet, String.Empty, RemiAPI.BatchStatus.NotSet, RemiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, RemiAPI.TestStageType.NotSet)
            requests.AddRange((From rs As RemiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())

            For Each department As DataRow In dtDepartments.Rows.Cast(Of DataRow)()
                If (department.Field(Of String)("LookupType").ToString() <> "All Test Centers") Then
                    Try
                        sb.AppendLine(String.Format("{0} - Retrieving TRS Batches For {1}...", DateTime.Now, department.Field(Of String)("LookupType").ToString()))
                        requests.AddRange((From r As DataRow In remi.GetInstance.GetRequestsNotInREMI(department.Field(Of String)("LookupType").ToString()) Select r.Field(Of String)("RequestNumber")).Distinct.ToList())
                    Catch ex As Exception
                        sb.AppendLine(String.Format("{0} - Error Retrieving Request Batches For {1}...", DateTime.Now, department.Field(Of String)("LookupType").ToString()))
                    End Try
                End If
            Next

            If requests IsNot Nothing Then
                sb.AppendLine(DateTime.Now.ToString + " - Done. " + requests.Count.ToString + " batches retreived.")
                sb.AppendLine(DateTime.Now + " - Starting checks...")

                For Each req In requests
                    retry = 1

                    Do
                        Try
                            remi.GetInstance.CheckBatchForStatusUpdates(req, "remi@blackberry.com")

                            counter += 1
                            If counter Mod 50 = 0 Then
                                sb.AppendFormat("{0} - Last batch checked ({1}) : {2}", DateTime.Now, counter, req)
                                sb.Append(Environment.NewLine)
                            End If
                            retry = 5
                        Catch ex As Exception
                            retry += 1
                            succeeded = False
                            sb.Append(Environment.NewLine)
                            Dim message As String = String.Format("{0} - BATCH CHECK FAILED FOR: {1}{2}Error Message: {3}{4}Stack Trace: {5}", DateTime.Now, req, Environment.NewLine, ex.Message, Environment.NewLine, ex.StackTrace)
                            sb.Append(message)
                            sb.Append(Environment.NewLine)
                        End Try
                    Loop While (retry < 5 And succeeded = False) 'The batch check failed. So retry while failed for 4 attempts
                Next
            Else
                sb.AppendLine(DateTime.Now + " - No active batches.")
            End If

            sb.AppendLine(DateTime.Now + " - Batch check complete. Total " + counter.ToString + " batches checked.")

            If (Not (succeeded) Or _sendSuccessEmails) Then
                Helpers.SendMail(String.Format("Batch Check Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        Catch ex As Exception
            Helpers.SendMail("Batch Check Failed.", ex.Message + Environment.NewLine + ex.StackTrace + Environment.NewLine + "Work Done: " + sb.ToString)
        End Try
    End Sub

    Private Sub JIRASync()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 7 And now.Hour <= 18)) Then 'Don't run if not between 8am and 5pm
            Return
        End If

        If (_sendSuccessEmails) Then
            Helpers.SendMail("JIRA Sync", "Executing")
        End If

        Dim sbSource As StringBuilder
        Dim request As HttpWebRequest
        Dim response As HttpWebResponse = Nothing
        Dim reader As StreamReader
        Dim dtServices As DataTable = remi.GetInstance.GetServicesAccess(Nothing)
        Dim requests As New List(Of String)
        'Dim products As New List(Of String)
        Dim ebs As RemiAPI.BatchSearchBatchStatus() = New RemiAPI.BatchSearchBatchStatus() {RemiAPI.BatchSearchBatchStatus.Complete, RemiAPI.BatchSearchBatchStatus.Rejected, RemiAPI.BatchSearchBatchStatus.Held, RemiAPI.BatchSearchBatchStatus.NotSavedToREMI, RemiAPI.BatchSearchBatchStatus.Quarantined, RemiAPI.BatchSearchBatchStatus.Received}
        Dim url As String = String.Empty

        For Each department As DataRow In (From s As DataRow In dtServices.Rows Where s.Field(Of String)("ServiceName") = "JIRASync" Select s).ToList
            Dim bv As RemiAPI.BatchView() = remi.GetInstance.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, department.Field(Of String)("Values").ToString(), String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, RemiAPI.TrackingLocationFunction.NotSet, String.Empty, RemiAPI.BatchStatus.NotSet, RemiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, RemiAPI.TestStageType.NotSet)
            requests.AddRange((From rs As RemiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())
            'products.AddRange((From rs As RemiAPI.BatchView In bv Select rs.ProductGroup).Distinct.ToList())
        Next

        Try
            ' and ""Applicable Platform(s)"" IN (""{1}"")     , String.Join(""",""", products.ConvertAll(Of String)(Function(i As String) i.ToString()).ToArray())
            Dim json As String = String.Format("labels IN ({0}) and issuetype=defect", String.Join(",", requests.ConvertAll(Of String)(Function(i As String) i.ToString()).ToArray()))
            url = String.Format("{0}rest/api/2/search?jql={1}&fields=key,summary,labels", ConfigurationManager.AppSettings("JIRALink").ToString(), Uri.EscapeUriString(json))
            request = DirectCast(WebRequest.Create(url), HttpWebRequest)
            request.Credentials = CredentialCache.DefaultCredentials
            request.Method = "GET"
            request.Timeout = 25000
            request.UseDefaultCredentials = True
            request.ContentType = "application/json"
            request.AutomaticDecompression = DecompressionMethods.GZip + DecompressionMethods.Deflate
            Dim authBytes As Byte() = Encoding.UTF8.GetBytes("remi:Zaq12wsx".ToCharArray())
            request.Headers("Authorization") = "Basic " + Convert.ToBase64String(authBytes)
            response = DirectCast(request.GetResponse(), HttpWebResponse)

            If request.HaveResponse = True AndAlso Not (response Is Nothing) Then
                reader = New StreamReader(response.GetResponseStream())
                sbSource = New StringBuilder(reader.ReadToEnd())

                Dim jiraSerialized As Dictionary(Of String, Object) = New JavaScriptSerializer().Deserialize(Of Object)(sbSource.ToString())

                For Each rec In DirectCast(jiraSerialized("issues"), Object())
                    Dim key As String = rec("key")
                    Dim title As String = DirectCast(rec("fields"), Dictionary(Of String, Object))("summary")
                    Dim requestNumber As String = String.Empty

                    For Each l In DirectCast(rec("fields"), Dictionary(Of String, Object))("labels")
                        If Regex.IsMatch(l.ToString(), "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}$") Then
                            requestNumber = l.ToString()
                        End If
                    Next

                    Dim dtJIRA As DataTable = remi.GetInstance.GetBatchJIRA(requestNumber)
                    Dim jira As DataRow = (From j As DataRow In dtJIRA Where j.Field(Of String)("DisplayName") = key Select j).FirstOrDefault()

                    If (jira Is Nothing) Then
                        remi.GetInstance.AddEditJira(requestNumber, 0, key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                    Else
                        remi.GetInstance.AddEditJira(requestNumber, jira.Field(Of Int32)("JIRAID"), key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                    End If
                Next
            End If
        Catch wex As WebException
            Helpers.SendMail("JIRA Check Failed...", String.Format("Message: {0}{1}StackTrace: {2}{3}{4}", wex.Message, Environment.NewLine, wex.StackTrace.ToString(), Environment.NewLine, url))
        Catch err As Exception
            Helpers.SendMail("JIRA Check Failed...", String.Format("Message: {0}{1}StackTrace: {2}{3}{4}", err.Message, Environment.NewLine, err.StackTrace.ToString(), Environment.NewLine, url))
        Finally
            If Not response Is Nothing Then response.Close()
        End Try

        If (_sendSuccessEmails) Then
            Helpers.SendMail("JIRA Sync", "Finished Executing")
        End If
    End Sub

    Private Sub BatchStartedBeforeAssigned()
        If (_sendNotAssignedEmails) Then
            If (_sendSuccessEmails) Then
                Helpers.SendMail("BatchStarted Before Assigned", "Executing")
            End If

            Dim countStarted As Int32 = 0

            Try
                Dim requests As New List(Of String)
                Dim ebs As RemiAPI.BatchSearchBatchStatus() = New RemiAPI.BatchSearchBatchStatus() {RemiAPI.BatchSearchBatchStatus.Complete, RemiAPI.BatchSearchBatchStatus.Rejected, RemiAPI.BatchSearchBatchStatus.Held, RemiAPI.BatchSearchBatchStatus.NotSavedToREMI, RemiAPI.BatchSearchBatchStatus.Quarantined, RemiAPI.BatchSearchBatchStatus.Received}
                Dim bv As RemiAPI.BatchView() = remi.GetInstance.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, RemiAPI.TrackingLocationFunction.NotSet, String.Empty, RemiAPI.BatchStatus.NotSet, RemiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, RemiAPI.TestStageType.NotSet)
                requests.AddRange((From rs As RemiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())

                For Each req In requests
                    If (remi.GetInstance.BatchStartedBeforeAssigned(req)) Then
                        countStarted += 1
                        Helpers.SendMail(String.Format("BatchStarted Before Assigned For {0}...", req), req)
                    End If
                Next
            Catch wex As WebException
                Helpers.SendMail("BatchStarted Before Assigned Failed...", String.Format("Message: {0}{1}StackTrace: {2}", wex.Message, Environment.NewLine, wex.StackTrace.ToString()))
            Catch err As Exception
                Helpers.SendMail("BatchStarted Before AssignedFailed...", String.Format("Message: {0}{1}StackTrace: {2}", err.Message, Environment.NewLine, err.StackTrace.ToString()))
            End Try

            If (_sendSuccessEmails) Then
                Helpers.SendMail("BatchStarted Before Assigned", String.Format("Finished Executing {0} Requests Started", countStarted))
            End If
        End If
    End Sub
#End Region
End Class