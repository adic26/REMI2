Imports System.ComponentModel
Imports REMI.Validation
Namespace REMI.BusinessEntities

    Public Class BatchTestStageSchedule
        Inherits LoggedItemBase
#Region "Private Variables"
        Private _startTime As DateTime
        Private _endTime As DateTime
        Private _comment As String
        Private _qraNumber As String
        Private _assignedUser As String
        Private _testStageName As String
#End Region

#Region "Public Properties"

        Public Property Comment() As String
            Get
                Return _comment
            End Get
            Set(ByVal value As String)
                _comment = value
            End Set
        End Property
        <NotNullOrEmpty(Message:="w65")> _
        Public Property StartTime() As DateTime
            Get
                Return _startTime
            End Get
            Set(ByVal value As DateTime)
                _startTime = value
            End Set
        End Property
        <NotNullOrEmpty(Message:="w66")> _
        Public Property EndTime() As DateTime
            Get
                Return _endTime
            End Get
            Set(ByVal value As DateTime)
                _endTime = value
            End Set
        End Property
        <NotNullOrEmpty(Message:="w8")> _
        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property
        <NotNullOrEmpty(Message:="w35")> _
        Public Property AssignedUser() As String
            Get
                Return _assignedUser
            End Get
            Set(ByVal value As String)
                _assignedUser = value
            End Set
        End Property
        <NotNullOrEmpty(Message:="w27")> _
        Public Property TestStageName() As String
            Get
                Return _testStageName
            End Get
            Set(ByVal value As String)
                _testStageName = value
            End Set
        End Property
        Public ReadOnly Property Text() As String
            Get
                Return QRANumber + " " + TestStageName
            End Get
        End Property
#End Region
    End Class
End Namespace