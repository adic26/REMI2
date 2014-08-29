Imports System
Imports System.Linq
Imports System.Reflection
Imports System.Diagnostics
Imports System.Resources


Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidationBase class serves as the base class for all business entities that want to implement 
    ''' the validation behavior. It provides Validate methods that are able to check the validity of 
    ''' this instance's properties by looking at the applied attributes. 
    ''' </summary> 
    <Serializable()> _
    Public Class ValidationBase
        Implements IValidatable
        Private Shared _resourceManager As ResourceManager
        <DebuggerBrowsable(DebuggerBrowsableState.Never)> _
    Private _Notifications As New NotificationCollection()
        ''' <summary> 
        ''' Determines whether the current instance meets all validation rules. It always clears the Notifications collection 
        ''' first before adding new Notification instances. 
        ''' </summary> 
        ''' <overloads> 
        ''' Determines whether the current instance meets all validation rules. 
        ''' </overloads> 
        ''' <returns>Returns <c>true</c> if the instance is valid, <c>false</c> otherwise.</returns> 
        ''' <remarks>This method automatically clears the internal Notifications collection.</remarks> 
        Public Overridable Function Validate() As Boolean Implements IValidatable.Validate
            Return Validate(True)
        End Function
        ''' <summary> 
        ''' Determines whether the current instance meets all validation rules. You can optionally determine 
        ''' whether the Notifications collection should be cleared or not. 
        ''' </summary> 
        ''' <param name="clearNotifications">If set to <c>true</c> the Notifications collection is cleared first.</param> 
        ''' <returns> 
        ''' Returns <c>true</c> if the instance is valid, <c>false</c> otherwise. 
        ''' </returns> 
        Public Overridable Function Validate(ByVal ClearNotifications As Boolean) As Boolean Implements IValidatable.Validate
            If ClearNotifications Then
                Me.Notifications.Clear()
            End If

            Dim Properties As PropertyInfo() = Me.[GetType]().GetProperties(BindingFlags.[Public] Or BindingFlags.Instance)

            Dim ValidProps = From Prop In Properties _
             Where Prop.GetCustomAttributes(GetType(ValidationAttribute), True).Length > 0 _
             Select New With {.[Property] = Prop, .ValidationAttributes = Prop.GetCustomAttributes(GetType(ValidationAttribute), True)}

            For Each Item In ValidProps

                For Each Attribute As ValidationAttribute In Item.ValidationAttributes
                    If Attribute.IsValid(Item.[Property].GetValue(Me, Nothing)) Then
                        Continue For
                    End If
                    'the following code was moved to the notification class
                    'Dim Message As String = String.Empty
                    'If Not String.IsNullOrEmpty(Attribute.Key) Then
                    '    Message = GetValidationMessage(Attribute.Key)
                    'Else
                    '    Message = Attribute.Message
                    'End If
                    Notifications.Add(New Notification(Me.[GetType]().ToString + "." + Item.[Property].Name, Attribute.Key, NotificationType.Warning))
                Next
            Next
            Return (Notifications.Count = 0)
        End Function

        ''' <summary> 
        ''' When overriden in a child class, this method gets the localized validation message based on the message key. 
        ''' </summary> 
        ''' <param name="key">The translation key of the validation message.</param> 
        ''' <returns>By default, this method returns the key "as is" and does not try to localize it. Classes overriding this method may localize the method using a ResourceManager.</returns> 
        Protected Overridable Function GetValidationMessage(ByVal Key As String) As String Implements IValidatable.GetValidationMessage
            Dim TempValue As String
            If ResourceManager IsNot Nothing Then
                TempValue = ResourceManager.GetString(Key)
            Else
                TempValue = String.Empty
            End If
            'this returns the gneral (en) messgae
            If String.IsNullOrEmpty(TempValue) Then
                TempValue = ResourceManager.GetString(Key)
            End If
            Return TempValue
        End Function
        ''' <summary> 
        ''' The ResourceManager used by the validation framework. 
        ''' </summary> 
        Public Property ResourceManager() As ResourceManager Implements IValidatable.ResourceManager
            Get
                Return _resourceManager
            End Get
            Set(ByVal value As ResourceManager)
                _resourceManager = value
            End Set
        End Property
        ''' <summary>
        ''' Indicates if the object has errors.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function HasErrors() As Boolean Implements IValidatable.HasErrors
            Return Me.Notifications.HasErrors
        End Function
        ''' <summary> 
        ''' Gets a collection of <see cref="Notifications"/> instances associated with this ValidationBase instance. 
        ''' </summary> 
        ''' <value>The broken rules associated with this ValidationBase.</value> 
        Public ReadOnly Property Notifications() As NotificationCollection Implements IValidatable.Notifications
            Get
                Return _Notifications
            End Get
        End Property
    End Class
End Namespace