Namespace REMI.BusinessEntities
    Public Class SimpleTestUnit
        Public Sub New(ByVal qraNumber As String, ByVal unitNumber As Integer, ByVal location As String, ByVal lastUser As String, ByVal lastDate As DateTime)
            Me.UnitNumber = unitNumber
            Me.QRANumber = qraNumber
            Me.Location = location
            Me.LastDate = lastDate
            Me.LastUser = lastUser
        End Sub
        Private _unitNumber As Integer
        Public Property UnitNumber() As Integer
            Get
                Return _unitNumber
            End Get
            Set(ByVal value As Integer)
                _unitNumber = value
            End Set
        End Property

        Private _qraNumber As String
        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        Private _location As String
        Public Property Location() As String
            Get
                Return _location
            End Get
            Set(ByVal value As String)
                _location = value
            End Set
        End Property

        Private _lastUser As String
        Public Property LastUser() As String
            Get
                Return _lastUser
            End Get
            Set(ByVal value As String)
                _lastUser = value
            End Set
        End Property

        Private _lastDate As DateTime
        Public Property LastDate() As DateTime
            Get
                Return _lastDate
            End Get
            Set(ByVal value As DateTime)
                _lastDate = value
            End Set
        End Property

    End Class
End Namespace
