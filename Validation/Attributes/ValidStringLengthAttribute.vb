Imports System
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidStringLengthAttribute class allows you to make sure that a string has less than a specified number of characters. 
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidStringLengthAttribute
        Inherits ValidationAttribute
        ''' <summary> 
        ''' Gets or sets a value that determines the maximum Length value (inclusive) for the underlying string to be valid. 
        ''' </summary> 
        ''' <remarks>The maximum length value.</remarks>
        Private _MaxLength As Integer
        Public Property MaxLength() As Integer
            Get
                Return _MaxLength
            End Get
            Set(ByVal value As Integer)
                _MaxLength = value
            End Set
        End Property

        ''' <summary> 
        ''' Determines whether the value of the underlying property is less than the maximum length value. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item's length is less than the given maximum; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal item As Object) As Boolean
            Dim tempValue As String = Convert.ToString(item)
            Return tempValue.Length <= MaxLength
        End Function
    End Class
End Namespace