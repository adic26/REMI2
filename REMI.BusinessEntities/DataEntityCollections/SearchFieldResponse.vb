Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class SearchFieldResponse
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _type As String
        Private _name As String
        Private _testID As Integer
#End Region

#Region "Public Properties"
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Public Property Type() As String
            Get
                Return _type
            End Get
            Set(ByVal value As String)
                _type = value
            End Set
        End Property

        Public Property TestID() As Integer
            Get
                Return _testID
            End Get
            Set(ByVal value As Integer)
                _testID = value
            End Set
        End Property
#End Region

        'Empty Constructor
        Public Sub New()
        End Sub

        Public Sub New(ByVal name As String, ByVal type As String, ByVal testID As Int32)
            Me.Name = name
            Me.Type = type
            Me.TestID = testID
        End Sub
    End Class

    Public Class SearchFieldResponseDefinition
        Public Results As List(Of SearchFieldResponse)
        Public Success As Boolean

        Public Sub New()
            Results = New List(Of SearchFieldResponse)()
            Success = False
        End Sub
    End Class
End Namespace