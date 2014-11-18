Imports REMI.Core
Imports REMI.Validation
Imports System.Web
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' This class represents a Test Unit Object. This represents a device under test.
    ''' </summary>
    <Serializable()> _
    Public Class TestUnit
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _qraNumber As String
        Private _bsn As Long
        Private _batchUnitNumber As Integer
        Private _currentTestStage As TestStage
        Private _currentTestName As String
        Private _currentTestStageName As String
        Private _assignedTo As String
        Private _currentTrackingLog As DeviceTrackingLog
        Private _comments As String
        Private _testCenterID As Int32
        Private _NoBSN As Boolean
        Private _IMEI As String
#End Region

#Region "Constructor(s)"

        Public Sub New()
            _currentTrackingLog = New DeviceTrackingLog
            _currentTestStage = New TestStage
        End Sub
        Public Sub New(ByVal qraNumber As String, ByVal batchUnitNumber As Integer, ByVal testStageName As String, ByVal lastUser As String)
            _qraNumber = qraNumber
            _batchUnitNumber = batchUnitNumber
            _currentTestStageName = testStageName
            MyBase.LastUser = lastUser
        End Sub
#End Region

#Region "Public Properties"
        ''' <summary>
        ''' Gets or sets the Batch QRA number for this test unit. ie QRA-YY-BBBB
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        ''' <summary>
        ''' Returns the unit full qra number i.e QRA-YY-BBBB-UUU
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property FullQRANumber() As String
            Get
                Return String.Format("{0}-{1:d3}", _qraNumber, _batchUnitNumber)
            End Get
        End Property
        ''' <summary>
        ''' Gets or sets the user the test is assigned to.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(Key:="AssignedUserMaxStringLength", MaxLength:=255)> _
        Public Property AssignedTo() As String
            Get
                Return _assignedTo
            End Get
            Set(ByVal value As String)
                _assignedTo = value
            End Set
        End Property

        Public Property NoBSN() As Boolean
            Get
                Return _NoBSN
            End Get
            Set(value As Boolean)
                _NoBSN = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the current tracking log of the test unit.
        ''' </summary>
        <NotNullOrEmpty(key:="w54")> _
        Public Property CurrentLog() As DeviceTrackingLog
            Get
                Return _currentTrackingLog
            End Get
            Set(ByVal value As DeviceTrackingLog)
                _currentTrackingLog = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the comments associated with the test unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        ''' 
        <ValidStringLength(MaxLength:=1000, key:="w33")> _
        Public Property Comments() As String
            Get
                Return _comments
            End Get
            Set(ByVal value As String)
                _comments = value
            End Set
        End Property

        Public ReadOnly Property CanDelete() As Boolean
            Get
                Return Not (BSN > 0)
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the base station number for the test unit.
        ''' </summary>
        Public Property BSN() As Long
            Get
                Return _bsn
            End Get
            Set(ByVal value As Long)
                _bsn = value
            End Set
        End Property

        Public Property IMEI() As String
            Get
                Return _IMEI
            End Get
            Set(ByVal value As String)
                _IMEI = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the batch unit number for this test unit.
        ''' </summary>
        <ValidRangeAttribute(Max:=9999, Min:=1, Message:="The unit number must be between 1 and 9999.")> _
        Public Property BatchUnitNumber() As Integer
            Get
                Return _batchUnitNumber
            End Get
            Set(ByVal value As Integer)
                _batchUnitNumber = value
            End Set
        End Property

        Public Property TestCenterID() As Int32
            Get
                Return _testCenterID
            End Get
            Set(value As Int32)
                _testCenterID = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the current Test for the Test Unit. 
        ''' </summary>
        Public ReadOnly Property CurrentTest() As Test
            Get
                If Not String.IsNullOrEmpty(_currentTestName) Then
                    Return _currentTestStage.Tests.FindByName(_currentTestName)
                Else
                    Return Nothing
                End If
            End Get
        End Property
        ''' <summary>
        ''' Gets or sets the name of the Current Test this unit is performing.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property CurrentTestName() As String
            Get
                Return _currentTestName
            End Get
            Set(ByVal value As String)
                _currentTestName = value
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the current Test Stage for the Test Unit.
        ''' </summary>
        Public Property CurrentTestStage() As TestStage
            Get
                Return _currentTestStage
            End Get
            Set(ByVal value As TestStage)
                If value IsNot Nothing Then
                    'ensure the current test is not set before changing units test stage.
                    If CurrentTest Is Nothing Then
                        _currentTestStage = value
                    Else
                        Throw New Exception("Attempt to change test stage from " + _currentTestStage.Name + " to " + value.Name + " while unit is in test.")
                    End If
                End If
            End Set
        End Property
        Public ReadOnly Property CurrentTestStageName() As String
            Get
                If CurrentTestStage IsNot Nothing Then
                    Return Me.CurrentTestStage.Name
                Else
                    Return _currentTestStageName
                End If
            End Get
        End Property

        ''' <summary>
        ''' Gets the link to the mfg web page for this test unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property MfgWebLink() As String
            Get
                Return REMIWebLinks.GetMfgWebLink(BSN.ToString)
            End Get
        End Property
        ''' <summary>
        ''' Gets the link to the mfg web page for this test unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property UnitInfoLink() As String
            Get
                Return REMIWebLinks.GetUnitInfoLink(FullQRANumber)
            End Get
        End Property
        ''' <summary>
        ''' Gets the link to the batch info page
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property BatchInfoLink() As String
            Get
                Return REMIWebLinks.GetBatchInfoLink(QRANumber)
            End Get
        End Property
        ''' <summary>
        ''' Get the link that leads to the page where you can edit exceptions for this unit
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property EditExceptionsLink() As String
            Get
                Return REMIWebLinks.GetTestUnitExceptionsLink(FullQRANumber)
            End Get
        End Property

        ''' <summary>
        ''' Gets the current location name
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property CurrentLocationName() As String
            Get
                Return CurrentLog.TrackingLocationName
            End Get
        End Property
        ''' <summary>
        ''' Gets the current location prefix
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property CurrentLocationBarcodePrefix() As Integer
            Get

                Return CurrentLog.TrackingLocationBarcodePrefix

            End Get
        End Property
        ''' <summary>
        ''' Gets a string that indicates the best known location of the unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property LocationString() As String
            Get
                Return CurrentLog.TrackingLocationName
            End Get
        End Property
#End Region

#Region "Public Functions"
        ''' <summary>
        ''' Overrides the default tostring to return the test unit's number.
        ''' </summary>
        ''' <returns>The batch unit number</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(BatchUnitNumber.ToString) Then
                Return String.Empty
            Else
                Return BatchUnitNumber.ToString
            End If
        End Function

        ''' <summary>
        ''' Checks that the test unit current test name is null and the last scan direction was out, indicating that the unit is not currently in test.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function IsInTest() As Boolean
            Return (Not String.IsNullOrEmpty(_currentTestName))
        End Function
        ''' <summary>
        ''' Checks if the testunit is currently back at the requestor
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function IsBackAtRequestor() As Boolean
            Return (_currentTrackingLog IsNot Nothing) AndAlso (_currentTrackingLog.TrackingLocationName IsNot Nothing AndAlso _currentTrackingLog.TrackingLocationName.ToLower = "back to requestor")
        End Function
        ''' <summary>
        ''' indicates if the unit is saved to the database (has an id)
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Function IsSavedInREMI() As Boolean
            Return Me.ID > 0
        End Function

        ''' <summary>
        ''' Sets the assignedTo field tot he current user, sets the assignment status to assigned and sets the update user to the Current user.
        ''' </summary>
        ''' <remarks></remarks>
        Public Sub AssignCurrentUser(ByVal userName As String)
            LastUser = userName
            AssignedTo = userName
        End Sub
#End Region

    End Class

End Namespace