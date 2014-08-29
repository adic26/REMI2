
Namespace REMI.BusinessEntities
    Public Class ProductSetting

        Public Sub New()

        End Sub
        Public Sub New(ByVal keyName As String, ByVal valueText As String, ByVal defaultValue As String)
            Me.DefaultValue = defaultValue
            Me.KeyName = keyName
            Me.ValueText = valueText
        End Sub

        Private _keyName As String
        Public Property KeyName() As String
            Get
                Return _keyName
            End Get
            Set(ByVal value As String)
                _keyName = value
            End Set
        End Property

        Private _valueText As String
        Public Property ValueText() As String
            Get
                Return _valueText
            End Get
            Set(ByVal value As String)
                _valueText = value
            End Set
        End Property

        Private _defaultValue As String
        Public Property DefaultValue() As String
            Get
                Return _defaultValue
            End Get
            Set(ByVal value As String)
                _defaultValue = value
            End Set
        End Property

    End Class
End Namespace
