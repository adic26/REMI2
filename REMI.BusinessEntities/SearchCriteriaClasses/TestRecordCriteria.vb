Imports REMI.Contracts
Namespace REMI.BusinessEntities
    Public Class TestRecordCriteria
        Private _testName As String
        Private _id As Integer
        Private _testUnitID As Integer
        Private _jobName As String
        Private _testStageName As String
        Private _status As TestRecordStatus
        Private _onlyIncompleteRecords As Boolean
        Private _batchID As Integer
        Private _qraNumber As String
#Region "Constructors"

        Public Sub New()

        End Sub
        Public Sub New(ByVal ID As Integer)
            Me.ID = ID
        End Sub

        Public Sub New(ByVal testUnitID As Integer, ByVal status As TestRecordStatus)
            _testUnitID = testUnitID
            _status = status
        End Sub

        Public Sub New(ByVal testUnitID As Integer, ByVal jobName As String, ByVal testStagename As String)
            _testUnitID = testUnitID
            _jobName = jobName
            _testStageName = testStagename
        End Sub

#End Region

#Region "Public Properties"
        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        Public Property OnlyIncompleteRecords() As Boolean
            Get
                Return _onlyIncompleteRecords
            End Get
            Set(ByVal value As Boolean)
                _onlyIncompleteRecords = value
            End Set
        End Property


        Public Property BatchID() As Integer
            Get
                Return _batchID
            End Get
            Set(ByVal value As Integer)
                _batchID = value
            End Set
        End Property

        Public Property Status() As TestRecordStatus
            Get
                Return _status
            End Get
            Set(ByVal value As TestRecordStatus)
                _status = value
            End Set
        End Property

        Public Property ID() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property

        Public Property TestUnitID() As Integer
            Get
                Return _testUnitID
            End Get
            Set(ByVal value As Integer)
                _testUnitID = value
            End Set
        End Property

        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

        Public Property TestStageName() As String
            Get
                Return _testStageName
            End Get
            Set(ByVal value As String)
                _testStageName = value
            End Set
        End Property

        Public Property TestName() As String
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property
#End Region
    End Class
End Namespace