Imports System

Namespace REMI.Validation
    ''' <summary> 
    ''' The EnumerationSetAttribute class allows you to make sure that a string value is not null or an empty string. 
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class EnumerationSetAttribute
        Inherits ValidationAttribute

        ''' <summary> 
        ''' Determines whether the value of the underlying property (passed in as the <paramref name="item"/> parameter) 
        ''' was set to a value. This is applied to enumerations which have a "NotSet" Value. "NotSet" should not be used. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item is not "NotSet"; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal Item As Object) As Boolean
            'get the value of the item. any item =0 is not set
            Dim tmpInt As Integer = CInt(Item)
            Return tmpInt > 0
        End Function
    End Class
End Namespace