Imports System
Imports System.Text.RegularExpressions
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidFailDocNumber checks that a fail doc number is valid by checking against a RegEx.
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidFailDocNumber
        Inherits ValidationAttribute

        Public Overloads Overrides Function IsValid(ByVal item As Object) As Boolean
            Dim number As String = DirectCast(item, String)
            Dim returnVal As Boolean = False
            Select Case number.Length
                Case 17
                    If Regex.IsMatch(number, "^FA-([a-zA-Z]){3}[-]([0-9]){4}[-]([0-9]){5}$") Then
                        returnVal = True 'valid fa
                    End If
                Case 14
                    If Regex.IsMatch(number, "^RIT-([0-9]){4}[-]([0-9]){5}$") Then
                        returnVal = True 'valid rit
                    End If
            End Select
            Return returnVal
        End Function
    End Class

End Namespace