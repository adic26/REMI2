Imports System
Imports System.Text.RegularExpressions
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidBarcodeString checks that a barocde string is valid by checking against a RegEx.
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidTRSRequestString
        Inherits ValidationAttribute
        ''' <summary> 
        ''' Determines whether the barcode string can be accepted and used to create a barcode object. 
        ''' </summary> 
        ''' <param name="item">The string representation of the barcode being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the barcode matches a reg ex; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal item As Object) As Boolean
            Dim number As String = DirectCast(item, String)
            Dim returnVal As Boolean = False
            If Not String.IsNullOrEmpty(number) Then
                Select Case number.Length
                    Case 11
                        If Regex.IsMatch(number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}$") Then
                            returnVal = True
                        End If
                    Case 14
                        If Regex.IsMatch(number, "^RIT-([0-9]){4}[-]([0-9]){5}$") OrElse Regex.IsMatch(number, "^SCM-([0-9]){4}[-]([0-9]){5}$") Then
                            returnVal = True
                        End If
                    Case 15
                        If Regex.IsMatch(number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){3}$") Then
                            returnVal = True
                        End If
                    Case 17
                        If Regex.IsMatch(number, "^FA-([a-zA-Z]){3}[-]([0-9]){4}[-]([0-9]){5}$") Then
                            returnVal = True
                        End If
                    Case 17
                        If Regex.IsMatch(number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){5}$") Then
                            returnVal = True
                        End If
                    Case 21
                        If Regex.IsMatch(number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){3}[-]([0-9]){5}$") Then
                            returnVal = True
                        End If
                End Select
            Else
                Return False
            End If
            Return returnVal
        End Function
    End Class
End Namespace