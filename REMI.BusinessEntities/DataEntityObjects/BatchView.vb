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
        Private _exceptions As TestExceptionCollection
        Private _specificTestDurations As Dictionary(Of Integer, Double)
        Private _job As Job

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
        Public Property TestExceptions() As TestExceptionCollection
            Get
                Return _exceptions
            End Get
            Set(ByVal value As TestExceptionCollection)
                _exceptions = value
            End Set
        End Property

        Public Function GetTestRecordsToCheckForRelabUpdates() As TestRecordCollection
            Dim trColl As New TestRecordCollection
            Dim tr As TestRecord
            Dim testStage = (From t In Me.Tasks Where t.TestType = TestType.IncomingEvaluation Or t.TestType = TestType.Parametric Or t.TestName.ToLower.Contains("drop") Or t.TestName.ToLower.Contains("tumble") Select t.TestStageName, t.TestStageID).Distinct().ToList()

            For Each ts In testStage
                For Each t In (From test In Me.Tasks Where test.TestStageID = ts.TestStageID Select test).ToList()
                    For Each tu As TestUnit In Me.TestUnits
                        If Not Me.TestingIsCompleteAndReviewedOrNotRequired(ts.TestStageID, t.TestID, tu.BatchUnitNumber, t.TestType) Then
                            tr = Me.TestRecords.GetItem(Me.JobName, ts.TestStageID, t.TestID, tu.BatchUnitNumber)

                            If tr Is Nothing Then  'new result
                                tr = New TestRecord(Me.QRANumber, tu.BatchUnitNumber, Me.Job.Name, ts.TestStageName, t.TestName, tu.ID, String.Empty, t.TestID, ts.TestStageID)
                            End If
                            trColl.Add(tr)
                        End If
                    Next
                Next
            Next
            Return trColl
        End Function

        Public Function TestingIsCompleteAndReviewedOrNotRequired(ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitNumber As Integer, ByVal testType As TestType) As Boolean
            Dim currentTR As TestRecord = TestRecords.GetItem(JobName, testStageID, testID, unitNumber)

            If (currentTR IsNot Nothing) Then
                Dim tst As TestStageType = (From ts As TestStage In Me.Job.TestStages Where ts.ID = testStageID Select ts.TestStageType).FirstOrDefault()

                If (tst = TestStageType.IncomingEvaluation Or tst = TestStageType.NonTestingTask Or tst = TestStageType.FailureAnalysis) Then
                    Return True
                End If
            End If

            If (testType = Contracts.TestType.IncomingEvaluation And currentTR Is Nothing) Then
                Return False
            ElseIf TestExceptions.UnitIsExempt(unitNumber, testStageID, testID, Me.Tasks) Then
                Return True
            Else
                Return False
            End If
        End Function

        Public ReadOnly Property TestStage() As TestStage
            Get
                Return Job.TestStages.FindByName(TestStageName)
            End Get
        End Property

        <XmlIgnore()> _
        Public Property SpecificTestDurations() As Dictionary(Of Integer, Double)
            Get
                Return _specificTestDurations
            End Get
            Set(ByVal value As Dictionary(Of Integer, Double))
                _specificTestDurations = value
            End Set
        End Property

        Public Property Job() As Job
            Get
                Return _job
            End Get
            Set(ByVal value As Job)
                If value IsNot Nothing Then
                    _job = value
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property RequestFields() As RequestFieldsCollection
            Get
                Return ReqData
            End Get
        End Property

        Public Function GetRemstarMaterial() As remstarMaterial
            Dim rM As New remstarMaterial(Me.QRANumber, Me.ProductGroup)
            Return rM
        End Function

        Public Function GetExpectedTestStageDuration(ByVal testStageID As Integer) As Double
            Dim expectedDuration As Double
            Dim tmpTs As TestStage = (From ts As TestStage In Me.Job.TestStages Where ts.ID = testStageID And ts.IsArchived = False Select ts).Single

            For Each t As Test In tmpTs.Tests
                expectedDuration += GetExpectedTestDuration(t)
            Next

            Return expectedDuration
        End Function

        Public Function GetExpectedTestDuration(ByVal selectedTest As Test) As Double
            Dim expectedDuration As Double

            If selectedTest IsNot Nothing AndAlso SpecificTestDurations IsNot Nothing Then
                If Not (selectedTest.TestType = TestType.EnvironmentalStress AndAlso SpecificTestDurations.TryGetValue(selectedTest.ID, expectedDuration)) Then
                    expectedDuration = selectedTest.Duration.TotalHours
                End If
            End If
            Return expectedDuration
        End Function

        Public Function GetUnit(ByVal Unitnumber As Integer) As TestUnit
            'check if its a valid unit number for a unit in this batch
            If Unitnumber > 0 And Unitnumber <= NumberOfUnitsExpected Then
                Dim tu As TestUnit = TestUnits.FindByBatchUnitNumber(Unitnumber)
                If tu IsNot Nothing Then
                    Return tu
                Else
                    'create a new tu
                    tu = New TestUnit
                    tu.BatchUnitNumber = Unitnumber
                    tu.QRANumber = Me.QRANumber
                    tu.CurrentTestStage = (From ts As TestStage In Me.Job.TestStages Where ts.ProcessOrder >= 0 And ts.IsArchived = False Select ts).FirstOrDefault()
                    Me.TestUnits.Add(tu)
                    Return tu
                End If
            Else
                Return Nothing
            End If
        End Function

        Public Sub SetNewBatchStatus(ByVal status As BatchStatus)
            If Me.IsCompleteInRequest Then
                Me.Status = BatchStatus.Complete
            Else
                Me.Status = status
            End If
            Me.OutOfDate = True
        End Sub

        Public Function SetTestStage(ByVal testStageName As String) As Boolean
            Dim teststage As TestStage = Me.Job.GetTestStage(testStageName)
            If teststage IsNot Nothing Then
                Me.TestStageName = teststage.Name
                Me.TestStageID = teststage.ID
                CheckBatchTestStageStatus()
                Return True
            End If
            Return False
        End Function

        Public Function SetJob(ByVal j As Job) As NotificationCollection
            Dim nc As New NotificationCollection
            If j IsNot Nothing Then
                If TestUnits IsNot Nothing Then
                    For Each tu As TestUnit In TestUnits
                        If tu.IsInTest Then
                            nc.AddWithMessage(tu.FullQRANumber + " is currently in a test. the job for this batch cannot be changed until this test unit is out of test.", NotificationType.Errors)
                        End If
                    Next

                    If Not nc.HasErrors Then
                        Me.Job = j
                        Me.JobName = j.Name
                    End If
                End If
            End If
            Return nc
        End Function

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

        Public Function UnitIsExempt(ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitNumber As Integer) As Boolean
            Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t).FirstOrDefault
            If task IsNot Nothing Then
                Return Not task.UnitsForTask.Contains(unitNumber)
            End If
            'default to exempt
            Return True
        End Function

        <XmlIgnore()> _
        <DataTableColName("PercentageComplete")> _
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
        <DataTableColName("GetExpectedJobCompletionDateTime")> _
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
        Public Function GetOverviewCellString(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32) As String
            If (From t In Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t).FirstOrDefault() Is Nothing Then
                If (Me.Status = BatchStatus.Complete) Then
                    Return "N/A"
                Else
                    Return "DNP"
                End If
            Else
                Dim overallStatus As TestRecordStatus = TestRecords.GetOverallTestStatus(jobName, testStageID, testID, NumberOfTestableUnits(testStageID, testID))

                If overallStatus <> TestRecordStatus.NotSet Then
                    Return overallStatus.ToString
                Else
                    Return String.Empty
                End If
            End If
        End Function

        Public Function NumberOfTestableUnits(ByVal testStageID As Int32, ByVal testID As Int32) As Integer
            Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t).FirstOrDefault

            If task IsNot Nothing Then
                Return task.UnitsForTask.Count
            End If
            Return 0
        End Function

        ''' <summary>
        ''' This function returns a link which is placed in the daily list tables. 
        ''' It contains the overview of testing for each test unit in a batch for the particular test.
        ''' </summary>
        ''' <param name="testID"></param>
        ''' <param name="testStageID"></param>
        ''' <returns></returns>
        ''' <remarks>The strings use html &quot; becuase they are sitting in javascript links.</remarks>
        Public Function GetPopupStringForDailyListTableCell(ByVal testID As Int32, ByVal testStageID As Int32, ByVal rqResults As DataTable) As String
            Dim retStr As New System.Text.StringBuilder
            If TestUnits IsNot Nothing Then
                retStr.Append("<a href=&quot;")
                retStr.Append(Me.RelabResultLink)
                retStr.Append("&quot;>View Results</a><br/>")
                retStr.Append(String.Format("<a target=&quot;_blank&quot; href=&quot;/Relab/Versions.aspx?TestID=###TESTID####&Batch={0}&TestStageID=###TESTSTAGEID####&quot;>Version History</a> <br />", Me.ID))

                For Each tu As TestUnit In TestUnits
                    retStr.Append("<a href=&quot;")
                    retStr.Append(tu.UnitInfoLink)
                    retStr.Append("&quot;>")
                    retStr.Append(tu.BatchUnitNumber)
                    retStr.Append("</a> - ")

                    If UnitIsExempt(testStageID, testID, tu.BatchUnitNumber) Then
                        retStr.Append("DNP") 'Unit should not be tested here
                        retStr.Append("<br />")
                    Else
                        Dim tr As TestRecord = TestRecords.GetItem(Me.JobName, testStageID, testID, tu.BatchUnitNumber)
                        Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t).FirstOrDefault

                        If (tr IsNot Nothing) Then
                            retStr = retStr.Replace("###TESTID####", tr.TestID.ToString()).Replace("###TESTSTAGEID####", tr.TestStageID.ToString())
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

                            If (task.ResultCheck.Count > 0) Then
                                Dim resultComparison() As String = (From tsk In task.ResultCheck Where tsk.Split(New Char() {":"c}, System.StringSplitOptions.RemoveEmptyEntries)(0) = tu.BatchUnitNumber.ToString() Select tsk.Split(New Char() {":"c}, System.StringSplitOptions.RemoveEmptyEntries)(1).Split(New Char() {"-"c}, System.StringSplitOptions.RemoveEmptyEntries)).FirstOrDefault()

                                If (resultComparison.Count > 0 AndAlso resultComparison(0) <> resultComparison(1)) Then
                                    retStr.Append("Pending")
                                Else
                                    retStr.Append(tr.Status.ToString)
                                End If
                            Else
                                retStr.Append(tr.Status.ToString)
                            End If

                            If tr.FailDocs.Count > 0 Then
                                For fdNumber As Integer = tr.FailDocs.Count - 1 To 0 Step -1
                                    If tr.FailDocs(fdNumber) IsNot Nothing Then
                                        retStr.Append(String.Format(" (<a href=&quot;", tr.FailDocs(fdNumber).Item("Request Link")))
                                        retStr.Append("&quot;>")
                                        retStr.Append(tr.FailDocs(fdNumber).Item("RequestNumber"))
                                        retStr.Append("</a>)")
                                        If fdNumber > 0 Then
                                            retStr.Append("<br />")
                                        End If
                                    End If
                                Next
                            End If

                            If Not (Me.TestStageName = tu.CurrentTestStageName) Then
                                retStr.Append(" *") 'indicate if the unit is at a different ts to the batch
                            End If

                            If (From trF In Me.TestRecords Where trF.BatchUnitNumber.Equals(tu.BatchUnitNumber) AndAlso trF.Status.Equals(TestRecordStatus.FARaised) Select trF).Count > 0 Then
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

        Public Overrides Function GetTestOverviewCellString(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal hasEditAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal rqResults As DataTable, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean) As String
            If TestUnits.Count <= 0 Then
                Return "0 Units"
            Else
                Dim names = (From t In Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t.TestName, t.TestStageName).FirstOrDefault()
                If (From t In Tasks Where t.TestStageID = testStageID AndAlso t.TestID = testID Select t).FirstOrDefault() Is Nothing Then
                    If (Me.Status = BatchStatus.Complete) Then
                        Return "N/A"
                    Else
                        Return "DNP"
                    End If
                Else
                    Dim numTestableUnits As Integer = NumberOfTestableUnits(testStageID, testID)
                    Dim overallTestRecordStatus As TestRecordStatus = TestRecords.GetOverallTestStatus(jobName, testStageID, testID, numTestableUnits)
                    Dim overallStatus As String = String.Empty

                    If overallTestRecordStatus <> TestRecordStatus.NotSet Then
                        Dim popUpString As String = GetPopupStringForDailyListTableCell(testID, testStageID, rqResults)

                        Dim baseLinkAll As String = String.Format("<a href=""{0}"" onmouseover=""Tip('{1}',STICKY,'true',CLICKCLOSE,'true',CLOSEBTN,'true',WIDTH,'-600',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()"">{{0}}</a>", REMIWebLinks.GetTestRecordsLink(System.Web.HttpContext.Current.Server.UrlEncode(Me.QRANumber), names.TestName, names.TestStageName, Me.JobName, 0), popUpString)
                        'finally get the actual text displayed in the cell and format it in.

                        If (popUpString.ToLower.Contains("pending")) Then
                            overallStatus = "Pending"
                        Else
                            overallStatus = overallTestRecordStatus.ToString()
                        End If

                        If (showHyperlinks) Then
                            Return String.Format(baseLinkAll, overallStatus)
                        Else
                            Return overallStatus.ToString()
                        End If
                    Else
                        Dim exceptionedUnits As Integer = Me.NumberOfUnits - numTestableUnits
                        If (hasEditAuthority Or isTestCenterAdmin Or hasBatchSetupAuthority) Then
                            Return (String.Format("<label style""font-color:red"">{0}&nbsp;</Label><label id='label{1}' class=""DNP""></label><input title=""Add Exception"" type=""checkbox"" id=""{1}"" value="""" onClick=""this.disabled=true;JavaScript: AddException('{2}','{3}','{4}','{5}','{6}', '0');"" />", IIf(exceptionedUnits > 0, exceptionedUnits.ToString() + " Exc", String.Empty), jobName + names.TestStageName + names.TestName + Me.QRANumber + "0", jobName, names.TestStageName, names.TestName, Me.QRANumber, Me.NumberOfUnits))
                        Else
                            Return String.Empty
                        End If
                    End If
                End If
            End If
        End Function

        Public Function GetEnvTestOverviewCellString(ByVal unitNumber As Integer, ByVal testStageID As Int32, ByVal hasEditItemAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal hasBatchSetupAuthority As Boolean) As String
            Dim tr As TestRecord = TestRecords.GetItem(Me.JobName, testStageID, unitNumber)
            Dim TestTimeRemaining As Double = 0
            Dim outDate As String = String.Empty
            Dim units = (From task In Tasks Where task.TestStageID = testStageID Select task.UnitsForTask).Distinct

            If (Array.IndexOf(units.ToArray(0), unitNumber) < 0) Then
                Return "DNP"
            ElseIf tr IsNot Nothing AndAlso tr.Status <> TestRecordStatus.NotSet Then
                Dim retString As String = String.Empty
                Dim task As ITaskModel = (From t In Me.Tasks Where t.TestStageID = testStageID Select t).FirstOrDefault

                If (task.ResultCheck.Count > 0) Then
                    Dim resultComparison() As String = (From tsk In task.ResultCheck Where tsk.Split(New Char() {":"c}, System.StringSplitOptions.RemoveEmptyEntries)(0) = unitNumber.ToString() Select tsk.Split(New Char() {":"c}, System.StringSplitOptions.RemoveEmptyEntries)(1).Split(New Char() {"-"c}, System.StringSplitOptions.RemoveEmptyEntries)).FirstOrDefault()

                    If (resultComparison.Count > 0 AndAlso resultComparison(0) <> resultComparison(1)) Then
                        retString = "Pending"
                    Else
                        retString = tr.Status.ToString
                    End If
                Else
                    retString = tr.Status.ToString
                End If

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
                    Return (String.Format("<label style""font-color:red"">{0}&nbsp;</Label><label id='label{1}' class=""DNP""></label><input title=""Add Exception"" type=""checkbox"" id=""{1}"" value="""" onClick=""this.disabled=true;JavaScript: AddException('{2}','{3}','{4}','{5}','{6}', '{7}');"" />", String.Empty, JobName + TestStageName + TestStageName + Me.QRANumber + unitNumber.ToString(), JobName, TestStageName, TestStageName, Me.QRANumber, 0, unitNumber))
                Else
                    Return String.Empty
                End If
            End If

            Return String.Empty
        End Function

        Public Function GetParametricTestOverviewTable(ByVal hasEditItemAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal rqResults As DataTable, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean) As DataTable
            Dim dt As New DataTable("TestingSummary")
            dt.Columns.Add("Test Stage")

            Dim applicableParamtericTests = (From task In Tasks Where task.TestType = TestType.Parametric Order By task.TestName Ascending Select task.TestName, task.TestID).Distinct().ToArray()
            For Each t In applicableParamtericTests
                If Not dt.Columns.Contains(t.TestName) Then
                    dt.Columns.Add(t.TestName)
                End If
            Next

            Dim r As DataRow
            Dim num = (From task In Tasks Where task.TestStageType = TestType.Parametric AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.ProcessOrder).Distinct.Count()

            For Each ts In (From task In Tasks Where task.TestStageType = TestType.Parametric AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.ProcessOrder, task.TestStageID).Distinct

                r = dt.NewRow

                If (showHyperlinks) Then
                    r.Item("Test Stage") = String.Format("<A href=""{0}"" target=""_blank"">{1}</A>", REMI.Core.REMIWebLinks.GetTestRecordsLink(Me.QRANumber, Nothing, ts.TestStageName, Nothing, 0), ts.TestStageName)
                Else
                    r.Item("Test Stage") = ts.TestStageName
                End If

                For Each t In applicableParamtericTests
                    Dim text As String = GetTestOverviewCellString(Me.JobName, ts.TestStageID, t.TestID, hasEditItemAuthority, isTestCenterAdmin, rqResults, hasBatchSetupAuthority, showHyperlinks)
                    r.Item(t.TestName) = text
                Next
                dt.Rows.Add(r)
            Next

            For Each t In applicableParamtericTests
                Dim paraTest As String = t.TestName
                Dim distinctRowCount() As DataRow = (From row As DataRow In dt.Rows.Cast(Of DataRow)() Where row.Field(Of String)(paraTest) = "DNP" Select row).ToArray

                If (distinctRowCount.Count() = num And num > 0) Then
                    dt.Columns.Remove(t.TestName)
                End If

                Dim distinctRowNACount() As DataRow = (From row As DataRow In dt.Rows.Cast(Of DataRow)() Where row.Field(Of String)(paraTest) = "N/A" Select row).ToArray

                If (distinctRowNACount.Count() = num And num > 0) Then
                    dt.Columns.Remove(t.TestName)
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
            Dim applicableTestStages = (From task In Tasks Where task.TestStageType = TestType.EnvironmentalStress AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.TestStageID).Distinct

            If (applicableTestStages.Count > 0) Then
                'add all the columns
                For Each ts In applicableTestStages
                    dt.Columns.Add(ts.TestStageName)
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
                        Dim drop As String = ts.TestStageName.ToLower.Replace("drops", String.Empty).Replace("drop", String.Empty).Replace("tumbles", String.Empty).Replace("tumble", String.Empty).Trim()
                        r.Item(ts.TestStageName) = GetEnvTestOverviewCellString(tu.BatchUnitNumber, ts.TestStageID, hasEditItemAuthority, isTestCenterAdmin, hasBatchSetupAuthority)

                        Dim orientationDesc As String = GetOrientationSetting(drop, tu.BatchUnitNumber.ToString(), orientationXML)

                        If (Not String.IsNullOrEmpty(orientationDesc)) Then
                            r.Item(ts.TestStageName) = String.Format("{0} {1}{2}{3}", r.Item(ts.TestStageName).ToString(), If(showHyperlinks, "<b>", String.Empty), orientationDesc, If(showHyperlinks, "</b>", String.Empty))
                        End If
                    Next
                    dt.Rows.Add(r)
                Next
                Return dt
            Else
                Return Nothing
            End If
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

        Public Function CheckBatchTestStageStatus() As Boolean
            'check if there is a record for every testunit for every test in the teststage
            'that is not DNP and is not inprogress.
            'check that each test record has been reviewed and that this is not the last test stage.
            'if this is the last test stage just leave it at testing complete.
            Dim maxTestStageProcessOrder As Integer

            If Me.Job IsNot Nothing AndAlso Me.Job.TestStages.Count > 0 Then
                maxTestStageProcessOrder = (From ts In Me.Job.TestStages Where ts.IsArchived = False Select ts.ProcessOrder).Max
            End If

            If Me.TestStage IsNot Nothing AndAlso TestStageCompleteByStatus(Me.TestStageID, TestStageCompletionStatus.ProcessComplete) AndAlso _
            Me.TestStage.ProcessOrder < maxTestStageProcessOrder Then
                If Me.TestStageCompletion <> TestStageCompletionStatus.ReadyForNextStage Then
                    TestStageCompletion = TestStageCompletionStatus.ReadyForNextStage
                    Return True
                Else
                    Return False
                End If
            End If

            If TestStageCompleteByStatus(Me.TestStageID, TestStageCompletionStatus.TestingComplete) Then
                If TestStageCompletion <> TestStageCompletionStatus.TestingComplete Then
                    TestStageCompletion = TestStageCompletionStatus.TestingComplete
                    Return True
                Else
                    Return False
                End If
            End If

            If (Me.TestStage.ProcessOrder = maxTestStageProcessOrder) Then
                Dim teststage = (From ts In Me.Job.TestStages Where ts.TestStageType = TestStageType.FailureAnalysis Select ts.Name, ts.ID).FirstOrDefault()

                If (Me.TestRecords.FindByTestStage(Me.JobName, teststage.ID).Count() = 0 And Me.TestRecords.UnitIsInFA(Me.QRANumber)) Then
                    Me.Status = BatchStatus.InProgress
                    Me.SetTestStage(teststage.Name)
                    Return True
                End If
            End If

            If TestStageCompletion <> TestStageCompletionStatus.InProgress Then
                TestStageCompletion = TestStageCompletionStatus.InProgress
                Return True
            End If

            Return False
        End Function

        Public Function TestStageCompleteByStatus(ByVal teststageID As Int32, ByVal completionStatus As TestStageCompletionStatus) As Boolean
            Dim allUnitsAreInFA As Boolean = True
            Dim testStage As TestStage = (From ts In Me.Job.TestStages Where ts.ID = teststageID).FirstOrDefault()

            If TestUnits IsNot Nothing Then
                For Each tu As TestUnit In TestUnits
                    If (testStage.TestStageType = TestStageType.FailureAnalysis) Then
                        Dim FAAnalysisCount As Int32 = Me.TestRecords.FindByTestStageUnit(Me.JobName, teststageID, tu.BatchUnitNumber).Count()

                        If (Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber) And FAAnalysisCount > 0) Then
                            allUnitsAreInFA = False
                        ElseIf (Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber) And FAAnalysisCount = 0) Then
                            Return False
                        End If
                    Else
                        If (Not Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber, teststageID)) Then
                            allUnitsAreInFA = False

                            If CountUnTested(tu.BatchUnitNumber, teststageID, completionStatus) > 0 Then
                                Return False
                            End If
                        End If
                    End If
                Next
            End If

            If (REMI.Core.REMIConfiguration.EnableFA100Message) Then
                'if it got here there are no untested or unreviewed units so if not all units are in FA continue
                'if all the units are in fa stay here. it should be reviewed and manually moved forward.
                Return (Not allUnitsAreInFA)
            Else
                'Enable FA 100% failure disabled. Allow the batch to move forward.
                'If we got here than their are no untested or unreviewed units so continue.
                Return True
            End If
        End Function

        Public Function CountUnTested(ByVal unitNumber As Integer, ByVal testStageID As Int32, ByVal completionStatus As TestStageCompletionStatus) As Integer
            Dim count As Integer
            If Job.TestStages.FindByID(testStageID) IsNot Nothing Then
                For Each t As Test In Job.TestStages.FindByID(testStageID).Tests
                    Select Case completionStatus
                        Case TestStageCompletionStatus.ProcessComplete
                            If Not TestingCompleteOrNotRequired(Me.JobName, testStageID, t.ID, unitNumber, t.TestType) Then
                                count += 1
                            End If
                        Case TestStageCompletionStatus.TestingComplete
                            If Not TestingIsCompleteAndReviewedOrNotRequired(testStageID, t.ID, unitNumber, t.TestType) Then
                                count += 1
                            End If
                        Case Else
                    End Select
                Next
            End If
            Return count
        End Function

        Public Function TestingCompleteOrNotRequired(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitNumber As Integer, ByVal testType As TestType) As Boolean
            Dim currentTR As TestRecord = TestRecords.GetItem(jobName, testStageID, testID, unitNumber)

            If (testType = Contracts.TestType.IncomingEvaluation And (currentTR IsNot Nothing AndAlso (currentTR.Status <> TestRecordStatus.InProgress And currentTR.Status <> TestRecordStatus.NotSet And currentTR.Status <> TestRecordStatus.NeedsRetest))) Then
                Return True
            ElseIf testType <> Contracts.TestType.IncomingEvaluation And (TestExceptions.UnitIsExempt(unitNumber, testStageID, testID, Me.Tasks) OrElse _
                  (currentTR IsNot Nothing AndAlso (currentTR.Status <> TestRecordStatus.InProgress And currentTR.Status <> TestRecordStatus.NotSet And currentTR.Status <> TestRecordStatus.NeedsRetest))) Then
                Return True
            End If
            Return False
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