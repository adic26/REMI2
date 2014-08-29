Namespace REMI.BusinessEntities
    Public Class RelabResultCriteria
        Private _batchUnitNumber As String
        Private _qraNumber As String
        Private _testName As String
        Private _jobName As String
        Private _testStageName As String
        Private _jobNameVariation As JobNameMode

        Public Sub New(ByVal qraNumber As String, ByVal batchUnitNumber As String, ByVal testName As String, ByVal jobName As String, ByVal testStageName As String)
            _qraNumber = qraNumber
            _batchUnitNumber = batchUnitNumber
            _jobName = jobName
            _testName = testName
            _testStageName = testStageName
            _jobNameVariation = 0
        End Sub

        Public Sub New(ByVal qraNumber As String, ByVal jobName As String, ByVal testStageName As String)
            _qraNumber = qraNumber
            _jobName = jobName
            _testStageName = testStageName
            _jobNameVariation = 0
        End Sub

        Public ReadOnly Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
        End Property

        Public ReadOnly Property BatchUnitNumber() As String
            Get
                Return _batchUnitNumber
            End Get
        End Property

        Public ReadOnly Property TestName() As String
            Get
                Select Case _jobNameVariation
                    Case JobNameMode.UpperCaseVariation, JobNameMode.OldLabviewVariationAndUpperCase
                        Return _testName.ToUpperInvariant
                    Case Else
                        Return _testName
                End Select
                Return _testName
            End Get
        End Property

        Public ReadOnly Property JobName() As String
            Get
                Return _jobName
            End Get
        End Property

        Public ReadOnly Property TestStageName() As String
            Get
                Return _testStageName
            End Get
        End Property

        Public Property JobNameVariation() As JobNameMode
            Get
                Return _jobNameVariation
            End Get
            Set(ByVal value As JobNameMode)
                _jobNameVariation = value
            End Set
        End Property

        Public Enum JobNameMode
            ''' <summary>
            ''' Leaves the jobname unchanged
            ''' </summary>
            ''' <remarks></remarks>e
            Unchanged = 0
            ''' <summary>
            ''' upper cases the test name
            ''' </summary>
            ''' <remarks></remarks>
            UpperCaseVariation = 1
            ''' <summary>
            ''' changes the name of the record to the old labview names
            ''' </summary>
            ''' <remarks></remarks>
            OldLabviewVariation = 2
            ''' <summary>
            ''' changes the name to the old labview name and uppercases the test name
            ''' </summary>
            ''' <remarks></remarks>
            OldLabviewVariationAndUpperCase = 3
        End Enum
    End Class
End Namespace