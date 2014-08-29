Imports REMI.Core
Imports REMI.Validation
Imports REMI.Contracts

Namespace REMI.BusinessEntities
    Public Class Calibration
        Inherits LoggedItemBase

        Private _name As String
        Private _productGroupName As String
        Private _hostName As String
        Private _productID As Int32
        Private _hostID As Int32
        Private _testID As Int32
        Private _dateCreated As DateTime
        Private _file As String
        Private _testName As String

        Public Sub New()
        End Sub

        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Public Property TestName() As String
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property

        Public Property ProductGroupName() As String
            Get
                Return _productGroupName
            End Get
            Set(ByVal value As String)
                _productGroupName = value
            End Set
        End Property

        Public Property HostName() As String
            Get
                Return _hostName
            End Get
            Set(ByVal value As String)
                _hostName = value
            End Set
        End Property

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(ByVal value As Int32)
                _testID = value
            End Set
        End Property

        Public Property HostID() As Int32
            Get
                Return _hostID
            End Get
            Set(ByVal value As Int32)
                _hostID = value
            End Set
        End Property

        Public Property ProductID() As Int32
            Get
                Return _productID
            End Get
            Set(ByVal value As Int32)
                _productID = value
            End Set
        End Property

        Public Property DateCreated() As DateTime
            Get
                Return _dateCreated
            End Get
            Set(ByVal value As DateTime)
                _dateCreated = value
            End Set
        End Property

        Public Property File() As String
            Get
                Return _file
            End Get
            Set(ByVal value As String)
                _file = value
            End Set
        End Property
    End Class
End Namespace