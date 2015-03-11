Imports System.Linq
Imports REMI.Validation
Imports System.Text.RegularExpressions
Imports REMI.Contracts
Imports REMI.Core
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents the testing status of a unit for a particular test.
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class TestRecord
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _testUnitID As Integer
        Private _jobName As String
        Private _testStageName As String
        Private _testName As String
        Private _status As TestRecordStatus
        Private _failDocs As List(Of Dictionary(Of String, String))
        Private _highestResultVerNum As Integer
        Private _comments As String
        Private _numberOfTests As Integer
        Private _testID As Int32
        Private _testStageID As Int32
        Private _totalTestTime As TimeSpan
        Private _QRANumber As String
        Private _batchUnitNumber As Integer
        Private _functionalType As Int32
        Private _resultSource As TestResultSource
#End Region

#Region "Constructors"
        Public Sub New(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal testUnitID As Integer, ByVal userName As String)
            _jobName = jobName
            _testStageName = testStageName
            _testName = testName
            _testUnitID = testUnitID
            LastUser = userName
            _failDocs = New List(Of Dictionary(Of String, String))
            _status = TestRecordStatus.NotSet
        End Sub
        Public Sub New(ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal testUnitID As Integer, ByVal userName As String, ByVal testID As Int32, ByVal testStageID As Int32)
            _jobName = jobName
            _testStageName = testStageName
            _testName = testName
            _testUnitID = testUnitID
            LastUser = userName
            _testID = testID
            _testStageID = testStageID
            _failDocs = New List(Of Dictionary(Of String, String))
            _status = TestRecordStatus.NotSet
        End Sub
        Public Sub New(ByVal qraNumber As String, ByVal batchUnitNumber As Integer, ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal testUnitID As Integer, ByVal userName As String)
            _jobName = jobName
            _QRANumber = qraNumber
            _batchUnitNumber = batchUnitNumber
            _testStageName = testStageName
            _testName = testName
            _testUnitID = testUnitID
            LastUser = userName
            _failDocs = New List(Of Dictionary(Of String, String))
            _status = TestRecordStatus.NotSet
        End Sub
        Public Sub New(ByVal qraNumber As String, ByVal batchUnitNumber As Integer, ByVal jobName As String, ByVal testStageName As String, ByVal testName As String, ByVal testUnitID As Integer, ByVal userName As String, ByVal testID As Int32, ByVal testStageID As Int32)
            _jobName = jobName
            _QRANumber = qraNumber
            _batchUnitNumber = batchUnitNumber
            _testStageName = testStageName
            _testName = testName
            _testUnitID = testUnitID
            LastUser = userName
            _testID = testID
            _testStageID = testStageID
            _failDocs = New List(Of Dictionary(Of String, String))
            _status = TestRecordStatus.NotSet
        End Sub
        Public Sub New()
            _failDocs = New List(Of Dictionary(Of String, String))
            _status = TestRecordStatus.NotSet
        End Sub
#End Region

#Region "Public Properties"
        ''' <summary>
        ''' The unique database ID of the test unit being logged.
        ''' </summary>
        <ValidIDNumber(Key:="w40")> _
        Public Property TestUnitID() As Integer
            Get
                Return _testUnitID
            End Get
            Set(ByVal value As Integer)
                _testUnitID = value
            End Set
        End Property

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(ByVal value As Int32)
                _testID = value
            End Set
        End Property

        Public Property FunctionalType() As Int32
            Get
                Return _functionalType
            End Get
            Set(ByVal value As Int32)
                _functionalType = value
            End Set
        End Property

        Public Property TestStageID() As Int32
            Get
                Return _testStageID
            End Get
            Set(ByVal value As Int32)
                _testStageID = value
            End Set
        End Property

        Public Property ResultSource() As TestResultSource
            Get
                Return _resultSource
            End Get
            Set(ByVal value As TestResultSource)
                _resultSource = value
            End Set
        End Property

        ''' <summary>
        ''' The name of the job.
        ''' </summary>
        <NotNullOrEmpty(key:="w41")> _
        <ValidStringLength(key:="w42", MaxLength:=400)> _
        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

        <NotNullOrEmpty(Message:="w43")> _
        <ValidStringLength(Message:="w44", MaxLength:=400)> _
        Public Property TestStageName() As String
            Get
                Return _testStageName
            End Get
            Set(ByVal value As String)
                _testStageName = value
            End Set
        End Property

        <NotNullOrEmpty(Message:="w45")> _
        <ValidStringLength(Message:="w46", MaxLength:=400)> _
        Public Property TestName() As String
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property

        <EnumerationSet(Message:="w47")> _
        Public Property Status() As TestRecordStatus
            Get
                Return _status

            End Get
            Set(ByVal value As TestRecordStatus)
                _status = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the FA/RIT doc if there is a failure
        ''' </summary>
        <Xml.Serialization.XmlIgnore()> _
        Public Property FailDocs() As List(Of Dictionary(Of String, String))
            Get
                Return _failDocs
            End Get
            Set(ByVal value As List(Of Dictionary(Of String, String)))
                If value IsNot Nothing Then
                    _failDocs = value
                End If
            End Set
        End Property

        Public Property CurrentRelabResultVersion() As Integer
            Get
                Return _highestResultVerNum
            End Get
            Set(ByVal value As Integer)
                _highestResultVerNum = value
            End Set
        End Property

        <ValidStringLength(Message:="w48", MaxLength:=1000)> _
        Public Property Comments() As String
            Get
                Return _comments
            End Get
            Set(ByVal value As String)
                _comments = value
            End Set
        End Property

        Public ReadOnly Property TestIdentificationString() As String
            Get
                Return String.Format("{0}-{1:d3} for {2} >> {3} >> {4}", _QRANumber, _batchUnitNumber, _jobName, _testStageName, _testName)
            End Get
        End Property

        Public Property NumberOfTests() As Integer
            Get
                Return _numberOfTests
            End Get
            Set(ByVal value As Integer)
                _numberOfTests = value
            End Set
        End Property

        Public Property BatchUnitNumber() As Integer
            Get
                Return _batchUnitNumber
            End Get
            Set(ByVal value As Integer)
                _batchUnitNumber = value
            End Set
        End Property

        Public Property QRANumber() As String
            Get
                Return _QRANumber
            End Get
            Set(ByVal value As String)
                _QRANumber = value
            End Set
        End Property

        Public Property TotalTestTimeInMinutes() As Double
            Get
                Return _totalTestTime.TotalMinutes
            End Get
            Set(ByVal value As Double)
                _totalTestTime = TimeSpan.FromMinutes(value)
            End Set
        End Property

        'calculated from the read only properties
        Public ReadOnly Property TotalTestTimeInHours() As Double
            Get
                Return _totalTestTime.TotalHours
            End Get
        End Property

        Public ReadOnly Property UnitInfoLink() As String
            Get
                Return REMIWebLinks.GetUnitInfoLink(String.Format("{0}-{1:d3}", QRANumber, BatchUnitNumber))
            End Get
        End Property

        Public ReadOnly Property EditDetailsLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsEditDetailLink(Me.ID)
            End Get
        End Property

        Public ReadOnly Property FailDocCSVList() As String
            Get
                Return String.Join(",", (From f In FailDocs Select f.Item("RequestNumber")).ToArray)
            End Get
        End Property

        Public ReadOnly Property FailDocDS() As DataTable
            Get
                Dim dt As New DataTable("FA")
                dt.Columns.Add("Unit", GetType(String))
                dt.Columns.Add("Test", GetType(String))
                dt.Columns.Add("Stage", GetType(String))

                For Each k In FailDocs(0).Keys
                    dt.Columns.Add(k, GetType(String))
                Next

                For Each f In FailDocs
                    Dim dr As DataRow = dt.NewRow
                    dr("Unit") = BatchUnitNumber
                    dr("Test") = TestName
                    dr("Stage") = TestStageName

                    For Each k In f.Keys
                        If (dt.Columns(k) Is Nothing) Then
                            dt.Columns.Add(k, GetType(String))
                        End If

                        Dim val As String = f.Item(k)

                        dr(k) = If(val Is Nothing Or val Is DBNull.Value, String.Empty, val)
                    Next
                    dt.Rows.Add(dr)
                Next

                If (dt.Columns("Failed 3rd Level") Is Nothing) Then
                    dt.Columns.Add("Failed 3rd Level", GetType(String))
                    Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Failed 3rd Level") = " ")
                End If

                If (dt.Columns("Caused By") Is Nothing) Then
                    dt.Columns.Add("Caused By", GetType(String))
                    Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Caused By") = " ")
                End If

                If (dt.Columns("Root Cause") Is Nothing) Then
                    dt.Columns.Add("Root Cause", GetType(String))
                    Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Root Cause") = " ")
                End If

                If (dt.Columns("Other") Is Nothing) Then
                    dt.Columns.Add("Other", GetType(String))
                    Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Other") = " ")
                End If

                If (dt.Columns("Analysis") Is Nothing) Then
                    dt.Columns.Add("Analysis", GetType(String))
                    Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Analysis") = " ")
                End If

                dt.AcceptChanges()

                Return dt
            End Get
        End Property

        Public ReadOnly Property FailDocLiteralHTMLLinkList() As String
            Get
                Dim i As Integer = 0
                Dim retStr As New System.Text.StringBuilder
                For Each f In FailDocs
                    If i > 0 Then
                        retStr.Append("<br/>")
                    End If
                    retStr.Append("<a href=""") 'if its an RIT/SCM then display the number and link too
                    retStr.Append(f.Item("Request Link"))
                    retStr.Append(""" target=""_blank"">")
                    retStr.Append(f.Item("RequestNumber"))
                    retStr.Append("</a>")
                    i += 1
                Next

                Return retStr.ToString
            End Get
        End Property

        Public ReadOnly Property TestRecordsLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsLink(String.Format("{0}-{1:d3}", QRANumber, BatchUnitNumber), Me.TestName, Me.TestStageName, Me.JobName, 0)
            End Get
        End Property

        Public ReadOnly Property BatchInfoLink() As String
            Get
                Return REMIWebLinks.GetBatchInfoLink(QRANumber)
            End Get
        End Property
#End Region

#Region "Public functions"
        ''' <summary>
        ''' Checks if the test record status is FA, RIT, Complete or Quarantined
        ''' </summary>
        Public Function RecordStatusIsProcessComplete() As Boolean
            Return (Status = TestRecordStatus.FARaised OrElse Status = TestRecordStatus.CompleteKnownFailure OrElse Status = TestRecordStatus.Complete OrElse Status = TestRecordStatus.Quarantined)
        End Function

        Public Function RecordStatusIsProcessCompleteOrContinueOnFailure() As Boolean
            Return (Status = TestRecordStatus.FARaised OrElse Status = TestRecordStatus.CompleteFail OrElse Status = TestRecordStatus.CompleteKnownFailure OrElse Status = TestRecordStatus.Complete OrElse Status = TestRecordStatus.Quarantined)
        End Function

        Public Function RecordStatusIsTestingComplete() As Boolean
            Return (Status = TestRecordStatus.CompleteFail OrElse Status = TestRecordStatus.Complete OrElse Status = TestRecordStatus.WaitingForResult)
        End Function

        Public Sub AddFailDoc(ByVal failDoc As Dictionary(Of String, String), ByVal comments As String, ByVal username As String)
            If failDoc IsNot Nothing Then
                If (From f In Me.FailDocs Where f.Item("RequestNumber") = failDoc.Item("RequestNumber") Select f).Count = 0 Then
                    Me.FailDocs.Add(failDoc)
                End If

                Me.Status = TestRecordStatus.FARaised
                Me.ResultSource = TestResultSource.Manual

                Me.Notifications.AddWithMessage(String.Format("{0} assigned to the test record ok.", failDoc.Item("RequestNumber")), NotificationType.Information)
                Me.Comments = comments
                LastUser = username
            Else
                Throw New Exception("Attempt to set null fail document. The number for the FA/RIT/SCM was not valid. Please review this number and try again.")
            End If
        End Sub

        Public Sub RemoveFailDoc(ByVal failDocNumber As String, ByVal username As String, ByVal comments As String)
            Try
                Dim selectedFaildoc As Dictionary(Of String, String) = (From f In _failDocs Where f.Item("RequestNumber").Equals(failDocNumber) Select f).Single
                If selectedFaildoc IsNot Nothing Then
                    _failDocs.Remove(selectedFaildoc)
                    Me.LastUser = username
                    Me.Comments = comments
                    If _failDocs.Count = 0 Then
                        Me.Status = TestRecordStatus.CompleteFail
                        Me.ResultSource = TestResultSource.Manual
                    Else
                        If (From f In _failDocs Where f.Item("RequestType") = "FA" Select f).Count > 0 Then
                            Me.Status = TestRecordStatus.FARaised
                            Me.ResultSource = TestResultSource.Manual
                        End If
                    End If
                End If
            Catch
                Throw New Exception("Unable to remove the given fail document (" + failDocNumber + ").")
            End Try
        End Sub

        Public Sub SetStatus(ByVal status As TestRecordStatus, ByVal comments As String, ByVal username As String)
            'should not set these two status. these should be set using the set fail doc method.
            If Me.Status <> TestRecordStatus.CompleteKnownFailure OrElse Me.Status <> TestRecordStatus.FARaised Then
                Dim oldStatus As String = status.ToString
                Me.Notifications.AddWithMessage(String.Format("Status for {0}-{1:d3} set to: {2} (Was: {3})", QRANumber, BatchUnitNumber, status.ToString, oldStatus), NotificationType.Information)
                Me.ResultSource = TestResultSource.Manual
                Me.Status = status
                Me.Comments = comments
                Me.LastUser = username
            End If
        End Sub

        Public Function SetStatusByResult(ByVal testResult As TestResult, ByVal userHasRetestAuthority As Boolean) As Boolean
            'check if the test result has
            'a status other than in fA - in fa tests should not shange the status of the record.
            'A higher version than the current version if its a relab result
            'OR its one of the other methods.
            Dim returnVal As Boolean = False

            If Me.Status <> TestRecordStatus.FARaised AndAlso Me.Status <> TestRecordStatus.CompleteKnownFailure Then
                Select Case testResult.Result
                    Case FinalTestResult.Fail
                        Me.Status = TestRecordStatus.CompleteFail
                        returnVal = True
                    Case FinalTestResult.Pass
                        'The unit passed and is now ready to continue on.
                        Me.Status = TestRecordStatus.Complete
                        returnVal = True
                    Case FinalTestResult.NotSet
                        Me.Status = TestRecordStatus.WaitingForResult
                        returnVal = True
                End Select

                Me.ResultSource = testResult.Source

                'there should never be a result from relab where the result is not set.
                If testResult.Result <> FinalTestResult.NotSet AndAlso testResult.Source = TestResultSource.Relab Then
                    'set the version if this came from relab.
                    Me.CurrentRelabResultVersion = testResult.Version
                End If
            End If

            Return returnVal
        End Function

        <Obsolete("SetStatusByResult Is Old Relab")> _
        Public Function SetStatusByRelabResult(ByVal testResult As TestResult, ByVal userHasRetestAuthority As Boolean) As Boolean
            'check if the test result has
            'a status other than in fA - in fa tests should not shange the status of the record.
            'A higher version than the current version if its a relab result
            'OR its one of the other methods.
            Dim returnVal As Boolean
            If Me.Status <> TestRecordStatus.FARaised AndAlso _
            Me.Status <> TestRecordStatus.CompleteKnownFailure AndAlso _
            ((testResult.Version > CurrentRelabResultVersion And testResult.Source = TestResultSource.Relab) Or _
            testResult.Source <> TestResultSource.Relab) Then
                Select Case testResult.Result
                    Case FinalTestResult.Fail

                        Me.Status = TestRecordStatus.CompleteFail
                        returnVal = True
                    Case FinalTestResult.Pass

                        'The unit passed and is now ready to continue on.
                        Me.Status = TestRecordStatus.Complete
                        returnVal = True
                    Case FinalTestResult.NotSet

                        Me.Status = TestRecordStatus.WaitingForResult
                        returnVal = True
                End Select
                Me.ResultSource = testResult.Source
                'there should never be a result from relab where the result is not set.
                If testResult.Result <> FinalTestResult.NotSet AndAlso testResult.Source = TestResultSource.Relab Then
                    'set the version if this came from relab.

                    Me.CurrentRelabResultVersion = testResult.Version
                End If
            End If
            Return returnVal
        End Function

        'Public Overrides Function Validate() As Boolean
        '    Dim baseValid As Boolean = MyBase.Validate
        '    Dim localValid As Boolean = True
        '    If localValid AndAlso FailDocs.Count >= 1 Then
        '        'check each fail doc for validity
        '        For Each f As RequestBase In FailDocs
        '            If Not f.Validate Then
        '                localValid = False
        '                Exit For
        '            End If
        '        Next

        '    End If
        '    Return baseValid AndAlso localValid
        'End Function
#End Region
    End Class
End Namespace