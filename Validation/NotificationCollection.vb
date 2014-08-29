
Imports System
Imports System.Collections.Generic
Imports System.Collections.ObjectModel
Imports System.Linq
Imports System.Text
Namespace REMI.Validation
    ''' <summary> 
    ''' The BrokenRulesCollection is designed to hold <see cref="Notification"/> items and supplies 
    ''' additional querying capabilities to retrieve specific BrokenRule instances. 
    ''' </summary> 
    <Serializable()> _
    Public Class NotificationCollection
        Inherits Collection(Of Notification)
        Public Event ItemAdded(ByVal Type As NotificationType)
#Region "Constructors"

        ''' <summary> 
        ''' Initializes a new instance of the <see cref="NotificationCollection"/> class. 
        ''' </summary> 
        ''' <param name="myList">My list.</param> 
        Friend Sub New(ByVal myList As IList(Of Notification))
            MyBase.New(myList)
        End Sub

        ''' <summary> 
        ''' Initializes a new instance of the <see cref="notificationCollection"/> class. 
        ''' </summary> 
        Public Sub New()
        End Sub


#End Region

#Region "Public Methods"

        ''' <summary> 
        ''' Returns a NotificationCollection with the rules for the specified property name. 
        ''' </summary> 
        ''' <param name="PropertyName">The (case insensitive) name of the property.</param> 
        ''' <returns>A NotificationCollection for the specified property name. Returns an empty collection when the specified property name is not found.</returns> 
        Public Function FindByPropertyName(ByVal PropertyName As String) As NotificationCollection
            Return New NotificationCollection((From Rule In Me _
             Where Rule.PropertyName.ToUpperInvariant() = PropertyName.ToUpperInvariant() _
             Select Rule).ToList())
        End Function

        ''' <summary>
        ''' Returns a NotificationCollection with the rules that contain (a part) of the specified message.. 
        ''' </summary> 
        ''' <param name="message">The (case insensitive) part of the message to search for.</param> 
        ''' <returns>A NotificationCollection containing the rules that match the specified message. Returns an empty collection when the specified message is not found.</returns> 
        Public Function FindByMessage(ByVal Message As String) As NotificationCollection
            Return New NotificationCollection((From Rule In Me _
              Where Rule.Message.ToUpperInvariant().Contains(Message.ToUpperInvariant()) _
              Select Rule).ToList())
        End Function
        ''' <summary> 
        ''' Returns a NotificationCollection with the rules that contain (a part) of the specified message.. 
        ''' </summary> 
        ''' <param name="Type">The Type or notification to search for.</param> 
        ''' <returns>A NotificationCollection containing the rules that match the specified type. Returns an empty collection when the specified type is not found.</returns> 
        Public Function FindByType(ByVal Type As NotificationType) As NotificationCollection
            Return New NotificationCollection((From Rule In Me _
              Where Rule.Type().Equals(Type) _
              Select Rule).ToList())
        End Function
        Public ReadOnly Property HasErrors() As Boolean
            Get
                If Me.FindByType(NotificationType.Errors).Count > 0 _
                OrElse Me.FindByType(NotificationType.Warning).Count > 0 _
                OrElse Me.FindByType(NotificationType.Fatal).Count > 0 Then
                    Return True
                End If
                Return False
            End Get
        End Property
        Public Overloads Sub Add(ByVal newNotification As Notification)
            If newNotification IsNot Nothing Then
                MyBase.Add(newNotification)
                RaiseEvent ItemAdded(newNotification.Type)
            End If
        End Sub
        ''' <summary>
        ''' This method allows the user to bypass the resource file lookup.
        ''' </summary>
        ''' <param name="Message"></param>
        ''' <param name="type"></param>
        ''' <remarks></remarks>
        Public Sub AddWithMessage(ByVal Message As String, ByVal type As NotificationType)
            Dim nt As New Notification
            nt.Message = Message
            nt.Type = type
            Add(nt)
        End Sub

        ''' <summary> 
        ''' Adds a notfification collection to list
        ''' </summary> 
        ''' <param name="notCollection">The broken rules collection to append.</param> 
        Public Overloads Sub Add(ByVal notCollection As NotificationCollection)
            If notCollection IsNot Nothing AndAlso notCollection.Count > 0 Then
                For Each br As Notification In notCollection
                    Add(br)
                Next
            End If
        End Sub
        ''' <summary> 
        ''' Adds a notification collection to the list but only adds errors and warnings
        ''' </summary> 
        ''' <param name="notCollection">The broken rules collection to append.</param> 
        Public Overloads Sub AddAnyErrorsOrWarnings(ByVal notCollection As NotificationCollection)
            If notCollection IsNot Nothing AndAlso notCollection.Count > 0 Then
                For Each br As Notification In notCollection
                    If br.Type = NotificationType.Errors Or br.Type = NotificationType.Fatal Or br.Type = NotificationType.Warning Then
                        Add(br)
                    End If
                Next
            End If
        End Sub
        Public Overloads Sub add(ByVal errorCode As String, ByVal type As NotificationType, Optional ByVal AdditionalInformation As String = "")
            Add(New Notification(errorCode, type, AdditionalInformation))
        End Sub

        ''' <summary> 
        ''' Creates a new NotificationCollection instance and adds it to the inner list. 
        ''' </summary>
        ''' <param name="propertyName">The name of the property that caused the rule to be broken. Can be left empty.</param> 
        ''' <param name="errorCode">The validation message associated with the broken rule.</param> 
        Public Overloads Sub Add(ByVal PropertyName As String, ByVal errorCode As String, ByVal type As NotificationType, Optional ByVal AdditionalInformation As String = "")
            Add(New Notification(PropertyName, errorCode, type, AdditionalInformation))

        End Sub

        ''' <summary> 
        ''' Returns a <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>. 
        ''' </summary> 
        ''' <returns> 
        ''' A <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>. 
        ''' </returns> 
        Public Overloads Overrides Function ToString() As String
            Dim myStringBuilder As New StringBuilder()
            For Each item As Notification In Me
                myStringBuilder.Append(item.ToString() & vbCr & vbLf)
            Next
            Return myStringBuilder.ToString()
        End Function

#End Region

    End Class
End Namespace