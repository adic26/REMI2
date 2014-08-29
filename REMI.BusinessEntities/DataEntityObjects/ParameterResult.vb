Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class ParameterResult
        Inherits Validation.ValidationBase
        Private _paramName As String
        Private _testName As String
        Private _param As String
        Private _lowerLimit As String
        Private _upperLimit As String
        Private _measuredValue As String
        Private _result As String
        Private _units As String
        Private _unitNumber As Integer
        Private _testStage As String
        Private _job As String

        Public Property Job() As String
            Get
                Return _job
            End Get
            Set(ByVal value As String)
                _job = value
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

        Public Property TestName() As String
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property
        Public Property ParameterName() As String
            Get
                Return _paramName
            End Get
            Set(ByVal value As String)
                _paramName = value
            End Set
        End Property
        Public Property Param() As String
            Get
                Return _param
            End Get
            Set(ByVal value As String)
                _param = value
            End Set
        End Property
        Public Property LowerLimit() As String
            Get
                Return _lowerLimit
            End Get
            Set(ByVal value As String)
                _lowerLimit = value
            End Set
        End Property

        Public Property UpperLimit() As String
            Get
                Return _upperLimit
            End Get
            Set(ByVal value As String)
                _upperLimit = value
            End Set
        End Property

        Public Property MeasuredValue() As String
            Get
                Return _measuredValue
            End Get
            Set(ByVal value As String)
                _measuredValue = value
            End Set
        End Property

        Public Property Result() As String
            Get
                Return _result
            End Get
            Set(ByVal value As String)
                _result = value
            End Set
        End Property

        Public Property Units() As String
            Get
                Return _units
            End Get
            Set(ByVal value As String)
                _units = value
            End Set
        End Property

        Public Property UnitNumber() As Integer
            Get
                Return _unitNumber
            End Get
            Set(ByVal value As Integer)
                _unitNumber = value
            End Set
        End Property

    End Class
End Namespace