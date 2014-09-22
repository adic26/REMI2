Imports REMI.Contracts
Imports REMI.Validation

Namespace REMI.BusinessEntities

    <Serializable()> _
    Public Class Orientation
        Inherits LoggedItemBase
        Implements IOrientation


#Region "Private Variables"
        Private _name As String
        Private _description As String
        Private _definition As String
        Private _productType As String
        Private _jobID As Int32
        Private _ID As Int32
        Private _productTypeID As Int32
        Private _numUnits As Int32
        Private _numDrops As Int32
        Private _createdDate As DateTime
        Private _isActive As Boolean
#End Region

#Region "Construcor(s)"
        Public Sub New()
        End Sub

        Public Sub New(ByVal id As Int32, ByVal name As String, ByVal description As String, ByVal definition As String, ByVal numDrops As Int32, ByVal numUnits As Int32, ByVal jobID As Int32, ByVal productTypeID As Int32, ByVal productType As String, ByVal isActive As Boolean, ByVal created As DateTime)
            Me.ID = id
            Me.Name = name
            Me.Description = description
            Me.Definition = definition
            Me.NumDrops = numDrops
            Me.NumUnits = numUnits
            Me.ProductType = productType
            Me.ProductTypeID = productTypeID
            Me.JobID = jobID
            Me.CreatedDate = created
        End Sub
#End Region

#Region "Public Properties"
        Public Property Name() As String Implements IOrientation.Name
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Public Property Description() As String Implements IOrientation.Description
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Public Property Definition() As String Implements IOrientation.Definition
            Get
                Return _definition
            End Get
            Set(ByVal value As String)
                _definition = value
            End Set
        End Property

        Public Property ProductType() As String Implements IOrientation.ProductType
            Get
                Return _productType
            End Get
            Set(ByVal value As String)
                _productType = value
            End Set
        End Property

        Public Property CreatedDate() As DateTime Implements IOrientation.CreatedDate
            Get
                Return _createdDate
            End Get
            Set(ByVal value As DateTime)
                _createdDate = value
            End Set
        End Property

        Public Property IsActive() As Boolean Implements IOrientation.IsActive
            Get
                Return _isActive
            End Get
            Set(ByVal value As Boolean)
                _isActive = value
            End Set
        End Property

        Public Overrides Property ID() As Int32 Implements IOrientation.ID
            Get
                Return _ID
            End Get
            Set(ByVal value As Int32)
                _ID = value
            End Set
        End Property

        Public Property JobID() As Int32 Implements IOrientation.JobID
            Get
                Return _jobID
            End Get
            Set(ByVal value As Int32)
                _jobID = value
            End Set
        End Property

        Public Property ProductTypeID() As Int32 Implements IOrientation.ProductTypeID
            Get
                Return _productTypeID
            End Get
            Set(ByVal value As Int32)
                _productTypeID = value
            End Set
        End Property

        Public Property NumDrops() As Int32 Implements IOrientation.NumDrops
            Get
                Return _numDrops
            End Get
            Set(ByVal value As Int32)
                _numDrops = value
            End Set
        End Property

        Public Property NumUnits() As Int32 Implements IOrientation.NumUnits
            Get
                Return _numUnits
            End Get
            Set(ByVal value As Int32)
                _numUnits = value
            End Set
        End Property
#End Region

        Public Overrides Function ToString() As String
            Return String.Format("{0} - {1}", Me.Name, Me.ProductType)
        End Function
    End Class
End Namespace