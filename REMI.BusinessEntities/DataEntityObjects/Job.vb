Imports REMI.Validation
Imports System.Web.UI.WebControls
Imports System.Xml
Imports REMI.Contracts

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class Job
        Inherits LoggedItemBase

#Region "Private variables"
        Private _isOperationsTest As Boolean
        Private _name As String
        Private _testStages As TestStageCollection
        Private _wiLocation As String
        Private _procedureLocation As String
        Private _comment As String
        Private _isTechOperationsTest As Boolean
        Private _isMechanicalTest As Boolean
        Private _isActive As Boolean
        Private _noBSN As Boolean
        Private _continueOnFailures As Boolean
#End Region

#Region "Constructors"
        Public Sub New()
            _testStages = New TestStageCollection
        End Sub
        Public Sub New(ByVal jobName As String)
            _name = jobName
            _testStages = New TestStageCollection
        End Sub
#End Region

#Region "Public Properties"
        ''' <summary>
        ''' Gets and sets the name of the job.
        ''' </summary>
        ''' <value>Job Name</value>
        ''' <returns>Job Name</returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(key:="w31")> _
            <ValidStringLength(MaxLength:=400, key:="w32")> _
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the location of the work instruction for this job.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(MaxLength:=400, key:="w23")> _
        Public Property WILocation() As String
            Get
                Return _wiLocation
            End Get
            Set(ByVal value As String)
                _wiLocation = value
            End Set
        End Property

        <ValidStringLength(MaxLength:=400, key:="w80")> _
        Public Property ProcedureLocation() As String
            Get
                Return _procedureLocation
            End Get
            Set(ByVal value As String)
                _procedureLocation = value
            End Set
        End Property

        Public Property IsTechOperationsTest() As Boolean
            Get
                Return _isTechOperationsTest
            End Get
            Set(ByVal value As Boolean)
                _isTechOperationsTest = value
            End Set
        End Property

        Public Property IsMechanicalTest() As Boolean
            Get
                Return _isMechanicalTest
            End Get
            Set(ByVal value As Boolean)
                _isMechanicalTest = value
            End Set
        End Property

        Public Property IsActive() As Boolean
            Get
                Return _isActive
            End Get
            Set(ByVal value As Boolean)
                _isActive = value
            End Set
        End Property

        Public Property ContinueOnFailures() As Boolean
            Get
                Return _continueOnFailures
            End Get
            Set(ByVal value As Boolean)
                _continueOnFailures = value
            End Set
        End Property

        Public Property NoBSN() As Boolean
            Get
                Return _noBSN
            End Get
            Set(ByVal value As Boolean)
                _noBSN = value
            End Set
        End Property

        Public Property IsOperationsTest() As Boolean
            Get
                Return _isOperationsTest
            End Get
            Set(ByVal value As Boolean)
                _isOperationsTest = value
            End Set
        End Property

        ''' <summary>
        ''' Gets and sets the collection of associated Test Stages for the Job.
        ''' </summary>
        ''' <value>TestStage Collection</value>
        ''' <returns>TestStage Collection</returns>
        ''' <remarks></remarks>
        Public Property TestStages() As TestStageCollection
            Get
                Return _testStages
            End Get
            Set(ByVal value As TestStageCollection)
                _testStages = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the comments for the job
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(MaxLength:=1000, key:="w28")> _
        Public Property Comment() As String
            Get
                Return _comment
            End Get
            Set(ByVal value As String)
                _comment = value
            End Set
        End Property

        ''' <summary>
        ''' Returns a sum of all the durations of the test stages 'underneath' this job.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property Duration() As TimeSpan
            Get
                Return TestStages.Duration
            End Get
        End Property
#End Region

#Region "Public Functions"

        Public Function GetTestStage(ByVal testStageName As String) As TestStage
            Return TestStages.FindByName(testStageName)
        End Function
        Public Function GetParametricTests() As TestCollection
            Dim paraTS As TestStage = (From ts In Me.TestStages Where ts.IsArchived = False And ts.TestStageType.Equals(TestStageType.Parametric) Select ts).FirstOrDefault
            If paraTS IsNot Nothing Then
                Return paraTS.Tests
            End If
            Return (New TestCollection)
        End Function

        ''' <summary>
        ''' Overrides the default to string and returns the name of the test
        ''' </summary>
        ''' <returns>The job name</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(Name) Then
                Return String.Empty
            Else
                Return Name
            End If
        End Function
#End Region
    End Class

End Namespace