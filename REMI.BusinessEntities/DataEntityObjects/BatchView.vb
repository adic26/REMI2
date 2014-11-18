Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Xml.Serialization
Imports System.Xml.XPath.Extensions

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class BatchView
        Inherits BatchBase
        Implements ITaskList

        Private _testUnits As TestUnitCollection
        Private _testRecords As TestRecordCollection
        Private _taskList As List(Of ITaskModel)

        Public Sub New()
            _taskList = New List(Of ITaskModel)
            _testRecords = New TestRecordCollection
            _testUnits = New TestUnitCollection
        End Sub

        Public Sub New(ByVal qraNumber As String)
            MyBase.New(qraNumber)
            _taskList = New List(Of ITaskModel)
            _testRecords = New TestRecordCollection
            _testUnits = New TestUnitCollection
        End Sub

        Public Sub New(ByVal reqData As RequestFieldsCollection)
            MyBase.New(reqData)
            _taskList = New List(Of ITaskModel)
            _testRecords = New TestRecordCollection
            _testUnits = New TestUnitCollection
        End Sub

        <XmlIgnore()> _
        Public Property Tasks() As System.Collections.Generic.List(Of Contracts.ITaskModel) Implements Contracts.ITaskList.Tasks
            Get
                Return _taskList
            End Get
            Set(ByVal value As System.Collections.Generic.List(Of Contracts.ITaskModel))
                value = _taskList
            End Set
        End Property

        Public Property TestUnits() As TestUnitCollection
            Get
                Return _testUnits
            End Get
            Set(ByVal value As TestUnitCollection)
                _testUnits = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property RequestFields() As RequestFieldsCollection
            Get
                Return ReqData
            End Get
        End Property

        <XmlIgnore()> _
        Public Property TestRecords() As TestRecordCollection
            Get
                Return _testRecords
            End Get
            Set(ByVal value As TestRecordCollection)
                _testRecords = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property TestRecords(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal jobName As String, ByVal testUnitID As Int32) As TestRecordCollection
            Get
                Dim trColl As New TestRecordCollection
                trColl.Add((From tr In _testRecords Where tr.QRANumber = qraNumber And (testName = String.Empty Or tr.TestName = testName) And (testStageName = String.Empty Or tr.TestStageName = testStageName) And (jobName = String.Empty Or tr.JobName = jobName) And (testUnitID = 0 Or tr.TestUnitID = testUnitID) Select tr).ToList)

                Return trColl
            End Get
            Set(ByVal value As TestRecordCollection)
                _testRecords = value
            End Set
        End Property

        Public Function UnitIsExempt(ByVal testStageName As String, ByVal testName As String, ByVal unitNumber As Integer) As Boolean
            Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageName = testStageName AndAlso t.TestName = testName Select t).FirstOrDefault
            If task IsNot Nothing Then
                Return Not task.UnitsForTask.Contains(unitNumber)
            End If
            'default to exempt
            Return True
        End Function

        <XmlIgnore()> _
        Public Overridable ReadOnly Property PercentageComplete() As Integer
            Get
                If Me.Status = BatchStatus.Complete OrElse Me.Status = BatchStatus.TestingComplete Then
                    Return 100
                End If
                'Get total teststage count
                Dim totalTeststageCount As IEnumerable(Of String) = (From task In Tasks Where task.ProcessOrder > 0 AndAlso task.TestStageType <> TestType.NotSet And task.IsArchived = False And task.TestIsArchived = False Select task.TestStageName).Distinct()

                'get complete teststage count
                Dim currentTSProcessOrder As Integer = (From ts In Tasks Where ts.TestStageName = Me.TestStageName And ts.IsArchived = False And ts.TestIsArchived = False Select ts.ProcessOrder).FirstOrDefault()
                Dim completeTestStageCount As Integer = (From task In Tasks Where task.ProcessOrder > 0 And task.IsArchived = False And task.TestIsArchived = False AndAlso task.ProcessOrder < currentTSProcessOrder AndAlso task.TestStageType <> TestType.NotSet Select task.TestStageName).Distinct().Count()
                'result = complete / total *100
                Dim result As Double = 0
                If totalTeststageCount.Count > 0 Then
                    result = (completeTestStageCount / totalTeststageCount.Count) * 100
                End If
                Return Convert.ToInt32(result)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property GetExpectedCompletionDateTime() As String
            Get
                If EstTSCompletionTime > 0 Then
                    Return DateTime.Now.AddHours(EstTSCompletionTime).ToString("MM/dd/yy hh:mm tt")
                Else
                    Return String.Empty
                End If
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property GetExpectedJobCompletionDateTime() As String
            Get
                If EstJobCompletionTime > 0 Then
                    Return DateTime.Now.AddHours(EstJobCompletionTime).ToString("MM/dd/yy hh:mm tt")
                Else
                    Return String.Empty
                End If
            End Get
        End Property

#Region "Public Table Views"
        ''' <summary>
        ''' This function returns a link which is placed in the daily list tables. 
        ''' It contains the overview of testing for each test unit in a batch for the particular test.
        ''' </summary>
        ''' <param name="testName"></param>
        ''' <param name="testStageName"></param>
        ''' <returns></returns>
        ''' <remarks>The strings use html &quot; becuase they are sitting in javascript links.</remarks>
        Public Function GetPopupStringForDailyListTableCell(ByVal testName As String, ByVal testStageName As String, ByVal rqResults As DataTable) As String
            Dim retStr As New System.Text.StringBuilder
            If TestUnits IsNot Nothing Then
                retStr.Append("<a href=&quot;")
                retStr.Append(Me.RelabResultLink)
                retStr.Append("&quot;>View Results</a><br/>")
                retStr.Append(String.Format("<a target=&quot;_blank&quot; href=&quot;/Relab/Versions.aspx?TestID=###TESTID####&Batch={0}&quot;>Version History</a> <br />", Me.ID))

                For Each tu As TestUnit In TestUnits
                    retStr.Append("<a href=&quot;")
                    retStr.Append(tu.UnitInfoLink)
                    retStr.Append("&quot;>")
                    retStr.Append(tu.BatchUnitNumber)
                    retStr.Append("</a> - ")

                    If UnitIsExempt(testStageName, testName, tu.BatchUnitNumber) Then
                        retStr.Append("DNP") 'Unit should not be tested here
                        retStr.Append("<br />")
                    Else
                        Dim tr As TestRecord = TestRecords.GetItem(Me.JobName, testStageName, testName, tu.BatchUnitNumber)

                        If (tr IsNot Nothing) Then
                            retStr = retStr.Replace("###TESTID####", tr.TestID.ToString())
                        End If

                        If tr IsNot Nothing Then  'if there is a test record for this unit for this test
                            Dim resultID As Int32 = (From rq In rqResults.AsEnumerable() _
                                                     Where rq.Field(Of Int32)("TestID") = tr.TestID _
                                                     And rq.Field(Of Int32)("TestStageID") = tr.TestStageID _
                                                     And rq.Field(Of Int32)("UN") = tu.BatchUnitNumber _
                                                     Select rq.Field(Of Int32)("RID")).FirstOrDefault()

                            If (resultID > 0) Then
                                retStr.Append(String.Format("<a target=&quot;_blank&quot; href=&quot;/Relab/Measurements.aspx?ID={0}&Batch={1}&quot;>RQ</a> - ", resultID, Me.ID))
                            End If

                            If tr.FailDocs.Count > 0 Then
                                For fdNumber As Integer = tr.FailDocs.Count - 1 To 0 Step -1
                                    If tr.FailDocs(fdNumber) IsNot Nothing Then
                                        Select Case tr.FailDocs(fdNumber).Item("RequestType")
                                            Case "FA" 'if its an FA then display the number and link too
                                                retStr.Append("FA (<a href=&quot;")
                                        End Select
                                        retStr.Append(tr.FailDocs(fdNumber).Item("Request Link"))
                                        retStr.Append("&quot;>")
                                        retStr.Append(tr.FailDocs(fdNumber).Item("RequestNumber"))
                                        retStr.Append("</a>)")
                                        If fdNumber > 0 Then
                                            retStr.Append("<br />")
                                        End If
                                    End If
                                Next
                            Else
                                retStr.Append(tr.Status.ToString) 'otherwise just put in the status)
                            End If
                            If Not (Me.TestStageName = tu.CurrentTestStageName) Then
                                retStr.Append(" *") 'indicate if the unit is at a different ts to the batch
                            End If
                            Dim i As Integer = tu.BatchUnitNumber
                            If (From trF In Me.TestRecords Where trF.BatchUnitNumber.Equals(i) AndAlso trF.Status.Equals(TestRecordStatus.FARaised) Select trF).Count > 0 Then
                                retStr.Append(" ^") 'indicate if the unit is currently in FA for a different test/teststage
                            End If
                            retStr.Append(String.Format("&nbsp;{0}", tr.CurrentRelabResultVersion))
                            If tr.ResultSource = TestResultSource.Manual Then
                                retStr.Append("<img src=&quot;" + System.Web.VirtualPathUtility.ToAbsolute("~/Design/Icons/png/16x16/user.png") + "&quot; title=&quot;" + tr.LastUser + "&quot;/>")
                            End If

                            retStr.Append("<br />") 'add the testing comments
                            If Not String.IsNullOrEmpty(tr.Comments) Then
                                retStr.Append(System.Web.HttpContext.Current.Server.HtmlEncode(tr.Comments))
                                retStr.Append("<br />")
                            End If
                        Else
                            retStr.Append("No Record") 'otherwise there is no record here and we dont know anything.
                            retStr.Append("<br />")
                        End If
                    End If
                Next
            End If
            Return retStr.ToString
        End Function

        Public Overrides Function GetTestOverviewCellString(ByVal jobName As String, ByVal testStageName As String, ByVal TestName As String, ByVal hasEditAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal rqResults As DataTable, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean) As String
            If TestUnits.Count <= 0 Then
                Return "0 Units"
            Else
                If (From t In Tasks Where t.TestStageName = testStageName AndAlso t.TestName = TestName Select t).FirstOrDefault() Is Nothing Then
                    If (Me.Status = BatchStatus.Complete) Then
                        Return "N/A"
                    Else
                        Return "DNP"
                    End If
                Else
                    Dim numTestableUnits As Integer = NumberOfTestableUnits(testStageName, TestName)
                    Dim overallStatus As TestRecordStatus = TestRecords.GetOverallTestStatus(jobName, testStageName, TestName, numTestableUnits)

                    If overallStatus <> TestRecordStatus.NotSet Then
                        Dim popUpString As String = GetPopupStringForDailyListTableCell(TestName, testStageName, rqResults)

                        Dim baseLinkAll As String = String.Format("<a href=""{0}"" onmouseover=""Tip('{1}',STICKY,'true',CLICKCLOSE,'true',CLOSEBTN,'true',WIDTH,'-600',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()"">{{0}}</a>", REMIWebLinks.GetTestRecordsLink(System.Web.HttpContext.Current.Server.UrlEncode(Me.QRANumber), TestName, testStageName, Me.JobName, 0), popUpString)
                        'finally get the actual text displayed in the cell and format it in.

                        If (showHyperlinks) Then
                            Return String.Format(baseLinkAll, overallStatus)
                        Else
                            Return overallStatus.ToString()
                        End If

                    Else
                        Dim exceptionedUnits As Integer = Me.NumberOfUnits - numTestableUnits
                        If (hasEditAuthority Or isTestCenterAdmin Or hasBatchSetupAuthority) Then
                            Return (String.Format("<label style""font-color:red"">{0}&nbsp;</Label><label id='label{1}' class=""DNP""></label><input title=""Add Exception"" type=""checkbox"" id=""{1}"" value="""" onClick=""this.disabled=true;JavaScript: AddException('{2}','{3}','{4}','{5}','{6}', '0');"" />", IIf(exceptionedUnits > 0, exceptionedUnits.ToString() + " Exc", String.Empty), jobName + testStageName + TestName + Me.QRANumber + "0", jobName, testStageName, TestName, Me.QRANumber, Me.NumberOfUnits))
                        Else
                            Return String.Empty
                        End If
                    End If
                End If
            End If
        End Function

        Public Function GetOverviewCellString(ByVal jobName As String, ByVal testStageName As String, ByVal TestName As String) As String
            If (From t In Tasks Where t.TestStageName = testStageName AndAlso t.TestName = TestName Select t).FirstOrDefault() Is Nothing Then
                If (Me.Status = BatchStatus.Complete) Then
                    Return "N/A"
                Else
                    Return "DNP"
                End If
            Else
                Dim overallStatus As TestRecordStatus = TestRecords.GetOverallTestStatus(jobName, testStageName, TestName, NumberOfTestableUnits(testStageName, TestName))

                If overallStatus <> TestRecordStatus.NotSet Then
                    Return overallStatus.ToString
                Else
                    Return String.Empty
                End If
            End If
        End Function

        Public Function NumberOfTestableUnits(ByVal testStageName As String, ByVal testName As String) As Integer
            Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageName = testStageName AndAlso t.TestName = testName Select t).FirstOrDefault

            If task IsNot Nothing Then
                Return task.UnitsForTask.Count
            End If
            Return 0
        End Function

        Public Function GetEnvTestOverviewCellString(ByVal unitNumber As Integer, ByVal testStageName As String, ByVal hasEditItemAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal hasBatchSetupAuthority As Boolean) As String
            Dim tr As TestRecord = TestRecords.GetItem(Me.JobName, testStageName, testStageName, unitNumber)
            Dim TestTimeRemaining As Double = 0
            Dim outDate As String = String.Empty
            Dim units = (From task In Tasks Where task.TestStageName = testStageName And task.TestName = testStageName Select task.UnitsForTask).Distinct

            If (Array.IndexOf(units.ToArray(0), unitNumber) < 0) Then
                Return "DNP"
            ElseIf tr IsNot Nothing AndAlso tr.Status <> TestRecordStatus.NotSet Then
                Dim retString As String = tr.Status.ToString
                Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageName = testStageName AndAlso t.TestName = testStageName Select t).FirstOrDefault

                If task IsNot Nothing AndAlso task.ResultBaseOnTime Then
                    TestTimeRemaining = task.ExpectedDuration.TotalHours - tr.TotalTestTimeInHours
                    If TestTimeRemaining >= 24 And tr.Status = TestRecordStatus.InProgress Then
                        outDate = " (" + DateTime.Now.AddHours(TestTimeRemaining).ToString("dd/MM/yy") + ")"
                    End If

                    retString = String.Format("{0} {1:f1}/{2:f1}h{3}", retString, tr.TotalTestTimeInHours, task.ExpectedDuration.TotalHours, outDate)
                End If
                Return retString
            Else
                If (hasEditItemAuthority Or isTestCenterAdmin Or hasBatchSetupAuthority) Then
                    Return (String.Format("<label style""font-color:red"">{0}&nbsp;</Label><label id='label{1}' class=""DNP""></label><input title=""Add Exception"" type=""checkbox"" id=""{1}"" value="""" onClick=""this.disabled=true;JavaScript: AddException('{2}','{3}','{4}','{5}','{6}', '{7}');"" />", String.Empty, JobName + testStageName + testStageName + Me.QRANumber + unitNumber.ToString(), JobName, testStageName, testStageName, Me.QRANumber, 0, unitNumber))
                Else
                    Return String.Empty
                End If
            End If

            Return String.Empty
        End Function

        Public Function GetParametricTestOverviewTable(ByVal hasEditItemAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal rqResults As DataTable, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean) As DataTable
            Dim dt As New DataTable("TestingSummary")
            dt.Columns.Add("Test Stage")

            Dim applicableParamtericTests As String() = (From task In Tasks Where task.TestType = TestType.Parametric Order By task.TestName Ascending Select task.TestName).Distinct().ToArray()
            For Each t As String In applicableParamtericTests
                If Not dt.Columns.Contains(t) Then
                    dt.Columns.Add(t)
                End If
            Next

            Dim r As DataRow
            Dim num = (From task In Tasks Where task.TestStageType = TestType.Parametric AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.ProcessOrder).Distinct.Count()

            For Each ts In (From task In Tasks Where task.TestStageType = TestType.Parametric AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.ProcessOrder).Distinct
                r = dt.NewRow

                If (showHyperlinks) Then
                    r.Item("Test Stage") = String.Format("<A href=""{0}"" target=""_blank"">{1}</A>", REMI.Core.REMIWebLinks.GetTestRecordsLink(Me.QRANumber, Nothing, ts.TestStageName, Nothing, 0), ts.TestStageName)
                Else
                    r.Item("Test Stage") = ts.TestStageName
                End If

                For Each t As String In applicableParamtericTests
                    Dim text As String = GetTestOverviewCellString(Me.JobName, ts.TestStageName, t, hasEditItemAuthority, isTestCenterAdmin, rqResults, hasBatchSetupAuthority, showHyperlinks)
                    r.Item(t) = text
                Next
                dt.Rows.Add(r)
            Next

            For Each t As String In applicableParamtericTests
                Dim paraTest As String = t
                Dim distinctRowCount() As DataRow = (From row As DataRow In dt.Rows.Cast(Of DataRow)() Where row.Field(Of String)(paraTest) = "DNP" Select row).ToArray

                If (distinctRowCount.Count() = num And num > 0) Then
                    dt.Columns.Remove(t)
                End If

                Dim distinctRowNACount() As DataRow = (From row As DataRow In dt.Rows.Cast(Of DataRow)() Where row.Field(Of String)(paraTest) = "N/A" Select row).ToArray

                If (distinctRowNACount.Count() = num And num > 0) Then
                    dt.Columns.Remove(t)
                End If
            Next
            Return dt
        End Function

        Public Function GetStressingOverviewTable(ByVal hasEditItemAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean, ByVal orientation As String) As DataTable
            If (orientation = String.Empty) Then
                orientation = "<Orientations />"
            End If

            Dim orientationXML As XDocument = XDocument.Parse(orientation)
            Dim dt As New DataTable("StressingSummary")
            dt.Columns.Add("Test Unit")
            Dim applicableTestStages = (From task In Tasks Where task.TestStageType = TestType.EnvironmentalStress AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName).Distinct

            'add all the columns
            For Each ts In applicableTestStages
                dt.Columns.Add(ts)
            Next

            'add the data
            For Each tu As TestUnit In Me.TestUnits
                Dim r As DataRow = dt.NewRow

                If (showHyperlinks) Then
                    r.Item("Test Unit") = String.Format("<A href=""{0}"" target=""_blank"">{1}</A>", REMI.Core.REMIWebLinks.GetTestRecordsLink(Me.QRANumber, Nothing, Nothing, Nothing, tu.ID), tu.BatchUnitNumber)
                Else
                    r.Item("Test Unit") = tu.BatchUnitNumber
                End If

                For Each ts In applicableTestStages
                    Dim drop As String = ts.ToLower.Replace("drops", String.Empty).Replace("drop", String.Empty).Replace("tumbles", String.Empty).Replace("tumble", String.Empty).Trim()
                    r.Item(ts) = GetEnvTestOverviewCellString(tu.BatchUnitNumber, ts, hasEditItemAuthority, isTestCenterAdmin, hasBatchSetupAuthority)

                    Dim orientationDesc As String = GetOrientationSetting(drop, tu.BatchUnitNumber.ToString(), orientationXML)

                    If (Not String.IsNullOrEmpty(orientationDesc)) Then
                        r.Item(ts) = String.Format("{0} {1}{2}{3}", r.Item(ts).ToString(), If(showHyperlinks, "<b>", String.Empty), orientationDesc, If(showHyperlinks, "</b>", String.Empty))
                    End If
                Next
                dt.Rows.Add(r)
            Next

            Return dt
        End Function

        Public Function GetOrientationSetting(ByVal drop As String, ByVal unit As String, ByVal doc As XDocument) As String
            Return (From el In doc.Root.Elements("Orientation") Where el.Attribute("Drop").Value = drop And el.Attribute("Unit").Value = unit Select el.Attribute("Description").Value).FirstOrDefault()
        End Function
#End Region

#Region "Batch Notifications"
        Public Function GetAllTestUnitNotifications(ByVal testUnitNumber As Integer) As NotificationCollection
            Dim tuNotifications As New NotificationCollection
            Dim tu As TestUnit = (From testUnit In TestUnits Where testUnit.BatchUnitNumber = testUnitNumber Select testUnit).FirstOrDefault()
            If tu IsNot Nothing Then
                For Each tr As TestRecord In TestRecords.FindByTestUnit(testUnitNumber)
                    Select Case tr.Status
                        Case TestRecordStatus.NeedsRetest
                            tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> has units requiring retest for {2}", REMIWebLinks.GetTestRecordsLink(Me.QRANumber, String.Empty, tu.CurrentTestStageName, Me.JobName, 0), tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.FARequired
                            tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> requires an FA number to be assigned for {2}", REMIWebLinks.GetTestRecordsLink(Me.QRANumber, String.Empty, tu.CurrentTestStageName, Me.JobName, 0), tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.WaitingForResult
                            tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> requires results to be assigned for {2}", REMIWebLinks.GetTestRecordsLink(Me.QRANumber, String.Empty, tu.CurrentTestStageName, Me.JobName, 0), tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.Quarantined
                            tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> has been quarantined for {2}", REMIWebLinks.GetTestRecordsLink(Me.QRANumber, String.Empty, tu.CurrentTestStageName, Me.JobName, 0), tu.FullQRANumber, tr.TestName), _
                                             NotificationType.Information)
                        Case TestRecordStatus.CompleteFail
                            If tr.TestStageName.ToLower <> "sample evaluation" OrElse (tr.TestStageName.ToLower = "sample evaluation" AndAlso Me.TestStageName.ToLower = "sample evaluation") Then 'we dont care about sample eval fails  once the test has moved past sample eval.
                                tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> has failed {2} and requires a review.", REMIWebLinks.GetTestRecordsLink(Me.QRANumber, String.Empty, tu.CurrentTestStageName, Me.JobName, 0), tu.FullQRANumber, tr.TestName), _
                                                 NotificationType.Warning)
                            End If
                    End Select
                Next
                If TestRecords.UnitIsInFA(testUnitNumber) Then
                    tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> {2}", tu.UnitInfoLink, tu.FullQRANumber, "is in FA"), NotificationType.Information)
                End If
                If Me.TestStageName <> tu.CurrentTestStageName Then
                    tuNotifications.AddWithMessage(String.Format("<a href=""{0}"">{1}</a> is currently at a different test stage ({2}) to the rest of the batch.", tu.UnitInfoLink, tu.FullQRANumber, tu.CurrentTestStage.Name), NotificationType.Information)
                End If
            Else
                tuNotifications.AddWithMessage(String.Format("Unit {0} not found or units Expected do not match the number of units added!", testUnitNumber), NotificationType.Warning)
            End If

            Return tuNotifications
        End Function

        Public Function GetAllTestUnitNotificationsWithoutLinks(ByVal testUnitNumber As Integer) As NotificationCollection
            Dim tuNotifications As New NotificationCollection
            Dim tu As TestUnit = (From testUnit In TestUnits Where testUnit.BatchUnitNumber = testUnitNumber Select testUnit).FirstOrDefault()
            If tu IsNot Nothing Then
                For Each tr As TestRecord In TestRecords.FindByTestUnit(testUnitNumber)
                    Select Case tr.Status
                        Case TestRecordStatus.NeedsRetest
                            tuNotifications.AddWithMessage(String.Format("{0} has units requiring retest for {1}", tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.FARequired
                            tuNotifications.AddWithMessage(String.Format("{0} requires an FA number to be assigned for {1}", tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.WaitingForResult
                            tuNotifications.AddWithMessage(String.Format("{0} requires results to be assigned for {1}", tu.FullQRANumber, tr.TestName), _
                                                       NotificationType.Information)
                        Case TestRecordStatus.Quarantined
                            tuNotifications.AddWithMessage(String.Format("{0} has been quarantined for {1}", tu.FullQRANumber, tr.TestName), _
                                             NotificationType.Information)
                        Case TestRecordStatus.CompleteFail
                            If tr.TestStageName.ToLower <> "sample evaluation" OrElse (tr.TestStageName.ToLower = "sample evaluation" AndAlso Me.TestStageName.ToLower = "sample evaluation") Then 'we dont care about sample eval fails  once the test has moved past sample eval.
                                tuNotifications.AddWithMessage(String.Format("{0} has failed {1} and requires a review.", tu.FullQRANumber, tr.TestName), _
                                                 NotificationType.Warning)
                            End If
                    End Select
                Next
                If TestRecords.UnitIsInFA(testUnitNumber) Then
                    tuNotifications.AddWithMessage(String.Format("{0} {1}", tu.FullQRANumber, "is in FA"), NotificationType.Information)
                End If
                If Me.TestStageName <> tu.CurrentTestStageName Then
                    tuNotifications.AddWithMessage(String.Format("{0} is currently at a different test stage ({1}) to the rest of the batch.", tu.FullQRANumber, tu.CurrentTestStage.Name), NotificationType.Information)
                End If
            Else
                tuNotifications.AddWithMessage(String.Format("Unit {0} not found or units Expected do not match the number of units added!", testUnitNumber), NotificationType.Warning)
            End If

            Return tuNotifications
        End Function

        Public Function GetAllNotifications(ByVal showHyperlinks As Boolean) As NotificationCollection
            If TestUnits IsNot Nothing Then
                Dim FACount As Integer
                For Each tu As TestUnit In TestUnits
                    If (showHyperlinks) Then
                        Me.Notifications.Add(GetAllTestUnitNotifications(tu.BatchUnitNumber))
                    Else
                        Me.Notifications.Add(GetAllTestUnitNotificationsWithoutLinks(tu.BatchUnitNumber))
                    End If

                    If TestRecords.UnitIsInFA(tu.BatchUnitNumber) Then
                        FACount += 1
                    End If
                Next

                Dim faRatio As Double = FACount / NumberOfUnits

                If faRatio > 0.5 Then
                    Me.Notifications.AddWithMessage(String.Format("{0} has {1:f2}% of the batch in FA.", QRANumber, faRatio * 100), NotificationType.Information)
                End If
            End If
            Return Me.Notifications
        End Function
#End Region

    End Class
End Namespace