Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class ProcessTask
        Implements ITaskModel

        Private _expectedDuration As TimeSpan
        Private _processOrder As Integer
        Private _resultBasedOnTime As Boolean
        Private _testName As String
        Private _teststageName As String
        Private _unitsForTask As Integer()
        Private _testType As TestType
        Private _testStageType As REMI.Contracts.TestStageType
        Private _testID As Int32
        Private _isArchived As Boolean
        Private _testIsArchived As Boolean
        Private _TestStageID As Int32

        Public Property TestStageType() As REMI.Contracts.TestStageType Implements ITaskModel.TestStageType

            Get
                Return _testStageType
            End Get
            Set(ByVal value As REMI.Contracts.TestStageType)
                _testStageType = value
            End Set
        End Property

        Public Property TestType() As TestType Implements ITaskModel.TestType
            Get
                Return _testType
            End Get
            Set(ByVal value As TestType)
                _testType = value
            End Set
        End Property

        Public Property ExpectedDuration() As System.TimeSpan Implements Contracts.ITaskModel.ExpectedDuration
            Get
                Return _expectedDuration
            End Get
            Set(ByVal value As System.TimeSpan)
                _expectedDuration = value
            End Set
        End Property

        Public Property TestIsArchived() As Boolean Implements Contracts.ITaskModel.TestIsArchived
            Get
                Return _testIsArchived
            End Get
            Set(ByVal value As Boolean)
                _testIsArchived = value
            End Set
        End Property

        Public Property IsArchived() As Boolean Implements Contracts.ITaskModel.IsArchived
            Get
                Return _isArchived
            End Get
            Set(ByVal value As Boolean)
                _isArchived = value
            End Set
        End Property

        Public Property TestID() As Integer Implements Contracts.ITaskModel.TestID
            Get
                Return _testID
            End Get
            Set(ByVal value As Integer)
                _testID = value
            End Set
        End Property

        Public Property TestStageID() As Integer Implements Contracts.ITaskModel.TestStageID
            Get
                Return _TestStageID
            End Get
            Set(ByVal value As Integer)
                _TestStageID = value
            End Set
        End Property

        Public Property ProcessOrder() As Integer Implements Contracts.ITaskModel.ProcessOrder
            Get
                Return _processOrder
            End Get
            Set(ByVal value As Integer)
                _processOrder = value
            End Set
        End Property

        Public Property ResultBaseOnTime() As Boolean Implements Contracts.ITaskModel.ResultBaseOnTime
            Get
                Return _resultBasedOnTime

            End Get
            Set(ByVal value As Boolean)
                _resultBasedOnTime = value

            End Set
        End Property

        Public Property TestName() As String Implements Contracts.ITaskModel.TestName
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property

        Public Property TestStageName() As String Implements Contracts.ITaskModel.TestStageName
            Get
                Return _teststageName
            End Get
            Set(ByVal value As String)
                _teststageName = value
            End Set
        End Property
        Public Sub SetUnitsForTask(ByVal units As String) Implements Contracts.ITaskModel.SetUnitsForTask
            Dim strVals = units.Split(New Char() {","c}, System.StringSplitOptions.RemoveEmptyEntries).TakeWhile(Function(str) (Not String.IsNullOrEmpty(str.Trim))).ToArray()
            _unitsForTask = Array.ConvertAll(strVals, Function(str) Int32.Parse(str))
        End Sub
        Public ReadOnly Property UnitsForTask() As Integer() Implements Contracts.ITaskModel.UnitsForTask
            Get
                Return _unitsForTask
            End Get
        End Property
    End Class
End Namespace