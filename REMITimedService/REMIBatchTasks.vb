Imports System.Timers
Imports System.Net.Mail
Imports System.Diagnostics
Imports System.Threading

Public Class REMIBatchTasks
    Inherits System.ServiceProcess.ServiceBase

    Private Shared _runTimedThreadFlag As Boolean ' used to control the thread spawned by the service to run tasks
    Private Shared _sync As Boolean
    Private Shared _dontRun As Boolean = True
    Private Shared _syncCount As Int32 = 0
    Private _sendSuccessEmails As Boolean
    Private Shared _configIntervalMinutes As Integer = My.MySettings.Default.IntervalMinutes
    Private Shared _webServiceURL As String = My.MySettings.Default.REMITimedService_remiAPI1_RemiAPI
    Private Shared _sendEmailTo As String = "remi@blackberry.com"
    Private Shared _sendHighPriorityEmailTo As String = "reliabilityinfrastructure@blackberry.com"

    Public Sub New()
        InitializeComponent()
    End Sub

    Protected Overrides Sub OnStart(ByVal args() As String)
        _runTimedThreadFlag = True
        Dim t As Thread = New Thread(New ThreadStart(AddressOf TimedLoop))
        t.Start()
    End Sub

    Private Sub TimedLoop()
        _sync = True
        While _runTimedThreadFlag
            Dim dateValue As Date = DateTime.Now

            If (dateValue.DayOfWeek = DayOfWeek.Sunday) Then 'Force Sync because it's Sunday and impact will be very little.
                _sync = True
            Else
                _sync = False
            End If

            If ((dateValue.Hour >= 3 And dateValue.Hour <= 6) Or (dateValue.Hour >= 19 And dateValue.Hour <= 23)) Then 'Don't synce between 3 AM and 6 AM or between 7 and 11
                _dontRun = True
            Else
                _dontRun = False
            End If

            If (Not (_dontRun)) Then
                RunTasks()
            End If

            'Don't set the time here. Use the config interval above!
            Thread.Sleep(_configIntervalMinutes * 60000)
        End While

        SendMail("Remi Timed Task Stopping.", "Auto Message")
    End Sub

    Protected Overrides Sub OnStop()
        _runTimedThreadFlag = False
    End Sub

    Private Shared Sub SendMailHighPriority(ByVal subject As String, ByVal message As String)
        Try
            remi.GetInstance.SendMail(_sendHighPriorityEmailTo, "remiTimedService@blackberry.com", subject, message)
        Catch ex As Exception
            _runTimedThreadFlag = False
            Throw
        End Try
    End Sub

    Private Shared Sub SendMail(ByVal subject As String, ByVal message As String)
        Try
            remi.GetInstance.SendMail(_sendEmailTo, "remiTimedService@blackberry.com", subject, message)
        Catch ex As Exception
            _runTimedThreadFlag = False
            Throw
        End Try
    End Sub

    ''' <summary>
    ''' This is a list of the tasks that are run
    ''' </summary>
    ''' <remarks></remarks>
    Private Sub RunTasks()
        Dim sb As New System.Text.StringBuilder
        Dim currentQRA As String = String.Empty
        Try
            Dim forceSync As Boolean = False
            forceSync = remi.GetInstance().HasAccess("RemiTimedServiceForceSync")

            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - Check Interval: {1}", DateTime.Now, _configIntervalMinutes.ToString()))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, _webServiceURL))
            sb.AppendLine(String.Format("{0} - Force Sync: {1}", DateTime.Now, forceSync.ToString()))

            If ((_sync Or forceSync) And _syncCount = 0) Then 'Sync oracle to Remi
                Try
                    sb.AppendLine(String.Format("Beginning Syncing Of Lookups & Products"))

                    Dim testCenterCount As Int32 = 0
                    Dim accessoryCount As Int32 = 0
                    Dim jobCount As Int32 = 0
                    Dim productTypeCount As Int32 = 0
                    Dim remiProductTypes As New DataTable
                    Dim remiAccessoryTypes As New DataTable
                    Dim remiTestCenters As New DataTable
                    Dim remiProducts As IEnumerable(Of String)
                    Dim remiJobs As IEnumerable(Of String)

                    Dim oracleProducts As IEnumerable(Of String)
                    Dim oracleAccessoryTypes As IEnumerable(Of String)
                    Dim oracleProductTypes As IEnumerable(Of String)
                    Dim oracleTestCenters As IEnumerable(Of String)
                    Dim oracleJobs As IEnumerable(Of String)

                    'Get the remi database lists
                    remiProductTypes = remi.GetInstance().GetLookups(3)
                    remiAccessoryTypes = remi.GetInstance().GetLookups(2)
                    remiTestCenters = remi.GetInstance().GetLookups(4)
                    remiProducts = (From p In remi.GetInstance().GetProductGroups() _
                        Select p)
                    remiJobs = (From j In remi.GetInstance().GetJobs() _
                        Select j)

                    'Get the oracle database lists
                    oracleProducts = (From p In remi.GetInstance().GetProductOracleList() _
                        Select p)
                    oracleAccessoryTypes = (From a In remi.GetInstance().GetOracleAccessoryTypes() _
                        Select a)
                    oracleProductTypes = (From p In remi.GetInstance().GetOracleProductTypes() _
                        Select p)
                    oracleTestCenters = (From t In remi.GetInstance().GetOracleTestCenters() _
                        Select t)
                    oracleJobs = (From j In remi.GetInstance().GetTRSJobs() _
                        Select j)

                    'Sync the oracle list to remi list
                    For Each str As String In oracleAccessoryTypes
                        Dim dr() As DataRow = remiAccessoryTypes.Select("LookupType = '" & str + "'")
                        If (dr.Length = 0) Then
                            accessoryCount += 1
                            remi.GetInstance().SaveLookup("AccessoryType", str, 1, Nothing, 0)
                        End If
                    Next

                    For Each str As String In oracleProductTypes
                        Dim dr() As DataRow = remiProductTypes.Select("LookupType = '" & str + "'")
                        If (dr.Length = 0) Then
                            productTypeCount += 1
                            remi.GetInstance().SaveLookup("ProductType", str, 1, Nothing, 0)
                        End If
                    Next

                    For Each str As String In oracleTestCenters
                        Dim dr() As DataRow = remiTestCenters.Select("LookupType = '" & str + "'")
                        If (dr.Length = 0) Then
                            testCenterCount += 1
                            remi.GetInstance().SaveLookup("ProductType", str, 1, Nothing, 0)
                        End If
                    Next

                    For Each str As String In remiProducts
                        If (Not (oracleProducts.Contains(str))) Then
                            remi.GetInstance().UpdateProduct(str.Trim(), 0, 0)
                        End If
                    Next

                    For Each str As String In oracleProducts
                        If (Not (remiProducts.Contains(str))) Then
                            remi.GetInstance().UpdateProduct(str.Trim(), 1, 0)
                        End If
                    Next

                    For Each str As String In oracleJobs
                        If (Not (remiJobs.Contains(str))) Then
                            Dim job As New remiAPI.Job
                            job.IsActive = 1
                            job.Name = str.Trim()
                            jobCount += 1

                            remi.GetInstance().SaveJob(job)
                        End If
                    Next

                    sb.AppendLine(String.Format("Inserted {0} Product Types", productTypeCount))
                    sb.AppendLine(String.Format("Inserted {0} Accessory Types", accessoryCount))
                    sb.AppendLine(String.Format("Inserted {0} Test Centers", testCenterCount))
                    sb.AppendLine(String.Format("Inserted {0} Jobs", jobCount))
                Catch ex As Exception
                    SendMailHighPriority("Oracle Sync Update Failed.", ex.Message + Environment.NewLine + ex.StackTrace)
                End Try

                _syncCount += 1
            End If

            sb.AppendLine(DateTime.Now + " - Batch check starting...")
            sb.AppendLine(DateTime.Now + " - Retrieving Active Jobs...")

            Dim batches As String() = remi.GetInstance.GetActiveBatchList
            Dim dtTestCenters As DataTable = remi.GetInstance.GetLookups(remiAPI.LookupType.TestCenter)

            For Each center As DataRow In dtTestCenters.Rows.Cast(Of DataRow)()
                If (center.Field(Of String)("LookupType").ToString() <> "All Test Centers") Then
                    Try
                        sb.AppendLine(String.Format("{0} - Retrieving TRS Batches For {1}...", DateTime.Now, center.Field(Of String)("LookupType").ToString()))
                        batches.Concat(remi.GetInstance.GetTRSReviewedBatchList(center.Field(Of String)("LookupType").ToString()))
                    Catch ex As Exception
                        sb.AppendLine(String.Format("{0} - Error Retrieving TRS Batches For {1}...", DateTime.Now, center.Field(Of String)("LookupType").ToString()))
                    End Try
                End If
            Next

            Dim counter As Integer = 0
            Dim succeeded As Boolean = True
            Dim retry As Int32 = 1
            _sendSuccessEmails = remi.GetInstance().HasAccess("RemiTimedServiceSendSuccessEmails")

            If batches IsNot Nothing Then
                sb.AppendLine(DateTime.Now.ToString + " - Done. " + batches.Length.ToString + " batches retreived.")
                sb.AppendLine(DateTime.Now + " - Starting checks...")

                For Each s As String In batches
                    currentQRA = s
                    retry = 1

                    Do
                        Try
                            remi.GetInstance.CheckBatchForStatusUpdates(s, "remi@blackberry.com")

                            counter += 1
                            If counter Mod 50 = 0 Then
                                sb.AppendFormat("{0} - Last batch checked ({1}) : {2}", DateTime.Now, counter, s)
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

                        Try
                            remi.GetInstance.BatchStartedBeforeAssigned(s)
                        Catch ex As Exception
                            sb.Append(Environment.NewLine)
                            sb.Append(String.Format("{0} - BatchStartedBeforeAssigned Failed For {1} with Error {2}{3}Stack Trace: {4}", DateTime.Now, currentQRA, ex.Message.ToString(), Environment.NewLine, ex.StackTrace))
                        End Try
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
            SendMailHighPriority("Batch Check Failed.", ex.Message + Environment.NewLine + ex.StackTrace + Environment.NewLine + "Current Batch: " + currentQRA + Environment.NewLine + "Work Done: " + sb.ToString)
        End Try
    End Sub
End Class