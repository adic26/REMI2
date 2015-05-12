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

        Public Function GetItem(ByVal jobName As String, ByVal testStageID As Int32, ByVal unitNumber As Integer) As TestRecord
            Return (From tr In Me Where tr.BatchUnitNumber().Equals(unitNumber) AndAlso tr.JobName().Equals(jobName) AndAlso tr.TestStageID = testStageID Select tr).FirstOrDefault
        End Function

        Public Function GetItem(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitNumber As Integer) As TestRecord
            Return (From tr In Me Where tr.BatchUnitNumber().Equals(unitNumber) AndAlso tr.JobName().Equals(jobName) AndAlso tr.TestID = testID AndAlso tr.TestStageID = testStageID Select tr).FirstOrDefault
        End Function

        Public Function UnitIsInFA(ByVal unitNumber As Integer) As Boolean
            Return (From tr In Me Where tr.BatchUnitNumber.Equals(unitNumber) AndAlso tr.Status.Equals(TestRecordStatus.FARaised) Select tr).Count > 0
        End Function

        Public Function UnitIsInFA(ByVal unitNumber As Integer, ByVal teststageID As Int32) As Boolean
            Return (From tr In Me Where tr.BatchUnitNumber.Equals(unitNumber) AndAlso tr.Status.Equals(TestRecordStatus.FARaised) AndAlso tr.TestStageID = teststageID Select tr).Count > 0
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
        Public Function GetOverallTestStatus(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal numberOfUnits As Integer) As TestRecordStatus
            'if we have a record for the test, but not a full set. return in progress
            Dim numberOfRecords As Integer = FindByTestStageTest(jobName, testStageID, testID).Count()
            If numberOfRecords > 0 AndAlso numberOfRecords < numberOfUnits Then
                Return TestRecordStatus.InProgress
            End If

            'otherwise we have a full set, calculate which title should be displayed.

            If CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.InProgress) > 0 Then
                Return TestRecordStatus.InProgress
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.CompleteFail) > 0 Then
                Return TestRecordStatus.CompleteFail
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.NeedsRetest) > 0 Then
                Return TestRecordStatus.NeedsRetest
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.WaitingForResult) > 0 Then
                Return TestRecordStatus.WaitingForResult
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.FARequired) > 0 Then
                Return TestRecordStatus.FARequired
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.FARaised) > 0 Then
                Return TestRecordStatus.FARaised
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.CompleteKnownFailure) > 0 Then
                Return TestRecordStatus.CompleteKnownFailure
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.Complete) > 0 Then
                Return TestRecordStatus.Complete
            ElseIf CountRecordsByStatus(jobName, testStageID, testID, TestRecordStatus.Quarantined) > 0 Then
                Return TestRecordStatus.Quarantined
            Else
                Return TestRecordStatus.NotSet
            End If
        End Function

        Public Function CountRecordsByStatus(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal status As TestRecordStatus) As Integer
            Return (From tr In Me Where tr.Status.Equals(status) AndAlso tr.TestID = testID AndAlso tr.TestStageID = testStageID).Count
        End Function
        ''' <summary>
        ''' Returns a collection of test records for a test stage.
        ''' </summary>
        ''' <param name="testStageName">the name of the test stage.</param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function FindByTestStage(ByVal jobName As String, ByVal testStageID As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageID = testStageID And tr.JobName.Equals(jobName) _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageUnit(ByVal jobName As String, ByVal testStageID As Int32, ByVal unitNumber As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageID = testStageID And tr.JobName.Equals(jobName) _
              And tr.BatchUnitNumber = unitNumber _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageTestUnit(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitID As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageID = testStageID And tr.TestID = testID And tr.JobName.Equals(jobName) And tr.TestUnitID.Equals(unitID) _
              Select tr).ToList())
        End Function
        Public Function FindByTestStageTest(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32) As TestRecordCollection
            Return New TestRecordCollection((From tr In Me _
              Where tr.TestStageID = testStageID And tr.TestID = testID And tr.JobName.Equals(jobName) _
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
        Public Function GetTotalTestTime(ByVal jobName As String, ByVal testStageID As Int32, ByVal testID As Int32, ByVal unitNumber As Integer) As Double
            Dim tr As TestRecord = GetItem(jobName, testStageID, testID, unitNumber)

            If tr IsNot Nothing AndAlso tr.Status <> TestRecordStatus.NotSet Then
                Return tr.TotalTestTimeInHours
            End If

            Return 0
        End Function
#End Region

    End Class
End Namespace