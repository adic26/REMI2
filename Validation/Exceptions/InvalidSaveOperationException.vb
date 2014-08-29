Imports System
Imports System.Runtime.Serialization

Namespace REMI.Validation
    ''' <summary> 
    ''' The InvalidSaveOperationException is thrown in when an attempt 
    ''' is made to save an invalid <see cref="ValidationBase" /> instance in the database. 
    ''' </summary> 
    <Serializable()> _
    Public Class InvalidSaveOperationException
        Inherits Exception

#Region "InvalidSaveOperationException()"
        ''' <summary> 
        ''' Initializes a new instance of the InvalidSaveOperationException class. 
        ''' </summary> 
        Public Sub New()
        End Sub
#End Region

#Region "InvalidSaveOperationException(string message)"
        ''' <summary> 
        ''' Initializes a new instance of the InvalidSaveOperationException class. 
        ''' </summary> 
        ''' <param name="message">The exception message</param> 
        Public Sub New(ByVal Message As String)
            MyBase.New(Message)
        End Sub
#End Region

#Region "InvalidSaveOperationException(string message, Exception innerException)"
        ''' <summary> 
        ''' Initializes a new instance of the InvalidSaveOperationException class. 
        ''' </summary> 
        ''' <param name="message">The exception message</param> 
        ''' <param name="innerException">The inner exception</param> 
        Public Sub New(ByVal Message As String, ByVal InnerException As Exception)
            MyBase.New(Message, InnerException)
        End Sub
#End Region

#Region "InvalidSaveOperationException(SerializationInfo info, StreamingContext context)"
        ''' <summary> 
        ''' Initializes a new instance of the InvalidSaveOperationException class. 
        ''' Serialization constructor. 
        ''' </summary> 
        Protected Sub New(ByVal Info As SerializationInfo, ByVal Context As StreamingContext)
            MyBase.New(Info, Context)
        End Sub
#End Region

    End Class
End Namespace