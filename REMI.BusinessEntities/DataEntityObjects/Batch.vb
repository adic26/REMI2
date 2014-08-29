Imports System.ComponentModel
Imports REMI.Validation
Imports System.Linq
Imports REMI.Contracts
Imports REMI.Core
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' The Batch class represents the information about the overall group of <see cref="TestUnit">Test Units</see> provided by the requestor for the test request. 
    ''' </summary> 
    <Serializable()> _
    Public Class Batch
        Inherits BatchView

#Region "Private Variables"
        Private _exceptions As TestExceptionCollection
        Private _job As Job
        'Private _FailParameters As ParameterResultCollection
        Private _specificTestDurations As Dictionary(Of Integer, Double)
        Private _IsBackToRequestor As Boolean
        Private _isCached As Boolean
#End Region

#Region "Constructor(s)"
        Private Sub BasicInitialisation()
            _job = New Job
            _specificTestDurations = New Dictionary(Of Integer, Double)
            _exceptions = New TestExceptionCollection
            '_FailParameters = New ParameterResultCollection
        End Sub

        ''' <summary>
        ''' Initializes a new instance of the Batch class. 
        ''' </summary>
        Public Sub New()
            MyBase.New()
            BasicInitialisation()
        End Sub

        ''' <summary>
        ''' Initializes a new instance of the Batch class. 
        ''' </summary>
        Public Sub New(ByVal QRAnumber As String)
            MyBase.New(QRAnumber)
            BasicInitialisation()
        End Sub

        ''' <summary>
        ''' Used to create a new batch
        ''' </summary>
        ''' <param name="trsData"></param>
        ''' <remarks></remarks>
        Public Sub New(ByVal trsData As IQRARequest)
            MyBase.New(trsData)
            BasicInitialisation()
            If trsData Is Nothing Then
                Me.Notifications.AddWithMessage("Unable to locate request.", NotificationType.Errors)
            End If
            Me.TRSData = trsData
            If Status = BatchStatus.NotSet Then
                Status = BatchStatus.NotSavedToREMI
            End If
        End Sub
#End Region

#Region "Public Properties"
        Public Property IsBackToRequestor() As Boolean
            Get
                Return _IsBackToRequestor
            End Get
            Set(ByVal value As Boolean)
                _IsBackToRequestor = value
            End Set
        End Property

        'Public Property FailParameters() As ParameterResultCollection
        '    Get
        '        Return _FailParameters
        '    End Get
        '    Set(ByVal value As ParameterResultCollection)
        '        _FailParameters = value
        '    End Set
        'End Property

        'collections and objects
        ''' <summary>
        ''' the exceptions related to this batch. includes test unit spoecific and product exceptions
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property TestExceptions() As TestExceptionCollection
            Get
                Return _exceptions
            End Get
            Set(ByVal value As TestExceptionCollection)
                _exceptions = value
            End Set
        End Property

        ''' <summary>
        ''' Gets and sets the job for the batch.
        ''' </summary>
        ''' <value>integer</value>
        ''' <returns>integer</returns>
        ''' <remarks></remarks>
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

        ''' <summary>
        ''' A collection of test durations for the batch
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <XmlIgnore()> _
        Public Property SpecificTestDurations() As Dictionary(Of Integer, Double)
            Get
                Return _specificTestDurations
            End Get
            Set(ByVal value As Dictionary(Of Integer, Double))
                _specificTestDurations = value
            End Set
        End Property

        Public ReadOnly Property TestStage() As TestStage
            Get
                Return Job.TestStages.FindByName(TestStageName)
            End Get
        End Property

        Public Sub SetNewBatchStatus()
            If Me.IsCompleteInTRS Then
                Me.Status = BatchStatus.Complete
            Else
                Me.Status = BatchStatus.Received
            End If
        End Sub
#End Region

#Region "Public Functions"
        ''' <summary>
        ''' Overrides the default to string and returns the qra number of the batch
        ''' </summary>
        ''' <returns>the QRA number of the batch.</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(QRANumber) Then
                Return String.Empty
            Else
                Return QRANumber
            End If
        End Function

        Public Function SetTestStage(ByVal testStageName As String) As Boolean
            If Me.Job.GetTestStage(testStageName) IsNot Nothing Then
                Me.TestStageName = testStageName
                CheckBatchTestStageStatus()
                Return True
            End If
            Return False
        End Function

        ''' <summary>
        ''' Checks the testrecords for the batch and updates the status of the test stage if required.
        ''' </summary>
        ''' <returns>True if the status has changed, False otherwise</returns>
        ''' <remarks></remarks>
        Public Function CheckBatchTestStageStatus() As Boolean
            'check if there is a record for every testunit for every test in the teststage
            'that is not DNP and is not inprogress.
            'check that each test record has been reviewed and that this is not the last test stage.
            'if this is the last test stage just leave it at testing complete.
            Dim maxTestStageProcessOrder As Integer

            If Me.Job IsNot Nothing AndAlso Me.Job.TestStages.Count > 0 Then
                maxTestStageProcessOrder = (From ts In Me.Job.TestStages Where ts.IsArchived = False Select ts.ProcessOrder).Max
            End If

            If Me.TestStage IsNot Nothing AndAlso TestStageCompleteByStatus(Me.TestStageName, TestStageCompletionStatus.ProcessComplete) AndAlso _
            Me.TestStage.ProcessOrder < maxTestStageProcessOrder Then
                If Me.TestStageCompletion <> TestStageCompletionStatus.ReadyForNextStage Then
                    TestStageCompletion = TestStageCompletionStatus.ReadyForNextStage
                    Return True
                Else
                    Return False
                End If
            End If

            If TestStageCompleteByStatus(Me.TestStageName, TestStageCompletionStatus.TestingComplete) Then
                If TestStageCompletion <> TestStageCompletionStatus.TestingComplete Then
                    TestStageCompletion = TestStageCompletionStatus.TestingComplete
                    Return True
                Else
                    Return False
                End If
            End If

            If (Me.TestStage.ProcessOrder = maxTestStageProcessOrder) Then
                Dim teststagename As String = (From ts In Me.Job.TestStages Where ts.TestStageType = TestStageType.FailureAnalysis Select ts.Name).FirstOrDefault()

                If (Me.TestRecords.FindByTestStage(Me.JobName, teststagename).Count() = 0 And Me.TestRecords.UnitIsInFA(Me.QRANumber)) Then
                    Me.Status = BatchStatus.InProgress
                    Me.SetTestStage(teststagename)
                    Return True
                End If
            End If

            If TestStageCompletion <> TestStageCompletionStatus.InProgress Then
                TestStageCompletion = TestStageCompletionStatus.InProgress
                Return True
            End If

            Return False
        End Function

        ''' <summary>
        ''' Selects the parametric and incoming eval type test records for the batch
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetTestRecordsToCheckForRelabUpdates() As TestRecordCollection
            Dim trColl As New TestRecordCollection
            Dim tr As TestRecord
            Dim testStage = (From t In Me.Tasks Where t.TestType = TestType.IncomingEvaluation Or t.TestType = TestType.Parametric Select t.TestStageName, t.TestStageID).Distinct().ToList()

            For Each ts In testStage
                For Each t In (From test In Me.Tasks Where test.TestStageID = ts.TestStageID And test.TestStageName = ts.TestStageName Select test).ToList()
                    For Each tu As TestUnit In Me.TestUnits
                        If Not Me.TestingIsCompleteAndReviewedOrNotRequired(ts.TestStageName, t.TestName, tu.BatchUnitNumber) Then
                            tr = Me.TestRecords.GetItem(Me.JobName, ts.TestStageName, t.TestName, tu.BatchUnitNumber, t.TestID, ts.TestStageID)

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

        Public Function CountUnTested(ByVal unitNumber As Integer, ByVal teststageName As String, ByVal completionStatus As TestStageCompletionStatus) As Integer
            Dim count As Integer
            If Job.TestStages.FindByName(teststageName) IsNot Nothing Then
                For Each t As Test In Job.TestStages.FindByName(teststageName).Tests
                    Select Case completionStatus
                        Case TestStageCompletionStatus.ProcessComplete
                            If Not TestingCompleteOrNotRequired(Me.JobName, teststageName, t.Name, unitNumber) Then
                                count += 1
                            End If
                        Case TestStageCompletionStatus.TestingComplete
                            If Not TestingIsCompleteAndReviewedOrNotRequired(teststageName, t.Name, unitNumber) Then
                                count += 1
                            End If
                        Case Else
                    End Select
                Next
            End If
            Return count
        End Function

        Public Function TestingCompleteOrNotRequired(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal unitNumber As Integer) As Boolean
            Dim currentTR As TestRecord = TestRecords.GetItem(jobName, testStageName, testName, unitNumber)

            If TestExceptions.UnitIsExempt(unitNumber, testStageName, testName, Me.Tasks) OrElse _
                 (currentTR IsNot Nothing AndAlso (currentTR.Status <> TestRecordStatus.InProgress And currentTR.Status <> TestRecordStatus.NotSet And currentTR.Status <> TestRecordStatus.NeedsRetest)) Then
                Return True
            End If
            Return False
        End Function

        Public Function TestingIsCompleteAndReviewedOrNotRequired(ByVal testStageName As String, ByVal testName As String, ByVal unitNumber As Integer) As Boolean
            Dim currentTR As TestRecord = TestRecords.GetItem(JobName, testStageName, testName, unitNumber)

            If (currentTR IsNot Nothing) Then
                Dim tst As TestStageType = (From ts As TestStage In Me.Job.TestStages Where ts.Name = testStageName Select ts.TestStageType).FirstOrDefault()

                If (tst = TestStageType.IncomingEvaluation And tst = TestStageType.NonTestingTask And tst = TestStageType.FailureAnalysis) Then
                    Return True
                End If
            End If

            If TestExceptions.UnitIsExempt(unitNumber, testStageName, testName, Me.Tasks) OrElse (currentTR IsNot Nothing AndAlso currentTR.RecordStatusIsProcessComplete) Then
                Return True
            ElseIf TestExceptions.UnitIsExempt(unitNumber, testStageName, testName, Me.Tasks) OrElse (currentTR IsNot Nothing AndAlso Me.Job.ContinueOnFailures AndAlso currentTR.RecordStatusIsProcessCompleteOrContinueOnFailure) Then
                Return True
            Else
                Return False
            End If
        End Function

        Public Function AdvanceToNextStageIfApplicable() As Boolean
            If TestStageCompletion = TestStageCompletionStatus.ReadyForNextStage AndAlso Me.TestStage IsNot Nothing Then
                Dim ts As TestStage = GetNextTestStage()

                If ts IsNot Nothing Then
                    Me.SetTestStage(ts.Name)
                    Return True
                End If
            End If
            Return False
        End Function

        Public Function AdvanceBatchToTestingCompleteIfApplicable() As Boolean
            If GetNextTestStage() Is Nothing Then

                If (TestStageCompletion = TestStageCompletionStatus.TestingComplete And Not (Me.IsCompleteInTRS)) Or (Me.TestStage.TestStageType = TestStageType.NonTestingTask And Not (Me.IsCompleteInTRS)) Then
                    If (Me.Status <> BatchStatus.TestingComplete) Then
                        Me.Status = BatchStatus.TestingComplete
                        Return True
                    End If

                    Return False
                End If
            End If
            Return False
        End Function

        Public Function GetNextTestStage() As TestStage
            If Me.TestStage IsNot Nothing Then
                Dim stage As TestStage = Nothing
                Dim processOrder As Int32 = Me.TestStage.ProcessOrder

                While stage Is Nothing
                    Dim temp As TestStage = (From ts As TestStage In Me.Job.TestStages Where ts.ProcessOrder > processOrder AndAlso ts.ProcessOrder >= 0 And ts.IsArchived = False Select ts).OrderBy(Function(ts) ts.ProcessOrder).FirstOrDefault()

                    If (temp Is Nothing) Then
                        Exit While
                    End If

                    processOrder = temp.ProcessOrder

                    Dim idVal As Int32 = (From t In Me.Job.TestStages Where t.ID = temp.ID Select t.ID).FirstOrDefault()

                    If (idVal > 0) Then
                        stage = temp
                    End If
                End While

                If (stage IsNot Nothing) Then
                    If (stage.TestStageType = TestStageType.FailureAnalysis And Me.TestRecords.UnitIsInFA(Me.QRANumber) = False) Then
                        stage = (From ts As TestStage In Me.Job.TestStages Where ts.ProcessOrder > stage.ProcessOrder AndAlso ts.ProcessOrder >= 0 And ts.IsArchived = False Select ts).OrderBy(Function(ts) ts.ProcessOrder).FirstOrDefault()
                    End If
                End If

                Return stage
            End If
            Return Nothing
        End Function

        ''' <summary>
        ''' This functions checks if all of the tests for a given teststage are complete for all units where the test is required.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function TestStageCompleteByStatus(ByVal teststageName As String, ByVal completionStatus As TestStageCompletionStatus) As Boolean
            Dim allUnitsAreInFA As Boolean = True
            Dim testStage As TestStage = (From ts In Me.Job.TestStages Where ts.Name = teststageName).FirstOrDefault()

            If TestUnits IsNot Nothing Then
                For Each tu As TestUnit In TestUnits
                    If (testStage.TestStageType = TestStageType.FailureAnalysis) Then
                        Dim FAAnalysisCount As Int32 = Me.TestRecords.FindByTestStageUnit(Me.JobName, Me.TestStageName, tu.BatchUnitNumber).Count()

                        If (Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber) And FAAnalysisCount > 0) Then
                            allUnitsAreInFA = False
                        ElseIf (Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber) And FAAnalysisCount = 0) Then
                            Return False
                        End If
                    Else
                        If (Not Me.TestRecords.UnitIsInFA(tu.BatchUnitNumber, teststageName)) Then
                            allUnitsAreInFA = False

                            If CountUnTested(tu.BatchUnitNumber, teststageName, completionStatus) > 0 Then
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

        ''' <summary>
        ''' Returns a test unit given the batch unit number
        ''' </summary>
        ''' <param name="Unitnumber">The batch unit number of the unit.</param>
        ''' <returns></returns>
        ''' <remarks></remarks>
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

        ''' <summary>
        ''' Sets the job name for a batch
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
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

        Public Function GetRemstarMaterial() As remstarMaterial
            Dim rM As New remstarMaterial(Me.QRANumber, Me.ProductGroup)
            Return rM
        End Function

        Public Function ApplicableParametricTests() As List(Of String)
            Dim l As New List(Of String)
            For Each t As Test In Me.Job.GetParametricTests
                If Not l.Contains(t.Name) AndAlso (Not Me.AllUnitsAreExemptFromTest(t.Name)) Then
                    l.Add(t.Name)
                End If
            Next
            Return l
        End Function

        Public Function GetUnitsAtLocation(ByVal barcodePrefix As Integer) As TestUnitCollection
            Return TestUnits.FindByLocation(barcodePrefix)
        End Function

        Public Function UnitIsInFA(ByVal unitnumber As Integer) As Boolean
            Return TestRecords.UnitIsInFA(unitnumber)
        End Function

        ''' <summary>
        ''' returns true if all units are exempt from test for all test stages.
        ''' </summary>
        ''' <param name="testName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Protected Function AllUnitsAreExemptFromTest(ByVal testName As String) As Boolean
            For Each s As String In (From ts In Job.TestStages Where ts.TestStageType = TestStageType.Parametric And ts.IsArchived = False Select ts.Name)
                If Not AllUnitsAreExemptFromTest(s, testName) Then
                    Return False
                End If
            Next
            Return True
        End Function

        Public Overrides ReadOnly Property PercentageComplete() As Integer
            Get
                'Get total teststage count
                Dim totalTeststageCount As IEnumerable(Of String) = (From ts In Job.TestStages Where ts.ProcessOrder > 0 And ts.IsArchived = False Select ts.Name)
                'get complete teststage count
                Dim currentTSProcessOrder As Integer

                If Me.TestStage IsNot Nothing Then
                    currentTSProcessOrder = Me.TestStage.ProcessOrder
                Else
                    currentTSProcessOrder = 0
                End If

                Dim completeTestStageCount As Integer = (From t In Job.TestStages Where t.ProcessOrder > 0 AndAlso t.ProcessOrder < currentTSProcessOrder And t.IsArchived = False Select t).Distinct().Count()
                Dim result As Double = 0

                If totalTeststageCount.Count > 0 Then
                    result = (completeTestStageCount / totalTeststageCount.Count) * 100
                End If
                Return Convert.ToInt32(result)
            End Get
        End Property

        Protected Function AllUnitsAreExemptFromTest(ByVal testStageName As String, ByVal testName As String) As Boolean
            If Job.TestStages.FindByName(testStageName) Is Nothing Then
                Return True
            Else
                If Job.TestStages.FindByName(testStageName).Tests.FindByName(testName) Is Nothing Then
                    Return True
                End If
            End If

            'check if the tu is exempt
            For Each tu As TestUnit In TestUnits
                If Not TestExceptions.UnitIsExempt(tu.BatchUnitNumber, testStageName, testName, Me.Tasks) Then
                    Return False
                End If
            Next
            Return True
        End Function
#End Region

#Region "Test Time Functions"
        ''' <summary>
        ''' returns the estimated time remaining for the given teststage for the entire batch.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetTimeRemaining(ByVal testStageName As String) As Double
            Dim maxTime As Double = 0
            If Not (Me.TestStageName = testStageName AndAlso Me.TestStageCompletion <> TestStageCompletionStatus.InProgress) Then
                'we must get the maximum time remaining for each unit
                Dim tuTime As Double
                If TestUnits IsNot Nothing AndAlso TestUnits.Count > 0 Then
                    For Each tu As TestUnit In TestUnits
                        tuTime = Me.GetTimeRemaining(tu.BatchUnitNumber, testStageName)
                        If maxTime < tuTime Then
                            maxTime = tuTime
                        End If
                    Next
                End If
            End If

            Return maxTime
        End Function

        ''' <summary>
        ''' returns the estimated time remaining for a test unit at a specific teststage
        ''' </summary>
        ''' <param name="unitNumber"></param>
        ''' <param name="tsName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetTimeRemaining(ByVal unitNumber As Integer, ByVal tsName As String) As Double
            Dim totalTimeremaining As Double
            If Not String.IsNullOrEmpty(tsName) AndAlso unitNumber > 0 AndAlso Job.TestStages.FindByName(tsName) IsNot Nothing Then
                For Each t As Test In Job.TestStages.FindByName(tsName).Tests
                    totalTimeremaining += GetTimeRemaining(unitNumber, t.Name, tsName)
                Next
            End If
            Return totalTimeremaining
        End Function

        ''' <summary>
        ''' gets the time remaining for a test for a test unit
        ''' </summary>
        ''' <param name="unitNumber"></param>
        ''' <param name="testName"></param>
        ''' <param name="testStageName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetTimeRemaining(ByVal unitNumber As Integer, ByVal testName As String, ByVal testStageName As String) As Double
            If Me.TestingIsCompleteAndReviewedOrNotRequired(testStageName, testName, unitNumber) Then
                Return 0
            Else
                Dim selectedTestStage As TestStage = Job.TestStages.FindByName(testStageName)
                Dim currentTR As TestRecord = TestRecords.GetItem(Me.JobName, testStageName, testName, unitNumber)

                If selectedTestStage IsNot Nothing AndAlso Not String.IsNullOrEmpty(testName) Then
                    Dim selectedTest As Test = selectedTestStage.GetTest(testName) 'test sand stage exist
                    Dim expectedDuration As Double

                    If selectedTest IsNot Nothing Then
                        expectedDuration = GetExpectedTestDuration(selectedTest)
                    End If

                    If currentTR Is Nothing Then
                        'this unit has not tested this test yet so return the full time
                        Return expectedDuration
                    Else
                        Dim tt As Double = (expectedDuration - currentTR.TotalTestTimeInHours) ' Get the estimated time remaining for the test
                        If tt >= 0 Then 'make sure it is not less than 0 (this would mess up all other calculations) we dont care about finishing early for now
                            Return tt
                        Else
                            Return 0
                        End If
                    End If
                Else
                    Return 0
                End If
            End If
        End Function

        Public Function GetTotalTestTime(ByVal unitNumber As Integer, ByVal TestStageName As String, ByVal testName As String) As Double
            Return TestRecords.GetTotalTestTime(Me.JobName, TestStageName, testName, unitNumber)
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
#End Region
    End Class
End Namespace