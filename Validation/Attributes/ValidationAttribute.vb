Imports System
Namespace REMI.Validation

    ''' <summary> 
    ''' The ValidationAttribute class is the base class for all validation attributes that can be applied to BO properties 
    ''' in order to define business validation rules. 
    ''' </summary> 
    ''' <example> 
    ''' <code lang="cs"> 
    ''' [NotNullOrEmpty()] 
    ''' public string Street 
    ''' { ... } 
    ''' </code> 
    ''' </example> 
    Public MustInherit Class ValidationAttribute
        Inherits Attribute

#Region "Private Variables"

        Private _Key As String
        Private _Message As String

#End Region

        ''' <summary> 
        ''' Determines whether the value of the underlying property (passed in as the <paramref name="item"/> parameter) 
        ''' is valid according to the validation rule. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item is valid; otherwise, <c>false</c>. 
        ''' </returns> 
        Public MustOverride Function IsValid(ByVal Item As Object) As Boolean

        ''' <summary> 
        ''' Gets the validation message associated with this validation. 
        ''' </summary> 
        ''' <value>The validation message.</value> 
        ''' <exception cref="ArgumentException">Thrown when Key already has a value when you try to set the Message property.</exception> 
        Public Property Message() As String
            Get
                Return _Message
            End Get
            Set(ByVal value As String)
                If Not String.IsNullOrEmpty(_Key) Then
                    Throw New ArgumentException("Can't set Message when Key has already been set.")
                End If
                _Message = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets the the globalization key associated with this validation. 
        ''' </summary> 
        ''' <value>The globalization key.</value> 
        ''' <exception cref="ArgumentException">Thrown when Message already has a value when you try to set the Key property.</exception> 
        Public Property Key() As String
            Get
                Return _Key
            End Get
            Set(ByVal value As String)
                If Not String.IsNullOrEmpty(_Message) Then
                    Throw New ArgumentException("Can't set Key when Message has already been set.")
                End If
                _Key = value
            End Set
        End Property
    End Class
End Namespace