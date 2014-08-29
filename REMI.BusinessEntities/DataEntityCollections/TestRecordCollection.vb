Imports System.Linq
Imports REMI.Contracts
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Testrecord">Test Records</see>.
    ''' </summary>
    <Serializable()> _
    Public Class TestRecordCollection
        Inherits REMICollectionBase(Of TestRecord)
#Region "Constructors"
        Public Sub New(ByVal myList As IList(Of REMI.BusinessEntities.TestRecord))
            MyBase.New(myList)
        End Sub

        Public Sub New()

        End Sub

#End Region
#Region "Public Functions"
        ''' <summary>
        ''' Returns a test record. Sometimes because of older test stations the results can be in there twice under different names. So this is why i force a take one. 
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetItem(ByVal jobName As String, ByVal testStagename As String, ByVal testName As String, ByVal unitNumber As Integer) As TestRecord
            Return (From tr In Me Where tr.BatchUnitNumber().Equals(unitNumber) AndAlso tr.JobName().Equals(jobName) AndAlso tr.TestName().Equals(testName) AndAlso tr.TestStageName().Equals(testStagename) Select tr).FirstOrDefault
        End Function

        Public Function GetItem(ByVal jobName As String, ByVal testStagename As String, ByVal testName As String, ByVal unitNumber As Integer, ByVal testID As Int32, ByVal testStageID As Int32) As TestRecord
            Return (From tr In Me Where tr.BatchUnitNumber().Equals(unitNumber) AndAlso tr.JobName().Equals(jobName) AndAlso tr.TestName().Equals(testName) AndAlso tr.TestStageName().Equals(testStagename) AndAlso tr.TestID().Equals(testID) AndAlso tr.TestStageID().Equals(testStageID) Select tr).FirstOrDefault
        End Function

        ''' <summary>
        ''' Returns true if the status of the test record means the test passed or any fail is accounted for.
        ''' </summary>
        ''' <param name="testName"></param>
        ''' <param name="testStagename"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function TestingIsCompleteAndORReviewed(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal unitNumber As Integer) As Boolean
            Return (GetItem(jobName, testStageName, testName, unitNumber) IsNot Nothing) AndAlso (GetItem(jobName, testStageName, testName, unitNumber).RecordStatusIsProcessComplete)
        End Function

        Public Function UnitIsInFA(ByVal unitNumber As Integer) As Boolean
            Return (From tr In Me Where tr.BatchUnitNumber.Equals(unitNumber) AndAlso tr.Status.Equals(TestRecordStatus.FARaised) Select tr).Count > 0
        End Function

        Public Function UnitIsInFA(ByVal unitNumber As Integer, ByVal testStageName As String) As Boolean
            Return (From tr In Me Where tr.BatchUnitNumber.Equals(unitNumber) AndAlso tr.Status.Equals(TestRecordStatus.FARaised) AndAlso tr.TestStageName = testStageName Select tr).Count > 0
        End Function

        Public Function UnitIsInFA(ByVal qraNumber As String) As Boolean
            Return (From tr In Me Where tr.QRANumber = qraNumber AndAlso tr.Status.Equals(TestRecordStatus.FARaised) Select tr).Count > 0
        End Function

        ''' <summary>
        ''' Return a collection of test records by status.
        ''' </summary>
        ''' <param name="status">the status to search for.</param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function FindByStatus(ByVal status As TestRecordStatus) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.Status().Equals(status) _
              Select tr).ToList())
        End Function
        ''' <summary>
        ''' Return a collection of test records by status.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function GetOverallTestStatus(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal numberOfUnits As Integer) As TestRecordStatus
            'if we have a record for the test, but not a full set. return in progress
            Dim numberOfRecords As Integer = FindByTestStageTest(jobName, testStageName, testName).Count()
            If numberOfRecords > 0 AndAlso numberOfRecords < numberOfUnits Then
                Return TestRecordStatus.InProgress
            End If

            'otherwise we have a full set, calculate which title should be displayed.

            If CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.InProgress) > 0 Then
                Return TestRecordStatus.InProgress
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.CompleteFail) > 0 Then
                Return TestRecordStatus.CompleteFail
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.NeedsRetest) > 0 Then
                Return TestRecordStatus.NeedsRetest
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.WaitingForResult) > 0 Then
                Return TestRecordStatus.WaitingForResult
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.FARequired) > 0 Then
                Return TestRecordStatus.FARequired
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.FARaised) > 0 Then
                Return TestRecordStatus.FARaised
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.CompleteKnownFailure) > 0 Then
                Return TestRecordStatus.CompleteKnownFailure
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.Complete) > 0 Then
                Return TestRecordStatus.Complete
            ElseIf CountRecordsByStatus(jobName, testStageName, testName, TestRecordStatus.Quarantined) > 0 Then
                Return TestRecordStatus.Quarantined
            Else
                Return TestRecordStatus.NotSet
            End If
        End Function
        Public Function CountRecordsByStatus(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal status As TestRecordStatus) As Integer

            Return (From tr In Me Where tr.Status.Equals(status) AndAlso tr.TestName.Equals(testName) AndAlso tr.TestStageName.Equals(testStageName)).Count

        End Function
        ''' <summary>
        ''' Returns a collection of test records for a test stage.
        ''' </summary>
        ''' <param name="testStageName">the name of the test stage.</param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function FindByTestStage(ByVal jobName As String, ByVal testStageName As String) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageName().Equals(testStageName) And tr.JobName.Equals(jobName) _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageUnit(ByVal jobName As String, ByVal testStageName As String, ByVal unitNumber As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageName().Equals(testStageName) And tr.JobName.Equals(jobName) _
              And tr.BatchUnitNumber = unitNumber _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageTestUnit(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal unitID As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageName().Equals(testStageName) And tr.TestName.Equals(testName) And tr.JobName.Equals(jobName) And tr.TestUnitID.Equals(unitID) _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageTest(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageName().Equals(testStageName) And tr.TestName.Equals(testName) And tr.JobName.Equals(jobName) _
              Select tr).ToList())
        End Function
        Public Function FindByTestUnit(ByVal unitNumber As Integer) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.BatchUnitNumber().Equals(unitNumber) _
              Select tr).ToList())
        End Function
        Public Overloads Sub Add(ByVal myList As IList(Of TestRecord))
            For Each tr As TestRecord In myList
                Me.Add(tr)
            Next
        End Sub
        Public Function GetTotalTestTime(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal unitNumber As Integer) As Double
            Dim tr As TestRecord = GetItem(jobName, testStageName, testName, unitNumber)

            If tr IsNot Nothing AndAlso tr.Status <> TestRecordStatus.NotSet Then
                Return tr.TotalTestTimeInHours
            End If

            Return 0
        End Function
#End Region


    End Class
End Namespace