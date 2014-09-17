
Imports REMI.Validation
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' This class represents a tracking location type. 
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class TrackingLocationType
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _name As String
        Private _TrackingLocationFunction As TrackingLocationFunction
        Private _comment As String
        Private _WILocation As String
        Private _unitCapacity As Integer
        Private _canDelete As Int32
#End Region
#Region "constructor"
        Public Sub New()
            _TrackingLocationFunction = TrackingLocationFunction.NotSet
        End Sub
#End Region
#Region "Public Properties"

        ''' <summary>
        ''' Gets or sets the name of the test station type.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(Key:="w1", MaxLength:=100)> _
        <NotNullOrEmpty(Key:="w2")> _
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property
        Public Property Comment() As String
            Get
                Return _comment
            End Get
            Set(ByVal value As String)
                _comment = value
            End Set
        End Property
        Public Property WILocation() As String
            Get
                Return _WILocation
            End Get
            Set(ByVal value As String)
                _WILocation = value
            End Set
        End Property
        <ValidRange(Key:="w3", Max:=99999, Min:=0)> _
        Public Property UnitCapacity() As Integer
            Get
                Return _unitCapacity
            End Get
            Set(ByVal value As Integer)
                _unitCapacity = value
            End Set
        End Property

        Public Property CanDelete() As Int32
            Get
                Return _canDelete
            End Get
            Set(value As Int32)
                _canDelete = value
            End Set
        End Property

        <EnumerationSet(key:="w38")> _
        Public Property TrackingLocationFunction() As TrackingLocationFunction
            Get
                Return _TrackingLocationFunction
            End Get
            Set(ByVal value As TrackingLocationFunction)
                _TrackingLocationFunction = value
            End Set
        End Property

#End Region

        ''' <summary>
        ''' Overrides the tostring function to return the name of the test type
        ''' </summary>
        ''' <returns>The test station type name</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(Name) Then
                Return String.Empty
            Else
                Return Name
            End If
        End Function
    End Class
End Namespace
