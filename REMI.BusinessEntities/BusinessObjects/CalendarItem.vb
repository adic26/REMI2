Namespace REMI.BusinessEntities
    Public Class CalendarItem
        Private _text As String
        Private _startTime As DateTime
        Private _endTime As DateTime
        Private _fullBarcodeNumber As String

        Public Property FullBarcodeNumber() As String
            Get
                Return _fullBarcodeNumber
            End Get
            Set(ByVal value As String)
                _fullBarcodeNumber = value
            End Set
        End Property

        Public Property StartTime() As DateTime
            Get
                Return _startTime
            End Get
            Set(ByVal value As DateTime)
                _startTime = value
            End Set
        End Property

        Public Property EndTime() As DateTime
            Get
                Return _endTime
            End Get
            Set(ByVal value As DateTime)
                _endTime = value
            End Set
        End Property

        Public Property Text() As String
            Get
                Return _text
            End Get
            Set(ByVal value As String)
                _text = value
            End Set
        End Property
    End Class
End Namespace