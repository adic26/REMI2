Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a new material for adding to the remstar db. this allows the remstar software to automatically add this material type.
    ''' </summary>
    ''' <remarks></remarks>
    Public Class remstarMaterial
        Private _productGroupName As String
        Private _qraNumber As String
        Private _propertyName As String
        Private _binType As String

        Public Sub New(ByVal qraNumber As String, ByVal productGroup As String)
            _qraNumber = qraNumber
            _productGroupName = productGroup
            _propertyName = "Default"
            _binType = "SMALL-REM2"
        End Sub
        Public Property QRAnumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property
        Public Property ProductGroupName() As String
            Get
                Return _productGroupName
            End Get
            Set(ByVal value As String)
                _productGroupName = value
            End Set
        End Property

        Public Property PropertyName() As String
            Get
                Return _propertyName
            End Get
            Set(ByVal value As String)
                _propertyName = value
            End Set
        End Property

        Public Property BinType() As String
            Get
                Return _binType
            End Get
            Set(ByVal value As String)
                _binType = value
            End Set
        End Property
    End Class
End Namespace