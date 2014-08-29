Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.BusinessEntities
    Public Class LookupBase
        Inherits LoggedItemBase
        Implements ILookups

        Private _lookupID As Int32
        Private _type As String
        Private _value As String

        Public Sub New()
        End Sub

        Public Sub New(ByVal type As String)
            If Not String.IsNullOrEmpty(type) Then
                type = type.Trim()
            End If
        End Sub

        Public Property LookupID As Integer Implements Contracts.ILookups.LookupID
            Get
                Return _lookupID
            End Get
            Set(value As Integer)
                _lookupID = value
            End Set
        End Property

        Public Property Type As String Implements Contracts.ILookups.type
            Get
                Return _type
            End Get
            Set(value As String)
                _type = value
            End Set
        End Property

        Public Property Value As String Implements Contracts.ILookups.value
            Get
                Return _value
            End Get
            Set(value As String)
                _value = value
            End Set
        End Property
    End Class
End Namespace