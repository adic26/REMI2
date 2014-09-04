Imports REMI.Contracts
Imports REMI.Validation
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' <para>The test class represents the lowest of three test levels in the system. this represents an individual test step in a test stage For Example:</para>
    ''' <list>
    ''' <item>Counducted RF</item>
    ''' <item>Bluetooth</item>
    ''' <item>Visual Inspection</item>
    ''' <item>Camera Test</item>
    ''' </list>
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class Test
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _name As String
        Private _duration As TimeSpan
        Private _testType As TestType
        Private _wiLocation As String
        Private _comments As String
        Private _resultIsTimeBased As Boolean
        Private _trackingLocationTypes As TrackingLocationTypeCollection
        Private _canDelete As Boolean
        Private _isArchived As Boolean = False
        Private _jobName As String
        Private _testStage As String
        Private _owner As String
        Private _trainee As String
        Private _degradation As Decimal
#End Region

#Region "Construcor(s)"

        ''' <summary>
        ''' This is the default constructor for the class.
        ''' </summary>
        ''' <remarks></remarks>
        Public Sub New()
            TestType = TestType.NotSet
            _isArchived = False
            _trackingLocationTypes = New TrackingLocationTypeCollection
        End Sub

        Public Sub New(ByVal Name As String, ByVal WILocation As String, _
                        ByVal TestType As TestType, ByVal trackingLocationTypes As TrackingLocationTypeCollection, ByVal totalHours As String)
            Me.Name = Name
            Me.WorkInstructionLocation = WILocation
            Me.TestType = TestType
            Me.TotalHours = totalHours
            Me.TrackingLocationTypes = trackingLocationTypes
            _isArchived = False
        End Sub

#End Region

#Region "Public Properties"
        Public Property TrackingLocationTypes() As TrackingLocationTypeCollection
            Get
                Return _trackingLocationTypes
            End Get
            Set(ByVal value As TrackingLocationTypeCollection)
                _trackingLocationTypes = value
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the name of the test.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(Key:="w19")> _
        <ValidStringLength(Key:="w20", Maxlength:=400)> _
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the expected duration of the test.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property Duration() As TimeSpan
            Get
                Return _duration
            End Get
            Set(ByVal value As TimeSpan)
                _duration = value
            End Set
        End Property

        Public Property CanDelete() As Boolean
            Get
                Return _canDelete
            End Get
            Set(value As Boolean)
                _canDelete = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the work instruction location (web address) for the test
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(Key:="w23", Maxlength:=400)> _
        Public Property WorkInstructionLocation() As String
            Get
                Return _wiLocation
            End Get
            Set(ByVal value As String)
                _wiLocation = value
            End Set
        End Property
        <ValidStringLength(Key:="w33", Maxlength:=1000)> _
        Public Property Comments() As String
            Get
                Return _comments
            End Get
            Set(ByVal value As String)
                _comments = value
            End Set
        End Property

        Public Property TestStage() As String
            Get
                Return _testStage
            End Get
            Set(ByVal value As String)
                _testStage = value
            End Set
        End Property

        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

        Public Property Owner() As String
            Get
                Return _owner
            End Get
            Set(ByVal value As String)
                _owner = value
            End Set
        End Property

        Public Property Degradation() As Decimal
            Get
                Return _degradation
            End Get
            Set(ByVal value As Decimal)
                _degradation = value
            End Set
        End Property

        Public Property Trainee() As String
            Get
                Return _trainee
            End Get
            Set(ByVal value As String)
                _trainee = value
            End Set
        End Property

        Public Property IsArchived() As Boolean
            Get
                Return _isArchived
            End Get
            Set(value As Boolean)
                _isArchived = value
            End Set
        End Property


        ''' <summary>
        ''' Gets or sets the test type of the test.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <EnumerationSet(key:="w26")> _
        Public Property TestType() As TestType
            Get
                Return _testType
            End Get
            Set(ByVal value As TestType)
                _testType = value
            End Set
        End Property

        <ValidRange(Key:="w21", max:=99999, min:=0)> _
        Public Property TotalHours() As String
            Get
                Return _duration.TotalHours.ToString
            End Get
            Set(ByVal value As String)
                'This setter checks the given value first
                Dim f As Double
                If Double.TryParse(value, f) Then
                    _duration = TimeSpan.FromHours(f)
                Else
                    _duration = Nothing
                End If
            End Set
        End Property

        Public Property ResultIsTimeBased() As Boolean
            Get
                Return _resultIsTimeBased
            End Get
            Set(ByVal value As Boolean)
                _resultIsTimeBased = value
            End Set
        End Property

#End Region


        ''' <summary>
        ''' Overrides the default to string and returns the name of the test
        ''' </summary>
        ''' <returns>The test name</returns>
        ''' <remarks></remarks>

        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(Me.Name) Then
                Return String.Empty
            Else
                Return Me.Name
            End If
        End Function

    End Class

End Namespace