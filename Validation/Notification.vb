Imports System
Imports My.Resources
Namespace REMI.Validation
    ''' <summary> 
    ''' The Notification class provides (localized) information about the object. 
    ''' </summary> 
    <Serializable()> _
    Public Class Notification

#Region "Private Variables"
        Private _PropertyName As String
        Private _Message As String
        Private _additionalInformation As String
        Private _Type As NotificationType
        Private _errorCode As String
#End Region

#Region "Constructor"

        ''' <summary> 
        ''' Initializes a new instance of the Notification class. 
        ''' </summary> 
        ''' <param name="PropertyName">The name of the property that caused the validation error or notification to be made.</param> 
        ''' <param name="errorCode">The message associated with the notification.</param> 
        Public Sub New(ByVal PropertyName As String, ByVal errorCode As String, ByVal type As NotificationType)
            _PropertyName = PropertyName
            If Not String.IsNullOrEmpty(errorCode) Then
                _Message = General.ResourceManager.GetString(errorCode.ToString)
            End If
            _errorCode = errorCode
            _Type = type
        End Sub
        ''' <summary> 
        ''' Initializes a new instance of the Notification class. 
        ''' </summary> 
        ''' <param name="PropertyName">The name of the property that caused the validation error or notification to be made.</param> 
        ''' <param name="errorCode">The message associated with the notification.</param> 
        Public Sub New(ByVal PropertyName As String, ByVal errorCode As String, ByVal type As NotificationType, ByVal additionalInformation As String)
            _PropertyName = PropertyName
            If Not String.IsNullOrEmpty(errorCode) Then
                _Message = General.ResourceManager.GetString(errorCode.ToString)
            End If
            _additionalInformation = additionalInformation
            _errorCode = errorCode
            _Type = type
        End Sub
        ''' <summary>
        ''' The error code is the key used to get the error message from the resource file.
        ''' </summary>
        ''' <param name="errorCode"></param>
        ''' <param name="type"></param>
        ''' <remarks></remarks>
        Public Sub New(ByVal errorCode As String, ByVal type As NotificationType, ByVal additionalInformation As String)
            If Not String.IsNullOrEmpty(errorCode) Then
                _Message = General.ResourceManager.GetString(errorCode.ToString)
            End If
            _additionalInformation = additionalInformation
            _errorCode = errorCode
            _Type = type
        End Sub
        ''' <summary>
        ''' The error code is the key used to get the error message from the resource file.
        ''' </summary>
        ''' <param name="errorCode"></param>
        ''' <param name="type"></param>
        ''' <remarks></remarks>
        Public Sub New(ByVal errorCode As String, ByVal type As NotificationType)
            If Not String.IsNullOrEmpty(errorCode) Then
                _Message = General.ResourceManager.GetString(errorCode.ToString)
            End If
            _errorCode = errorCode
            _Type = type
        End Sub
        Public Sub New()
            Type = NotificationType.NotSet
        End Sub
#End Region

#Region "Public Properties"

        ''' <summary> 
        ''' Gets or sets the error message associated with the notification. 
        ''' </summary> 
        ''' <value>The localized error message.</value> 
        Public Property Message() As String
            Get
                If _Message Is Nothing Then
                    Return String.Empty
                Else
                    Return _Message
                End If
            End Get
            Set(ByVal value As String)
                _Message = value
            End Set
        End Property
        Public Property ErrorCode() As String
            Get
                If _errorCode Is Nothing Then
                    Return String.Empty
                Else
                    Return _errorCode
                End If
            End Get
            Set(ByVal value As String)
                _errorCode = value
            End Set
        End Property
        Public Property AdditionalInformation() As String
            Get
                If _additionalInformation Is Nothing Then
                    Return String.Empty
                Else
                    Return _additionalInformation
                End If
            End Get
            Set(ByVal value As String)
                _additionalInformation = value
            End Set
        End Property
        ''' <summary> 
        ''' Gets or sets the name of the property that caused the notification. 
        ''' </summary> 
        ''' <value>The name of the property.</value> 
        Public Property PropertyName() As String
            Get
                If _PropertyName Is Nothing Then
                    Return String.Empty
                Else
                    Return _PropertyName
                End If

            End Get
            Set(ByVal value As String)
                If value Is Nothing Then
                    value = String.Empty
                End If
                _PropertyName = value
            End Set
        End Property
        Property Type() As NotificationType
            Get
                Return _Type
            End Get
            Set(ByVal value As NotificationType)
                _Type = value
            End Set
        End Property
#End Region

#Region "Public Methods"

        ''' <summary> 
        ''' Returns a <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>. 
        ''' </summary> 
        ''' <returns> 
        ''' A <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>. 
        ''' </returns> 
        Public Overloads Overrides Function ToString() As String
            Dim s As New Text.StringBuilder
            If Type = NotificationType.Errors Then
                s.Append("Error")
            Else
                s.Append(Type.ToString)
            End If

            s.Append(" ")
            If Not String.IsNullOrEmpty(ErrorCode) Then
                s.Append("(")
                s.Append(ErrorCode.ToString())
                s.Append(")")
            End If
            If Not String.IsNullOrEmpty(PropertyName) Then
                s.Append(" on ")
                s.Append(PropertyName)
            End If
            s.Append(": ")
            s.Append(Message)
            If Not String.IsNullOrEmpty(AdditionalInformation) Then
                s.Append(" (")
                s.Append(AdditionalInformation)
                s.Append(")")
            End If
            Return s.ToString
        End Function

#End Region


    End Class
End Namespace