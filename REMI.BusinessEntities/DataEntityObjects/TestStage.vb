Imports REMI.Contracts
Imports REMI.Validation
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' The test stage class represents the second level of test in the process. A job comprises of a number of test stages. For expample:
    ''' <list>
    ''' <item>Baseline</item>
    ''' <item>150 hour Humidity Cyclic Test</item>
    ''' <item>Post Cyclic Test Measurments</item>
    ''' </list>
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class TestStage
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _processOrder As Integer
        Private _name As String
        Private _tests As TestCollection
        Private _testStageType As TestStageType
        Private _jobName As String
        Private _comments As String
        Private _testID As Integer
        Private _isArchived As Boolean = False
        Private _canDelete As Boolean = False
#End Region

#Region "constructor(s)"

        Public Sub New()
            _tests = New TestCollection
            _testStageType = TestStageType.NotSet
            _isArchived = False
        End Sub

#End Region

#Region "Public Properties"

        'Database properties
        ''' <summary>
        ''' Gets or sets the Name of the test stage
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(key:="w27")> _
        <ValidStringLength(MaxLength:=400, key:="w28")> _
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property
        ''' <summary>
        ''' Represents the order that this test stage is completed in rrelation to the other stages in the job. If the process order is
        ''' negative then the stage is effectively ignored in the process setting calcualations.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property ProcessOrder() As Integer
            Get
                Return _processOrder
            End Get
            Set(ByVal value As Integer)
                _processOrder = value
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

        Public Property IsArchived() As Boolean
            Get
                Return _isArchived
            End Get
            Set(value As Boolean)
                _isArchived = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the test stage type for this test.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <EnumerationSet(key:="w29")> _
        Public Property TestStageType() As TestStageType
            Get
                Return _testStageType
            End Get
            Set(ByVal value As TestStageType)
                _testStageType = value
            End Set
        End Property
        Public Property TestID() As Integer
            Get
                Return _testID
            End Get
            Set(ByVal value As Integer)
                _testID = value
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the tests associated with this test stage
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(key:="w30")> _
        Public Property Tests() As TestCollection
            Get
                Return _tests
            End Get
            Set(ByVal value As TestCollection)
                If value IsNot Nothing Then
                    _tests = value
                End If
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the comments for the test stage
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(MaxLength:=1000, key:="w33")> _
        Public Property Comments() As String
            Get
                Return _comments
            End Get
            Set(ByVal value As String)
                _comments = value
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the job name for the test stage
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(key:="w31")> _
         <ValidStringLength(MaxLength:=800, key:="w32")> _
        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

        ' Claculated properties
        ''' <summary>
        ''' Returns the duration of the test stage by analysing the tests in the test stage
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property Duration() As TimeSpan
            Get
                Dim d As New TimeSpan
                For Each t As Test In Tests
                    d = d.Add(t.Duration)
                Next
                Return d
            End Get
        End Property
        Public ReadOnly Property DurationInHours() As Double
            Get
                Return Duration.TotalHours
            End Get
        End Property
#End Region

        ''' <summary>
        ''' Overrides the default to string and returns the name of the procduct group
        ''' </summary>
        ''' <returns>The test stage name</returns>
        ''' <remarks></remarks>

        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(Name) Then
                Return String.Empty
            Else
                Return Name
            End If
        End Function

        Public Function GetTest(ByVal name As String) As Test
            Return Tests.FindByName(name)
        End Function
        Public Function GetTestID(ByVal name As String) As Integer
            If Tests.FindByName(name) IsNot Nothing Then
                Return Tests.FindByName(name).ID
            End If
            Return 0
        End Function
        Public Function GetTestsApplicableToTestStationType(ByVal fixtureTypeID As Integer) As TestCollection
            Return Tests.GetTestsApplicableToLocation(fixtureTypeID)
        End Function
        Public Overrides Function Validate() As Boolean
            Dim baseValid As Boolean = MyBase.Validate()
            Dim localValid As Boolean = True

            If Me.TestStageType = TestStageType.EnvironmentalStress And Me.TestID <= 0 Then
                localValid = False
                Me.Notifications.AddWithMessage("The type of test is environmental stress but this test stage is not associated with any environmental test.", NotificationType.Errors)
            End If

            Return baseValid AndAlso localValid
        End Function
    End Class

End Namespace