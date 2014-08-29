Imports System
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidStartDateAttribute class allows you to make sure that a date is a valid date for starting a test. 
    '''
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidStartDateAttribute
        Inherits ValidationAttribute
        ''' <summary> 
        ''' Determines whether the value of the underlying property is after now.
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item falls between Min and Max (inclusive); otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal item As Object) As Boolean
            Dim tmpvalue As DateTime = DirectCast(item, DateTime)
            Return tmpvalue >= DateTime.UtcNow
        End Function
    End Class
End Namespace