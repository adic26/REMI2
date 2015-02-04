Imports REMI.Contracts
Imports REMI.Validation

Namespace REMI.BusinessEntities

    <Serializable()> _
    Public Class RequestFields
        Inherits LoggedItemBase
        Implements IRequestFields

#Region "Private Variables"
        Private _fieldSetupID As Int32
        Private _fieldTypeID As Int32
        Private _fieldValidationID As Int32
        Private _displayOrder As Int32
        Private _columnOrder As Int32
        Private _optionsTypeID As Int32
        Private _requestTypeID As Int32
        Private _requestID As Int32
        Private _internalField As Int32
        Private _requestType As String
        Private _defaultValue As String
        Private _name As String
        Private _fieldType As String
        Private _fieldValidation As String
        Private _optionsTypeName As String
        Private _category As String
        Private _intField As String
        Private _extField As String
        Private _requestNumber As String
        Private _value As String
        Private _description As String
        Private _parentFieldSetupName As String
        Private _isRequired As Boolean
        Private _isArchived As Boolean
        Private _isFromExternalSystem As Boolean
        Private _hasIntegration As Boolean
        Private _optionsType As List(Of String)
        Private _newRequest As Boolean
        Private _customLookupHierarchy As List(Of RequestFieldObjectHeirarchy)
        Private _parentFieldSetupID As Int32
#End Region

#Region "Construcor(s)"
        Public Sub New()
        End Sub

        Public Sub New(ByVal fieldSetupID As Int32, ByVal fieldTypeID As Int32, ByVal fieldValidationID As Int32, ByVal displayOrder As Int32, ByVal optionsTypeID As Int32, ByVal requestTypeID As Int32, ByVal requestType As String, ByVal name As String, ByVal fieldType As String, ByVal fieldValidation As String, ByVal isRequired As Boolean, ByVal isArchived As Boolean, ByVal description As String, ByVal optionsType As List(Of String), ByVal requestID As Int32, ByVal requestNumber As String, ByVal value As String, ByVal internalField As Int32, ByVal intField As String, ByVal extField As String, ByVal newRequest As Boolean, ByVal columnOrder As Int32, ByVal isFromExternalSystem As Boolean, ByVal parentFieldSetupID As Int32, ByVal hasIntegration As Boolean, ByVal parentFieldSetupName As String, ByVal defaultval As String)
            _fieldSetupID = fieldSetupID
            _fieldTypeID = fieldTypeID
            _fieldValidationID = fieldValidationID
            _displayOrder = displayOrder
            _optionsTypeID = optionsTypeID
            _requestTypeID = requestTypeID
            _requestType = requestType
            _name = name
            _fieldType = fieldType
            _fieldValidation = fieldValidation
            _isRequired = isRequired
            _isArchived = isArchived
            _description = description
            _optionsType = optionsType
            _requestID = requestID
            _requestNumber = requestNumber
            _value = value
            _internalField = internalField
            _columnOrder = columnOrder
            _extField = extField
            _intField = intField
            _newRequest = newRequest
            _isFromExternalSystem = isFromExternalSystem
            _hasIntegration = hasIntegration
            _parentFieldSetupID = parentFieldSetupID
            _parentFieldSetupName = parentFieldSetupName
            _defaultValue = defaultval
        End Sub
#End Region

#Region "Public Properties"
        Public Property RequestTypeID() As Int32 Implements IRequestFields.RequestTypeID
            Get
                Return _requestTypeID
            End Get
            Set(ByVal value As Int32)
                _requestTypeID = value
            End Set
        End Property

        Public Property RequestType() As String Implements IRequestFields.RequestType
            Get
                Return _requestType
            End Get
            Set(ByVal value As String)
                _requestType = value
            End Set
        End Property

        Public Property RequestID() As Int32 Implements IRequestFields.RequestID
            Get
                Return _requestID
            End Get
            Set(ByVal value As Int32)
                _requestID = value
            End Set
        End Property

        Public Property RequestNumber() As String Implements IRequestFields.RequestNumber
            Get
                Return _requestNumber
            End Get
            Set(ByVal value As String)
                _requestNumber = value
            End Set
        End Property

        Public Property InternalField() As Int32 Implements IRequestFields.InternalField
            Get
                Return _internalField
            End Get
            Set(ByVal value As Int32)
                _internalField = value
            End Set
        End Property

        Public Property FieldSetupID() As Int32 Implements IRequestFields.FieldSetupID
            Get
                Return _fieldSetupID
            End Get
            Set(ByVal value As Int32)
                _fieldSetupID = value
            End Set
        End Property

        Public Property Name() As String Implements IRequestFields.Category
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Public Property Category() As String Implements IRequestFields.Name
            Get
                Return _category
            End Get
            Set(ByVal value As String)
                _category = value
            End Set
        End Property

        Public Property DisplayOrder() As Int32 Implements IRequestFields.DisplayOrder
            Get
                Return _displayOrder
            End Get
            Set(ByVal value As Int32)
                _displayOrder = value
            End Set
        End Property

        Public Property ColumnOrder() As Int32 Implements IRequestFields.ColumnOrder
            Get
                Return _columnOrder
            End Get
            Set(ByVal value As Int32)
                _columnOrder = value
            End Set
        End Property

        Public Property IsRequired() As Boolean Implements IRequestFields.IsRequired
            Get
                Return _isRequired
            End Get
            Set(ByVal value As Boolean)
                _isRequired = value
            End Set
        End Property

        Public Property FieldTypeID() As Int32 Implements IRequestFields.FieldTypeID
            Get
                Return _fieldTypeID
            End Get
            Set(ByVal value As Int32)
                _fieldTypeID = value
            End Set
        End Property

        Public Property FieldType() As String Implements IRequestFields.FieldType
            Get
                Return _fieldType
            End Get
            Set(ByVal value As String)
                _fieldType = value
            End Set
        End Property

        Public Property FieldValidationID() As Int32 Implements IRequestFields.FieldValidationID
            Get
                Return _fieldValidationID
            End Get
            Set(ByVal value As Int32)
                _fieldValidationID = value
            End Set
        End Property

        Public Property FieldValidation() As String Implements IRequestFields.FieldValidation
            Get
                Return _fieldValidation
            End Get
            Set(ByVal value As String)
                _fieldValidation = value
            End Set
        End Property

        Public Property Description() As String Implements IRequestFields.Description
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Public Property OptionsTypeID() As Int32 Implements IRequestFields.OptionsTypeID
            Get
                Return _optionsTypeID
            End Get
            Set(ByVal value As Int32)
                _optionsTypeID = value
            End Set
        End Property

        Public Property OptionsType() As List(Of String) Implements IRequestFields.OptionsType
            Get
                Return _optionsType
            End Get
            Set(ByVal value As List(Of String))
                _optionsType = value
            End Set
        End Property

        Public Property OptionsTypeName() As String Implements IRequestFields.OptionsTypeName
            Get
                Return _optionsTypeName
            End Get
            Set(ByVal value As String)
                _optionsTypeName = value
            End Set
        End Property

        Public Property DefaultValue() As String Implements IRequestFields.DefaultValue
            Get
                Return _defaultValue
            End Get
            Set(value As String)
                _defaultValue = value
            End Set
        End Property

        Public Property CustomLookupHierarchy() As List(Of RequestFieldObjectHeirarchy)
            Get
                Return _customLookupHierarchy
            End Get
            Set(value As List(Of RequestFieldObjectHeirarchy))
                _customLookupHierarchy = value
            End Set
        End Property

        Public Property IsArchived() As Boolean Implements IRequestFields.IsArchived
            Get
                Return _isArchived
            End Get
            Set(ByVal value As Boolean)
                _isArchived = value
            End Set
        End Property

        Public Property IntField() As String Implements IRequestFields.IntField
            Get
                Return _intField
            End Get
            Set(ByVal value As String)
                _intField = value
            End Set
        End Property

        Public Property ExtField() As String Implements IRequestFields.ExtField
            Get
                Return _extField
            End Get
            Set(ByVal value As String)
                _extField = value
            End Set
        End Property

        Public Property IsFromExternalSystem() As Boolean Implements IRequestFields.IsFromExternalSystem
            Get
                Return _isFromExternalSystem
            End Get
            Set(value As Boolean)
                _isFromExternalSystem = value
            End Set
        End Property

        Public Property HasIntegration() As Boolean Implements IRequestFields.HasIntegration
            Get
                Return _hasIntegration
            End Get
            Set(value As Boolean)
                _hasIntegration = value
            End Set
        End Property

        Public Property Value() As String Implements IRequestFields.Value
            Get
                Return _value
            End Get
            Set(ByVal value As String)
                _value = value
            End Set
        End Property

        Public Property NewRequest() As Boolean Implements IRequestFields.NewRequest
            Get
                Return _newRequest
            End Get
            Set(ByVal value As Boolean)
                _newRequest = value
            End Set
        End Property

        Public Property ParentFieldSetupID() As Int32 Implements IRequestFields.ParentFieldSetupID
            Get
                Return _parentFieldSetupID
            End Get
            Set(ByVal value As Int32)
                _parentFieldSetupID = value
            End Set
        End Property

        Public Property ParentFieldSetupName() As String Implements IRequestFields.ParentFieldSetupName
            Get
                Return _parentFieldSetupName
            End Get
            Set(ByVal value As String)
                _parentFieldSetupName = value
            End Set
        End Property
#End Region

        Public Overrides Function ToString() As String
            Return String.Format("{0}", Me.Name)
        End Function
    End Class

    <Serializable()> _
    Public Class RequestFieldObjectHeirarchy
        Private _RequestTypeID As Int32
        Private _ParentLookupID As Int32
        Private _ChildLookupID As Int32
        Private _ParentLookupTypeID As Int32
        Private _ChildLookupTypeID As Int32
        Private _ParentLookup As String
        Private _ChildLookup As String
        Private _ParentLookupType As String
        Private _ChildLookupType As String

        Public Sub New(ByVal rtID As Int32, ByVal plID As Int32, ByVal clID As Int32, ByVal pltID As Int32, ByVal cltID As Int32, ByVal pl As String, ByVal cl As String, ByVal plt As String, ByVal clt As String)
            _RequestTypeID = rtID
            _ParentLookupID = plID
            _ChildLookupID = clID
            _ParentLookupTypeID = pltID
            _ChildLookupTypeID = cltID
            _ParentLookup = pl
            _ChildLookup = cl
            _ParentLookupType = plt
            _ChildLookupType = clt
        End Sub

        Public Sub New()
        End Sub

        Public Property RequestTypeID() As Int32
            Get
                Return _RequestTypeID
            End Get
            Set(value As Int32)
                _RequestTypeID = value
            End Set
        End Property

        Public Property ParentLookupID() As Int32
            Get
                Return _ParentLookupID
            End Get
            Set(value As Int32)
                _ParentLookupID = value
            End Set
        End Property

        Public Property ChildLookupID() As Int32
            Get
                Return _ChildLookupID
            End Get
            Set(value As Int32)
                _ChildLookupID = value
            End Set
        End Property

        Public Property ChildLookupTypeID() As Int32
            Get
                Return _ChildLookupTypeID
            End Get
            Set(value As Int32)
                _ChildLookupTypeID = value
            End Set
        End Property

        Public Property ParentLookupTypeID() As Int32
            Get
                Return _ParentLookupTypeID
            End Get
            Set(value As Int32)
                _ParentLookupTypeID = value
            End Set
        End Property

        Public Property ParentLookup() As String
            Get
                Return _ParentLookup
            End Get
            Set(value As String)
                _ParentLookup = value
            End Set
        End Property

        Public Property ChildLookup() As String
            Get
                Return _ChildLookup
            End Get
            Set(value As String)
                _ChildLookup = value
            End Set
        End Property

        Public Property ParentLookupType() As String
            Get
                Return _ParentLookupType
            End Get
            Set(value As String)
                _ParentLookupType = value
            End Set
        End Property

        Public Property ChildLookupType() As String
            Get
                Return _ChildLookupType
            End Get
            Set(value As String)
                _ChildLookupType = value
            End Set
        End Property
    End Class
End Namespace