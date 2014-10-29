Imports REMI.Contracts
Imports REMI.Validation

Namespace REMI.BusinessEntities

    <Serializable()> _
    Public Class RequestFields
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _fieldSetupID As Int32
        Private _fieldTypeID As Int32
        Private _fieldValidationID As Int32
        Private _displayOrder As Int32
        Private _optionsTypeID As Int32
        Private _requestID As Int32
        Private _requestType As String
        Private _name As String
        Private _fieldType As String
        Private _fieldValidation As String
        Private _description As String
        Private _isRequired As Boolean
        Private _isArchived As Boolean
        Private _optionsType As List(Of String)
#End Region

#Region "Construcor(s)"
        Public Sub New()
        End Sub

        Public Sub New(ByVal fieldSetupID As Int32, ByVal fieldTypeID As Int32, ByVal fieldValidationID As Int32, ByVal displayOrder As Int32, ByVal optionsTypeID As Int32, ByVal requestID As Int32, ByVal requestType As String, ByVal name As String, ByVal fieldType As String, ByVal fieldValidation As String, ByVal isRequired As Boolean, ByVal isArchived As Boolean, ByVal description As String, ByVal optionsType As List(Of String))
            _fieldSetupID = fieldSetupID
            _fieldTypeID = fieldTypeID
            _fieldValidationID = fieldValidationID
            _displayOrder = displayOrder
            _optionsTypeID = optionsTypeID
            _requestID = requestID
            _requestType = requestType
            _name = name
            _fieldType = fieldType
            _fieldValidation = fieldValidation
            _isRequired = isRequired
            _isArchived = isArchived
            _description = description
            _optionsType = optionsType
        End Sub
#End Region

#Region "Public Properties"
        Public Property OptionsType() As List(Of String)
            Get
                Return _optionsType
            End Get
            Set(ByVal value As List(Of String))
                _optionsType = value
            End Set
        End Property

        Public Property FieldSetupID() As Int32
            Get
                Return _fieldSetupID
            End Get
            Set(ByVal value As Int32)
                _fieldSetupID = value
            End Set
        End Property

        Public Property FieldTypeID() As Int32
            Get
                Return _fieldTypeID
            End Get
            Set(ByVal value As Int32)
                _fieldTypeID = value
            End Set
        End Property

        Public Property FieldValidationID() As Int32
            Get
                Return _fieldValidationID
            End Get
            Set(ByVal value As Int32)
                _fieldValidationID = value
            End Set
        End Property

        Public Property DisplayOrder() As Int32
            Get
                Return _displayOrder
            End Get
            Set(ByVal value As Int32)
                _displayOrder = value
            End Set
        End Property

        Public Property OptionsTypeID() As Int32
            Get
                Return _optionsTypeID
            End Get
            Set(ByVal value As Int32)
                _optionsTypeID = value
            End Set
        End Property

        Public Property RequestID() As Int32
            Get
                Return _requestID
            End Get
            Set(ByVal value As Int32)
                _requestID = value
            End Set
        End Property

        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Public Property RequestType() As String
            Get
                Return _requestType
            End Get
            Set(ByVal value As String)
                _requestType = value
            End Set
        End Property

        Public Property FieldType() As String
            Get
                Return _fieldType
            End Get
            Set(ByVal value As String)
                _fieldType = value
            End Set
        End Property

        Public Property FieldValidation() As String
            Get
                Return _fieldValidation
            End Get
            Set(ByVal value As String)
                _fieldValidation = value
            End Set
        End Property

        Public Property Description() As String
            Get
                Return _description
            End Get
            Set(ByVal value As String)
                _description = value
            End Set
        End Property

        Public Property IsArchived() As Boolean
            Get
                Return _isArchived
            End Get
            Set(ByVal value As Boolean)
                _isArchived = value
            End Set
        End Property

        Public Property IsRequired() As Boolean
            Get
                Return _isRequired
            End Get
            Set(ByVal value As Boolean)
                _isRequired = value
            End Set
        End Property
#End Region

        Public Overrides Function ToString() As String
            Return String.Format("{0}", Me.Name)
        End Function
    End Class
End Namespace