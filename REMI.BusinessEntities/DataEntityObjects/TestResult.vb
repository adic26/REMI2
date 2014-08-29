Imports REMI.Contracts
Namespace REMI.BusinessEntities
    Public Class TestResult
        Inherits Validation.ValidationBase
        Private _testName As String
        Private _jobName As String
        Private _testStageName As String
        Private _result As FinalTestResult
        Private _version As Integer
        Private _testID As Int32
        Private _testStageID As Int32
        Private _unitNumber As Integer
        Private _source As TestResultSource

        Public Sub New()
            _result = FinalTestResult.NotSet
            _source = TestResultSource.NotSet
        End Sub

        Public Sub New(ByVal source As TestResultSource, ByVal version As Integer, ByVal resultstr As String, ByVal testName As String, ByVal testStageString As String, ByVal unitNumber As Integer)
            SetResult(resultstr, version, source)
            _testName = testName
            Dim testAndTestStage() As String = testStageString.Split("-"c)
            _testStageName = testAndTestStage(1).Trim()
            _jobName = testAndTestStage(0).Trim()
            _unitNumber = unitNumber
        End Sub

        Public Sub New(ByVal source As TestResultSource, ByVal version As Integer, ByVal resultstr As String, ByVal testName As String, ByVal testStageString As String, ByVal unitNumber As Integer, ByVal testID As Int32, ByVal testStageID As Int32)
            SetResult(resultstr, version, source)
            _testName = testName
            _testID = testID
            _testStageID = testStageID
            Dim testAndTestStage() As String = testStageString.Split("-"c)
            _testStageName = testAndTestStage(1).Trim()
            _jobName = testAndTestStage(0).Trim()
            _unitNumber = unitNumber
        End Sub

        Public Sub New(ByVal source As TestResultSource, ByVal resultstr As String, ByVal testName As String, ByVal testStageString As String, ByVal unitNumber As Integer, ByVal testID As Int32, ByVal testStageID As Int32)
            SetResult(resultstr, 0, source)
            _testName = testName
            _testID = testID
            _testStageID = testStageID

            If (testStageString.Contains("-")) Then
                Dim testAndTestStage() As String = testStageString.Split("-"c)
                _testStageName = testAndTestStage(1).Trim()
                _jobName = testAndTestStage(0).Trim()
            Else
                _testStageName = testStageString
            End If

            _unitNumber = unitNumber
        End Sub

        Public ReadOnly Property Result() As FinalTestResult
            Get
                Return _result
            End Get
        End Property

        Public ReadOnly Property UnitNumber() As Integer
            Get
                Return _unitNumber
            End Get
        End Property

        Public ReadOnly Property TestID() As Int32
            Get
                Return _testID
            End Get
        End Property

        Public ReadOnly Property TestStageID() As Int32
            Get
                Return _testStageID
            End Get
        End Property

        Public ReadOnly Property Version() As Integer
            Get
                Return _version
            End Get
        End Property

        Public ReadOnly Property TestName() As String
            Get
                Return _testName
            End Get
        End Property

        Public ReadOnly Property TestStageName() As String
            Get
                Return _testStageName
            End Get
        End Property

        Public ReadOnly Property JobName() As String
            Get
                Return _jobName
            End Get
        End Property

        Public ReadOnly Property Source() As TestResultSource
            Get
                Return _source
            End Get
        End Property

        Public Sub SetResult(ByVal resultStr As String, ByVal version As Integer, ByVal source As TestResultSource)
            _version = version
            _source = source
            Select Case resultStr.ToLowerInvariant
                Case "pass"
                    _result = FinalTestResult.Pass
                Case "fail"
                    _result = FinalTestResult.Fail
                Case Else
                    _result = FinalTestResult.NotSet
                    _source = TestResultSource.NotSet
                    _version = 0
            End Select
        End Sub

        'Public Overrides Function Validate() As Boolean
        '    Select Case Source
        '        Case TestResultSource.Relab
        '            If Version > 0 AndAlso Result <> FinalTestResult.NotSet Then
        '                Return True
        '            End If
        '        Case TestResultSource.WebService, TestResultSource.Manual 'slightly different becuase these guys don't have versions
        '            If Result <> FinalTestResult.NotSet Then
        '                Return True
        '            End If
        '        Case Else
        '            Return False
        '    End Select
        'End Function

        Public Overrides Function ToString() As String
            Return _result.ToString
        End Function
    End Class
End Namespace