Imports System.Resources
Namespace REMI.Validation
    Public Interface IValidatable
        Function Validate() As Boolean
        Function Validate(ByVal ClearNotifications As Boolean) As Boolean
        Function GetValidationMessage(ByVal Key As String) As String
        Property ResourceManager() As ResourceManager
        Function HasErrors() As Boolean
        ReadOnly Property Notifications() As NotificationCollection
    End Interface
End Namespace
