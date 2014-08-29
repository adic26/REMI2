Imports System

Namespace REMI.Validation
    ''' <summary> 
    ''' The NotNullOrEmptyAttribute class allows you to make sure that a string value is not null or an empty string. 
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class NotNullOrEmptyAttribute
        Inherits ValidationAttribute

        ''' <summary> 
        ''' Determines whether the value of the underlying property (passed in as the <paramref name="item"/> parameter) 
        ''' is not null or an empty string. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item is not null or an empty string; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal Item As Object) As Boolean
            If TypeOf Item Is String Then
                Return Not String.IsNullOrEmpty(TryCast(Item, String))
            End If
            If TypeOf Item Is DateTime Then
                Return (DirectCast(Item, DateTime) > DateTime.MinValue)
            End If
            Return Item IsNot Nothing
        End Function
    End Class
End Namespace