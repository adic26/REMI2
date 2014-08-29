Namespace REMI.BusinessEntities
    Public Class InventoryReportData

        Private _totalBatches As Integer
        Private _productLocationReport As DataTable
        Private _AverageUnitsInBatch As Integer
        Private _totalUnits As Integer
        Private _productDistribution As DataTable

        Public Sub New()
            _productLocationReport = New DataTable("ProductLocationReport")
            _productDistribution = New DataTable("ProductDistribution")
            _productDistribution.Columns.Add("ProductGroup")
            _productDistribution.Columns.Add("TotalBatches")
            _productDistribution.Columns.Add("TotalTestUnits")

        End Sub
        Public Sub AddRowToProductDistribution(ByVal productgroupname As String, ByVal totalBatches As Integer, ByVal totalTestUnits As Integer)
            Dim r As DataRow = _productDistribution.NewRow()
            r("ProductGroup") = productgroupname
            r("TotalBatches") = totalBatches
            r("TotalTestUnits") = totalTestUnits
            _productDistribution.Rows.Add(r)
        End Sub
        Public Property TotalBatches() As Integer
            Get
                Return _totalBatches
            End Get
            Set(ByVal value As Integer)
                _totalBatches = value
            End Set
        End Property

        Public Property TotalUnits() As Integer
            Get
                Return _totalUnits
            End Get
            Set(ByVal value As Integer)
                _totalUnits = value
            End Set
        End Property

        Public Property AverageUnitsInBatch() As Integer
            Get
                Return _AverageUnitsInBatch
            End Get
            Set(ByVal value As Integer)
                _AverageUnitsInBatch = value
            End Set
        End Property


        Public ReadOnly Property ProductDistribution() As DataTable
            Get
                Return _productDistribution
            End Get

        End Property


        Public ReadOnly Property ProductLocationReport() As DataTable
            Get
                Return _productLocationReport
            End Get

        End Property

    End Class
End Namespace