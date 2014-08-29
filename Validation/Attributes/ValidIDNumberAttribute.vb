Imports System

Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidIDNumberAttribute class allows you to make sure that an ID is valid. e.g. greater than 0. 
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidIDNumberAttribute
        Inherits ValidationAttribute

        ''' <summary> 
        ''' Determines whether the value of the underlying property (passed in as the <paramref name="item"/> parameter) 
        ''' is greater than 0. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item is > 0; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal Item As Object) As Boolean
            Return CInt(Item) > 0
        End Function
    End Class
End Namespace