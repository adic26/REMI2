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
Imports Word = Microsoft.Office.Interop.Word
Imports System.IO.Compression
Imports System.Data.SqlClient
Imports System.Drawing

Public Class REMITasks
    Inherits System.ServiceProcess.ServiceBase

#Region "Declaration"
    Private _sendSuccessEmails As Boolean
    Private _sendNotAssignedEmails As Boolean
    Private _createDocs As Boolean
    Private _checkJIRA As Boolean
    Private tcbJIRA As TimerCallback = New TimerCallback(AddressOf JIRASyncByDB)
    Private jiraTimer As Threading.Timer
    Private tcbStarted As TimerCallback = New TimerCallback(AddressOf BatchStartedBeforeAssigned)
    Private startedTimer As Threading.Timer
    Private tcbCheckUpdates As TimerCallback = New TimerCallback(AddressOf CheckBatchForStatusUpdates)
    Private checkUpdateTimer As Threading.Timer
    Private tcbCreateDoc As TimerCallback = New TimerCallback(AddressOf CreateDocs)
    Private createDocTimer As Threading.Timer
#End Region

    Public Sub New()
        InitializeComponent()
    End Sub

#Region "Service Methods"
    Protected Overrides Sub OnStart(ByVal args() As String)
        Dim now As Date = DateTime.Now
        Dim dueTime As Integer
        dueTime = 3600000 - (now.Minute Mod 60) * 60000 - now.Second * 1000 - now.Millisecond
        jiraTimer = New System.Threading.Timer(tcbJIRA, Nothing, dueTime, 3600000)

        'Timer is set in milliseconds so we set it to run every 1000 (millisecond => second) * 60 (second => minute) * 60 (minute => hour) * 24 (hour => day)
        startedTimer = New System.Threading.Timer(tcbStarted, Nothing, 0, (1000 * 60 * 60 * 24))

        Dim interval As Int32 = My.MySettings.Default.IntervalMinutes
        dueTime = (interval * 60000)
        checkUpdateTimer = New System.Threading.Timer(tcbCheckUpdates, Nothing, 0, dueTime)

        'dueTime = 3600000 - (now.Minute Mod 60) * 60000 - now.Second * 1000 - now.Millisecond
        'createDocTimer = New System.Threading.Timer(tcbCreateDoc, Nothing, dueTime, 14400000) 'Every 4 hours on the hour.
    End Sub

    Protected Overrides Sub OnStop()
        checkUpdateTimer = Nothing
        startedTimer = Nothing
        jiraTimer = Nothing
        createDocTimer = Nothing
    End Sub
#End Region

#Region "Methods"
    Private Sub CreateDocs()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 12 And now.Hour <= 17) Or now.DayOfWeek = DayOfWeek.Saturday Or now.DayOfWeek = DayOfWeek.Sunday) Then 'Don't run if not between 7am and 5pm
            Return
        End If

        _createDocs = DBControl.DAL.Remi.HasAccess("RemiTimedServiceCreateDocs")
        _sendSuccessEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendSuccessEmails")
        Dim sb As New System.Text.StringBuilder

        If (_createDocs) Then
            Dim succeeded As Boolean = True
            Dim counter As Integer = 0
            Dim dtServices As DataTable = DBControl.DAL.Remi.GetServicesAccess(Nothing)
            Dim ebs As DBControl.remiAPI.BatchSearchBatchStatus() = New DBControl.remiAPI.BatchSearchBatchStatus() {DBControl.remiAPI.BatchSearchBatchStatus.Complete, DBControl.remiAPI.BatchSearchBatchStatus.Held, DBControl.remiAPI.BatchSearchBatchStatus.NotSavedToREMI, DBControl.remiAPI.BatchSearchBatchStatus.Quarantined, DBControl.remiAPI.BatchSearchBatchStatus.Received, DBControl.remiAPI.BatchSearchBatchStatus.Rejected}
            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, DBControl.DAL.Remi.WSUrl))
            sb.AppendLine(String.Format("{0} - Create Doc Creation Starting...", DateTime.Now))

            For Each department As DataRow In (From s As DataRow In dtServices.Rows Where s.Field(Of String)("ServiceName") = "ExecutiveDoc" Select s).ToList
                Dim bv As DBControl.remiAPI.BatchView() = DBControl.DAL.Remi.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, department.Field(Of String)("Values").ToString(), String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, "Report", String.Empty, String.Empty, DBControl.remiAPI.TrackingLocationFunction.NotSet, String.Empty, DBControl.remiAPI.BatchStatus.NotSet, DBControl.remiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, DBControl.remiAPI.TestStageType.NonTestingTask)

                For Each bw In bv
                    Dim req() As DBControl.remiAPI.RequestFields = DBControl.DAL.Remi.GetRequest(bw.QRANumber)
                    Dim dtFiles As DataTable = DBControl.DAL.Results.GetFiles(bw.QRANumber, True)
                    Dim es As String = (From r In req Where r.IntField = "ExecutiveSummary" Select r.Value).FirstOrDefault()
                    Dim fileToOpen As Object = DirectCast(ConfigurationManager.AppSettings("TemplateFile").ToString(), Object)

                    If Not Directory.Exists(String.Concat(ConfigurationManager.AppSettings("DocCreationFolder").ToString(), req(0).RequestType)) Then
                        Directory.CreateDirectory(String.Concat(ConfigurationManager.AppSettings("DocCreationFolder").ToString(), req(0).RequestType))
                    End If

                    Dim fileToSave As Object = DirectCast(String.Format("{0}{1}\{2}.docx", ConfigurationManager.AppSettings("DocCreationFolder").ToString(), req(0).RequestType, bw.QRANumber), Object)

                    If (Not String.IsNullOrEmpty(es) And Not File.Exists(fileToSave)) Then
                        Dim PassFail As String = DBControl.DAL.Results.GetOverAllPassFail(bw.QRANumber)

                        Dim wordApp As New Word.Application()
                        Dim sourceDoc As New Word.Document
                        Dim missing As Object = System.Reflection.Missing.Value
                        sourceDoc = wordApp.Documents.Open(fileToOpen, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing, missing)

                        If (sourceDoc IsNot Nothing) Then
                            Dim rng As Word.Range

                            If (sourceDoc.Bookmarks.Exists(DirectCast("Department", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("Department", Object)).Range
                                rng.Text = bw.Department
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            If (sourceDoc.Bookmarks.Exists(DirectCast("ExecutiveSummary", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("ExecutiveSummary", Object)).Range
                                rng.Text = es
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            If (sourceDoc.Bookmarks.Exists(DirectCast("JobName", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("JobName", Object)).Range
                                rng.Text = bw.JobName
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            If (sourceDoc.Bookmarks.Exists(DirectCast("JobNameHeader", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("JobNameHeader", Object)).Range
                                rng.Text = bw.JobName
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            If (sourceDoc.Bookmarks.Exists(DirectCast("RequestNumber", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("RequestNumber", Object)).Range
                                rng.Text = bw.QRANumber
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            If (sourceDoc.Bookmarks.Exists(DirectCast("PartNameUnderTest", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("PartNameUnderTest", Object)).Range
                                rng.Text = (From r In req Where r.Name = "Part Name Under Test" Select r.Value).FirstOrDefault()
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            rng = sourceDoc.Bookmarks.Item(DirectCast("RequestDetails", Object)).Range
                            rng.Text = String.Empty
                            Dim oTemplate As Word.ListTemplate = wordApp.ListGalleries.Item(Word.WdListGalleryType.wdBulletGallery).ListTemplates.Item(1)

                            For Each r In req
                                If (Not String.IsNullOrEmpty(r.Value) And Not r.IntField.ToLower.Contains("execut")) Then
                                    With rng
                                        .ListFormat.ApplyListTemplateWithLevel(ListTemplate:=oTemplate, ContinuePreviousList:=False, ApplyTo:=Word.WdListApplyTo.wdListApplyToWholeList, DefaultListBehavior:=Word.WdDefaultListBehavior.wdWord10ListBehavior)
                                        .Collapse(Word.WdCollapseDirection.wdCollapseStart)
                                        .Text = String.Format("{0}: {1}", r.Name, r.Value.Replace(vbCr, " ").Replace(vbLf, " "))
                                        .Font.Size = 10
                                        .Font.Name = "Arial"
                                        .ParagraphFormat.Alignment = Word.WdParagraphAlignment.wdAlignParagraphLeft
                                        .Bold = False
                                        .InsertParagraphAfter()
                                        .Collapse(Word.WdCollapseDirection.wdCollapseEnd)
                                    End With
                                End If
                            Next

                            System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)

                            If (sourceDoc.Bookmarks.Exists(DirectCast("Result", Object).ToString())) Then
                                rng = sourceDoc.Bookmarks.Item(DirectCast("Result", Object)).Range
                                rng.Text = PassFail
                                System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            End If

                            Dim tempPath As String = String.Concat(Path.GetTempPath(), bw.QRANumber)

                            If (Directory.Exists(tempPath)) Then
                                Directory.Delete(tempPath, True)
                            End If

                            Directory.CreateDirectory(tempPath)

                            For Each row As DataRow In dtFiles.Rows
                                Dim stagePath As String = String.Concat(tempPath, "\", row.Field(Of String)("TestStageName").ToString())
                                Dim testPath As String = String.Concat(stagePath, "\", row.Field(Of String)("TestName").ToString())
                                Dim unit As String = String.Concat(testPath, "\", row.Field(Of Int32)("BatchUnitNumber").ToString())
                                Dim contentType As String = row.Field(Of String)("ContentType").ToString().Replace(".", String.Empty)
                                Dim fileName As String = row.Field(Of String)("FileName").ToString()
                                fileName = fileName.Substring(fileName.LastIndexOf("\") + 1)

                                If Not Directory.Exists(stagePath) Then
                                    Directory.CreateDirectory(stagePath)
                                End If

                                If Not Directory.Exists(testPath) Then
                                    Directory.CreateDirectory(testPath)
                                End If

                                If Not Directory.Exists(unit) Then
                                    Directory.CreateDirectory(unit)
                                End If

                                Dim fs As IO.FileStream = New IO.FileStream(String.Concat(unit, "\", fileName), IO.FileMode.OpenOrCreate, IO.FileAccess.Write)
                                Dim binwrite As IO.BinaryWriter = New IO.BinaryWriter(fs)
                                binwrite.Write(row.Field(Of Byte())("File"))
                                binwrite.Flush()
                                binwrite.Close()
                                fs.Close()
                                binwrite = Nothing
                                fs.Dispose()
                            Next

                            rng = sourceDoc.Bookmarks.Item(DirectCast("Images", Object)).Range
                            Dim rowCount As Int32 = Math.Ceiling(dtFiles.Rows.Count() / 2)
                            Dim tbl As Word.Table = rng.Tables.Add(rng, rowCount, 2, missing, missing)
                            Dim pictureCounter As Int32 = 0
                            tbl.Borders(Word.WdBorderType.wdBorderBottom).LineStyle = Word.WdLineStyle.wdLineStyleSingle
                            tbl.Borders(Word.WdBorderType.wdBorderLeft).LineStyle = Word.WdLineStyle.wdLineStyleSingle
                            tbl.Borders(Word.WdBorderType.wdBorderRight).LineStyle = Word.WdLineStyle.wdLineStyleSingle
                            tbl.Borders(Word.WdBorderType.wdBorderTop).LineStyle = Word.WdLineStyle.wdLineStyleSingle
                            tbl.Borders(Word.WdBorderType.wdBorderVertical).LineStyle = Word.WdLineStyle.wdLineStyleSingle
                            tbl.Borders(Word.WdBorderType.wdBorderHorizontal).LineStyle = Word.WdLineStyle.wdLineStyleSingle

                            For Each row As Word.Row In tbl.Rows
                                For Each cell As Word.Cell In row.Cells
                                    If (pictureCounter < dtFiles.Rows.Count) Then
                                        Dim innerTable As Word.Table = cell.Range.Tables.Add(cell.Range, 1, 1, missing, missing)

                                        innerTable.Rows(1).Cells(1).Range.Text = dtFiles.Rows(pictureCounter).Field(Of String)("Values")
                                        innerTable.Rows(1).Cells(1).Range.Bold = 0
                                        innerTable.Rows(1).Cells(1).Range.Font.Size = 9
                                        Dim row2 As Word.Row = innerTable.Rows.Add(missing)

                                        Dim ms As MemoryStream = New MemoryStream(dtFiles.Rows(pictureCounter).Field(Of Byte())("File"))
                                        Dim image As Bitmap = DirectCast(Drawing.Image.FromStream(ms), Bitmap)

                                        Dim origHPix As Int32 = image.Height
                                        Dim origWPix As Int32 = image.Width
                                        Dim newWInches As Decimal = 3.5
                                        Dim newWPoints As Decimal = wordApp.InchesToPoints(newWInches)
                                        Dim newWPixels As Decimal = wordApp.PointsToPixels(newWPoints, missing)
                                        Dim newHPixels As Decimal = newWPixels * origHPix / origWPix
                                        Dim newImage As Bitmap = New Bitmap(image, New Size(newWPixels, newHPixels))

                                        System.Windows.Forms.Clipboard.SetDataObject(newImage)
                                        row2.Cells(1).Range.PasteAndFormat(Word.WdRecoveryType.wdFormatOriginalFormatting)
                                        image.Dispose()
                                        image = Nothing
                                        newImage.Dispose()
                                        newImage = Nothing

                                        Dim row3 As Word.Row = innerTable.Rows.Add(missing)
                                        row3.Cells(1).Range.Text = String.Format("{0} {1} {2}", dtFiles.Rows(pictureCounter).Field(Of String)("TestStageName"), dtFiles.Rows(pictureCounter).Field(Of String)("TestName"), dtFiles.Rows(pictureCounter).Field(Of Int32)("BatchUnitNumber"))
                                        row3.Range.Font.Bold = 0
                                        row3.Range.Font.Size = 8
                                        System.Runtime.InteropServices.Marshal.ReleaseComObject(row3)
                                        System.Runtime.InteropServices.Marshal.ReleaseComObject(row2)
                                        System.Runtime.InteropServices.Marshal.ReleaseComObject(innerTable)

                                        pictureCounter += 1
                                    End If
                                    System.Runtime.InteropServices.Marshal.ReleaseComObject(cell)
                                Next
                            Next
                            System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)
                            System.Runtime.InteropServices.Marshal.ReleaseComObject(tbl)

                            Dim subDirs As String() = IO.Directory.GetDirectories(tempPath)
                            rng = sourceDoc.Bookmarks.Item(DirectCast("ZipImages", Object)).Range
                            rng.Text = String.Empty

                            For Each dir As String In subDirs
                                Dim file As String = String.Concat(tempPath, "\", dir.Substring(dir.LastIndexOf("\") + 1) + ".zip")
                                ZipFile.CreateFromDirectory(dir, file, CompressionLevel.Optimal, True)

                                rng.InlineShapes.AddOLEObject(missing, file, missing, missing, missing, missing, missing, missing)
                            Next

                            System.Runtime.InteropServices.Marshal.ReleaseComObject(rng)

                            Directory.Delete(tempPath, True)
                        End If

                        If (sourceDoc IsNot Nothing) Then
                            sourceDoc.SaveAs(fileToSave, missing, missing, missing, missing, missing, missing, missing, missing,
                                     missing, missing, missing, missing, missing, missing, missing)
                            Dim saveChanges As Object = DirectCast(Word.WdSaveOptions.wdDoNotSaveChanges, Object)
                            sourceDoc.Close(saveChanges, missing, missing)
                        End If

                        If (wordApp IsNot Nothing) Then
                            wordApp.Quit(missing, missing, missing)
                        End If

                        Thread.Sleep(60000)
                    End If
                Next
            Next

            If (Not (succeeded) Or _sendSuccessEmails) Then
                sb.AppendLine(String.Format("{0} - Finished Creating {1} Word Doc's", DateTime.Now, counter))
                Helpers.SendMail(String.Format("Word Doc Creation Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        End If
    End Sub

    Private Sub CheckBatchForStatusUpdates()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 6 And now.Hour <= 18) Or now.DayOfWeek = DayOfWeek.Saturday Or now.DayOfWeek = DayOfWeek.Sunday) Then 'Don't run if not between 7am and 5pm
            Return
        End If

        Dim sb As New System.Text.StringBuilder
        Dim counter As Integer = 0
        Dim succeeded As Boolean = True
        Dim retry As Int32 = 1
        _sendSuccessEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendSuccessEmails")

        Try
            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - Check Interval: {1}", DateTime.Now, My.MySettings.Default.IntervalMinutes))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, DBControl.DAL.Remi.WSUrl))
            sb.AppendLine(DateTime.Now + " - Batch check starting...")
            sb.AppendLine(DateTime.Now + " - Retrieving Active Jobs...")

            Dim requests As New List(Of String)
            Dim dtDepartments As DataTable = DBControl.DAL.Remi.GetLookups(DBControl.remiAPI.LookupType.Department)
            Dim ebs As DBControl.remiAPI.BatchSearchBatchStatus() = New DBControl.remiAPI.BatchSearchBatchStatus() {DBControl.remiAPI.BatchSearchBatchStatus.Complete, DBControl.remiAPI.BatchSearchBatchStatus.Rejected, DBControl.remiAPI.BatchSearchBatchStatus.Held, DBControl.remiAPI.BatchSearchBatchStatus.NotSavedToREMI, DBControl.remiAPI.BatchSearchBatchStatus.Quarantined, DBControl.remiAPI.BatchSearchBatchStatus.Received}
            Dim bv As DBControl.remiAPI.BatchView() = DBControl.DAL.Remi.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, DBControl.remiAPI.TrackingLocationFunction.NotSet, String.Empty, DBControl.remiAPI.BatchStatus.NotSet, DBControl.remiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, DBControl.remiAPI.TestStageType.NotSet)
            requests.AddRange((From rs As DBControl.remiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())

            For Each department As DataRow In dtDepartments.Rows.Cast(Of DataRow)()
                If (department.Field(Of String)("LookupType").ToString() <> "All Test Centers") Then
                    Try
                        sb.AppendLine(String.Format("{0} - Retrieving TRS Batches For {1}...", DateTime.Now, department.Field(Of String)("LookupType").ToString()))
                        requests.AddRange((From r As DataRow In DBControl.DAL.Remi.GetRequestsNotInREMI(department.Field(Of String)("LookupType").ToString()) Select r.Field(Of String)("RequestNumber")).Distinct.ToList())
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
                            DBControl.DAL.Remi.MoveBatchForward(req, "remi@blackberry.com")

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

    Private Sub JIRASyncByDB()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 7 And now.Hour <= 18) Or now.DayOfWeek = DayOfWeek.Saturday Or now.DayOfWeek = DayOfWeek.Sunday) Then 'Don't run if not between 8am and 5pm
            Return
        End If

        _checkJIRA = DBControl.DAL.Remi.HasAccess("RemiTimedServiceCheckJIRA")

        If (_checkJIRA) Then
            Dim sb As New StringBuilder
            Dim succeeded As Boolean = True
            Dim counter As Integer = 0
            _sendSuccessEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendSuccessEmails")
            Dim dtServices As DataTable = DBControl.DAL.Remi.GetServicesAccess(Nothing)
            Dim requests As New List(Of String)
            Dim ebs As DBControl.remiAPI.BatchSearchBatchStatus() = New DBControl.remiAPI.BatchSearchBatchStatus() {DBControl.remiAPI.BatchSearchBatchStatus.Complete, DBControl.remiAPI.BatchSearchBatchStatus.Rejected, DBControl.remiAPI.BatchSearchBatchStatus.Held, DBControl.remiAPI.BatchSearchBatchStatus.NotSavedToREMI, DBControl.remiAPI.BatchSearchBatchStatus.Quarantined, DBControl.remiAPI.BatchSearchBatchStatus.Received}

            For Each department As DataRow In (From s As DataRow In dtServices.Rows Where s.Field(Of String)("ServiceName") = "JIRASync" Select s).ToList
                Dim bv As DBControl.remiAPI.BatchView() = DBControl.DAL.Remi.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, department.Field(Of String)("Values").ToString(), String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, DBControl.remiAPI.TrackingLocationFunction.NotSet, String.Empty, DBControl.remiAPI.BatchStatus.NotSet, DBControl.remiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, DBControl.remiAPI.TestStageType.NotSet)
                requests.AddRange((From rs As DBControl.remiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())
                sb.AppendLine(String.Format("{0} - Adding Requests For Department {1}", DateTime.Now, department.Field(Of String)("Values").ToString()))
            Next

            Dim strRequests As String = String.Join("','", requests.ConvertAll(Of String)(Function(i As String) i.ToString()).ToArray())
            Dim dtJiraQuery As New DataTable("JiraQuery")

            Try
                Using myConnection As New SqlConnection(ConfigurationManager.ConnectionStrings("JiraDBConnectionString").ConnectionString)
                    Using myCommand As New SqlCommand("SELECT d.IssueKey, d.Summary, l.Label FROM FCT.vDefects d INNER JOIN DIM.vLabels l ON l.IssueID=d.IssueID WHERE l.Label IN ('" + strRequests + "')", myConnection)
                        myCommand.CommandType = CommandType.Text
                        myConnection.Open()

                        Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                        da.Fill(dtJiraQuery)
                        dtJiraQuery.TableName = "JiraQuery"
                    End Using
                End Using
            Catch ex As Exception
                sb.AppendLine(String.Format("{0} - Message: {1}{2}StackTrace: {3}", DateTime.Now, ex.Message, Environment.NewLine, ex.StackTrace.ToString()))
                succeeded = False
            End Try

            If (succeeded) Then
                For Each dr As DataRow In dtJiraQuery.Rows
                    Dim key As String = dr.Field(Of String)("IssueKey")
                    Dim title As String = dr.Field(Of String)("Summary")
                    Dim requestNumber As String = String.Empty

                    If Regex.IsMatch(dr.Field(Of String)("Label"), "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}$") Then
                        requestNumber = dr.Field(Of String)("Label")
                        sb.AppendLine(String.Format("{0} - Found Request {1}", DateTime.Now, requestNumber))
                    End If

                    If (Not String.IsNullOrEmpty(requestNumber)) Then
                        Dim dtJIRA As DataTable = DBControl.DAL.Remi.GetBatchJIRA(requestNumber)
                        Dim jira As DataRow = (From j As DataRow In dtJIRA Where j.Field(Of String)("DisplayName") = key Select j).FirstOrDefault()
                        counter += 1

                        If (jira Is Nothing) Then
                            sb.AppendLine(String.Format("{0} - Inserting {1} To REMI", DateTime.Now, requestNumber))
                            DBControl.DAL.Remi.AddEditJira(requestNumber, 0, key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                        Else
                            sb.AppendLine(String.Format("{0} - Editing {1} In REMI", DateTime.Now, requestNumber))
                            DBControl.DAL.Remi.AddEditJira(requestNumber, jira.Field(Of Int32)("JIRAID"), key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                        End If
                    End If
                Next
            End If

            If (Not (succeeded) Or _sendSuccessEmails) Then
                sb.AppendLine(String.Format("{0} - Finished Executing {1} JIRA's", DateTime.Now, counter))
                Helpers.SendMail(String.Format("JIRA Check Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        End If
    End Sub

    <Obsolete("Use JIRASyncByDB Instead")> _
    Private Sub JIRASyncByURL()
        Dim now As Date = DateTime.Now

        If (Not (now.Hour >= 7 And now.Hour <= 18) Or now.DayOfWeek = DayOfWeek.Saturday Or now.DayOfWeek = DayOfWeek.Sunday) Then 'Don't run if not between 8am and 5pm
            Return
        End If

        _checkJIRA = DBControl.DAL.Remi.HasAccess("RemiTimedServiceCheckJIRA")

        If (_checkJIRA) Then
            Dim sb As New StringBuilder
            Dim succeeded As Boolean = True
            Dim sbSource As StringBuilder
            Dim request As HttpWebRequest
            Dim response As HttpWebResponse = Nothing
            Dim reader As StreamReader
            Dim dtServices As DataTable = DBControl.DAL.Remi.GetServicesAccess(Nothing)
            Dim requests As New List(Of String)
            Dim ebs As DBControl.remiAPI.BatchSearchBatchStatus() = New DBControl.remiAPI.BatchSearchBatchStatus() {DBControl.remiAPI.BatchSearchBatchStatus.Complete, DBControl.remiAPI.BatchSearchBatchStatus.Rejected, DBControl.remiAPI.BatchSearchBatchStatus.Held, DBControl.remiAPI.BatchSearchBatchStatus.NotSavedToREMI, DBControl.remiAPI.BatchSearchBatchStatus.Quarantined, DBControl.remiAPI.BatchSearchBatchStatus.Received}
            Dim url As String = String.Empty
            Dim counter As Integer = 0
            _sendSuccessEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendSuccessEmails")

            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, DBControl.DAL.Remi.WSUrl))
            sb.AppendLine(String.Format("{0} - JIRA Check Starting...", DateTime.Now))

            For Each department As DataRow In (From s As DataRow In dtServices.Rows Where s.Field(Of String)("ServiceName") = "JIRASync" Select s).ToList
                Dim bv As DBControl.remiAPI.BatchView() = DBControl.DAL.Remi.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, department.Field(Of String)("Values").ToString(), String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, DBControl.remiAPI.TrackingLocationFunction.NotSet, String.Empty, DBControl.remiAPI.BatchStatus.NotSet, DBControl.remiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, DBControl.remiAPI.TestStageType.NotSet)
                requests.AddRange((From rs As DBControl.remiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())
                sb.AppendLine(String.Format("{0} - Adding Requests For Department {1}", DateTime.Now, department.Field(Of String)("Values").ToString()))
            Next

            Try
                sb.AppendLine(String.Format("{0} - Building URL", DateTime.Now))
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
                sb.AppendLine(String.Format("{0} - Finished Building/Executing URL", DateTime.Now))

                If request.HaveResponse = True AndAlso Not (response Is Nothing) Then
                    reader = New StreamReader(response.GetResponseStream())
                    sbSource = New StringBuilder(reader.ReadToEnd())
                    sb.AppendLine(String.Format("{0} - Read Response", DateTime.Now))

                    Dim jiraSerialized As Dictionary(Of String, Object) = New JavaScriptSerializer().Deserialize(Of Object)(sbSource.ToString())

                    For Each rec In DirectCast(jiraSerialized("issues"), Object())
                        Dim key As String = rec("key")
                        Dim title As String = DirectCast(rec("fields"), Dictionary(Of String, Object))("summary")
                        Dim requestNumber As String = String.Empty

                        For Each l In DirectCast(rec("fields"), Dictionary(Of String, Object))("labels")
                            If Regex.IsMatch(l.ToString(), "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}$") Then
                                requestNumber = l.ToString()
                                sb.AppendLine(String.Format("{0} - Found Request {1}", DateTime.Now, requestNumber))
                            End If
                        Next

                        Dim dtJIRA As DataTable = DBControl.DAL.Remi.GetBatchJIRA(requestNumber)
                        Dim jira As DataRow = (From j As DataRow In dtJIRA Where j.Field(Of String)("DisplayName") = key Select j).FirstOrDefault()

                        counter += 1

                        If (jira Is Nothing) Then
                            sb.AppendLine(String.Format("{0} - Inserting To REMI", DateTime.Now))
                            DBControl.DAL.Remi.AddEditJira(requestNumber, 0, key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                        Else
                            sb.AppendLine(String.Format("{0} - Editing In REMI", DateTime.Now))
                            DBControl.DAL.Remi.AddEditJira(requestNumber, jira.Field(Of Int32)("JIRAID"), key, String.Format("{0}browse/{1}", ConfigurationManager.AppSettings("JIRALink").ToString(), key), title)
                        End If
                    Next
                End If
            Catch wex As WebException
                succeeded = False
                sb.AppendLine(String.Format("{0} - Message: {1}{2}StackTrace: {3}{4}{5}", DateTime.Now, wex.Message, Environment.NewLine, wex.StackTrace.ToString(), Environment.NewLine, url))
            Catch err As Exception
                succeeded = False
                sb.AppendLine(String.Format("{0} - Message: {1}{2}StackTrace: {3}{4}{5}", DateTime.Now, err.Message, Environment.NewLine, err.StackTrace.ToString(), Environment.NewLine, url))
            Finally
                If Not response Is Nothing Then response.Close()
            End Try

            If (Not (succeeded) Or _sendSuccessEmails) Then
                sb.AppendLine(String.Format("{0} - Finished Executing {1} JIRA's", DateTime.Now, counter))
                Helpers.SendMail(String.Format("JIRA Check Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        End If
    End Sub

    Private Sub BatchStartedBeforeAssigned()
        Dim now As Date = DateTime.Now

        If (now.DayOfWeek = DayOfWeek.Saturday Or now.DayOfWeek = DayOfWeek.Sunday) Then 'Don't run if not between 7am and 5pm
            Return
        End If

        _sendNotAssignedEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendNotAssignedEmails")

        If (_sendNotAssignedEmails) Then
            _sendSuccessEmails = DBControl.DAL.Remi.HasAccess("RemiTimedServiceSendSuccessEmails")
            Dim sb As New StringBuilder
            Dim countStarted As Int32 = 0
            Dim succeeded As Boolean = True

            sb.AppendLine(String.Format("{0} - Service Running On: {1}", DateTime.Now, System.Environment.MachineName))
            sb.AppendLine(String.Format("{0} - WebService URL: {1}", DateTime.Now, DBControl.DAL.Remi.WSUrl))
            sb.AppendLine(String.Format("{0} - JIRA Check Starting...", DateTime.Now))

            Try
                Dim requests As New List(Of String)
                Dim ebs As DBControl.remiAPI.BatchSearchBatchStatus() = New DBControl.remiAPI.BatchSearchBatchStatus() {DBControl.remiAPI.BatchSearchBatchStatus.Complete, DBControl.remiAPI.BatchSearchBatchStatus.Rejected, DBControl.remiAPI.BatchSearchBatchStatus.Held, DBControl.remiAPI.BatchSearchBatchStatus.NotSavedToREMI, DBControl.remiAPI.BatchSearchBatchStatus.Quarantined, DBControl.remiAPI.BatchSearchBatchStatus.Received}
                Dim bv As DBControl.remiAPI.BatchView() = DBControl.DAL.Remi.SearchBatch("remi", String.Empty, DateTime.MinValue, DateTime.MaxValue, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, DBControl.remiAPI.TrackingLocationFunction.NotSet, String.Empty, DBControl.remiAPI.BatchStatus.NotSet, DBControl.remiAPI.TrackingLocationFunction.NotSet, Nothing, ebs, DBControl.remiAPI.TestStageType.NotSet)
                requests.AddRange((From rs As DBControl.remiAPI.BatchView In bv Select rs.QRANumber).Distinct.ToList())

                For Each req In requests
                    If (DBControl.DAL.Remi.BatchStartedBeforeAssigned(req)) Then
                        countStarted += 1
                        sb.AppendLine(String.Format("{0} - BatchStarted Before Assigned For {1}", DateTime.Now, req))
                        Helpers.SendMail(String.Format("BatchStarted Before Assigned For {0}...", req), req)
                    End If
                Next
            Catch wex As WebException
                succeeded = False
                sb.AppendLine(String.Format("{0} - Message: {1}{2}StackTrace: {3}", DateTime.Now, wex.Message, Environment.NewLine, wex.StackTrace.ToString()))
            Catch err As Exception
                succeeded = False
                sb.AppendLine(String.Format("{0} - Message: {1}{2}StackTrace: {3}", DateTime.Now, err.Message, Environment.NewLine, err.StackTrace.ToString()))
            End Try

            If (Not (succeeded) Or _sendSuccessEmails) Then
                sb.AppendLine(String.Format("{0} - Finished Executing {1} Requests Started", DateTime.Now, countStarted))
                Helpers.SendMail(String.Format("BatchStarted Before Assigned Complete{0}...", IIf(Not (succeeded), " - Failed", String.Empty)), sb.ToString)
            End If
        End If
    End Sub
#End Region
End Class