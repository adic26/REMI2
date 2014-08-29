Namespace REMI.BusinessEntities
    Public Class UserSearch
        Private _byPass As Int32
        Private _productID As Int32
        Private _trainingID As Int32
        Private _trainingLevelID As Int32
        Private _testCenterID As Int32
        Private _userID As Int32

        Public Property ByPass() As Int32
            Get
                Return _byPass
            End Get
            Set(value As Int32)
                _byPass = value
            End Set
        End Property

        Public Property UserID() As Int32
            Get
                Return _userID
            End Get
            Set(value As Int32)
                _userID = value
            End Set
        End Property

        Public Property ProductID() As Int32
            Get
                Return _productID
            End Get
            Set(value As Int32)
                _productID = value
            End Set
        End Property

        Public Property TrainingID() As Int32
            Get
                Return _trainingID
            End Get
            Set(value As Int32)
                _trainingID = value
            End Set
        End Property

        Public Property TrainingLevelID() As Int32
            Get
                Return _trainingLevelID
            End Get
            Set(value As Int32)
                _trainingLevelID = value
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
    End Class
End Namespace