Imports REMI.Contracts

Namespace REMI.BusinessEntities
    Public Class ChamberTestUnit
        Implements IComparable(Of ChamberTestUnit)

        Private _assignedTo As String
        Private _QRAnumber As String
        Private _testStage As String
        Private _location As String
        Private _inTime As DateTime
        Private _testLength As Double
        Private _totalTestTime As Double
        Private _batchInfoLink As String
        Private _job As String
        Private _unitnumber As Integer
        Private _status As TrackingStatus
        Private _productGroupName As String
        Private _getExpectedCompletionDateTime As String

        Public Property GetExpectedCompletionDateTime() As String
            Get
                Return _getExpectedCompletionDateTime
            End Get
            Set(value As String)
                _getExpectedCompletionDateTime = value
            End Set
        End Property

        Public Property ProductGroupName() As String
            Get
                Return _productGroupName
            End Get
            Set(value As String)
                _productGroupName = value
            End Set
        End Property

        Public Property Job() As String
            Get
                Return _job
            End Get
            Set(ByVal value As String)
                _job = value
            End Set
        End Property

        Public Function CompareTo(ByVal other As ChamberTestUnit) As Integer Implements System.IComparable(Of ChamberTestUnit).CompareTo
            Dim timediff As Integer = Convert.ToInt32(Me.RemainingTestTime - other.RemainingTestTime)
            'if the times are the same then we want to organise the units by their batch
            If timediff = 0 Then
                Dim batchDiff As Integer = String.Compare(Me.QRAnumber, other.QRAnumber)
                If batchDiff = 0 Then
                    'stil the same? then order by the unit numbers in the batch
                    Return Me.UnitNumber - other.UnitNumber
                End If
                Return batchDiff
            End If
            Return timediff
        End Function

        Public Property Status() As TrackingStatus
            Get
                Return _status
            End Get
            Set(value As TrackingStatus)
                _status = value
            End Set
        End Property

        Public Property QRAnumber() As String
            Get
                Return _QRAnumber
            End Get
            Set(ByVal value As String)
                _QRAnumber = value
            End Set
        End Property

        Public Property UnitNumber() As Integer
            Get
                Return _unitnumber
            End Get
            Set(ByVal value As Integer)
                _unitnumber = value
            End Set
        End Property

        Public Property Assignedto() As String
            Get
                Return _assignedTo
            End Get
            Set(ByVal value As String)
                _assignedTo = value
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

        Public Property Location() As String
            Get
                Return _location
            End Get
            Set(ByVal value As String)
                _location = value
            End Set
        End Property


        Public Property InTime() As DateTime
            Get
                Return _inTime
            End Get
            Set(ByVal value As DateTime)
                _inTime = value
            End Set
        End Property

        Public Property TestLength() As Double
            Get
                Return _testLength
            End Get
            Set(ByVal value As Double)
                _testLength = value
            End Set
        End Property

        Public Property TotalTestTime() As Double
            Get
                Return _totalTestTime
            End Get
            Set(ByVal value As Double)
                _totalTestTime = value
            End Set
        End Property

        Public ReadOnly Property RemainingTestTime() As Double
            Get
                Return Me.TestLength - Me.TotalTestTime
            End Get
        End Property

        Public ReadOnly Property CanBeRemovedAt() As String
            Get
                If Me.RemainingTestTime > 0 Then
                    Return String.Format("{0:g}", DateTime.UtcNow.AddHours(RemainingTestTime))
                Else
                    Return "Now!"
                End If
            End Get
        End Property

        Public Property BatchInfoLink() As String
            Get
                Return _batchInfoLink
            End Get
            Set(ByVal value As String)
                _batchInfoLink = value
            End Set
        End Property
    End Class
End Namespace