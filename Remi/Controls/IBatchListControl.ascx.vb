Imports REMI.BusinessEntities
Imports REMI.Bll
Imports Remi.Contracts

Partial Class Controls_IBatchListControl
    Inherits System.Web.UI.UserControl
    Private _Datasource As IDataSource
    Private _DatasourceID As String
    Private _allowPaging As Boolean
    Private _allowSorting As Boolean
    Private _autoGenerateEditButton As Boolean
    Private _pageSize As Int32

    Public Property Datasource() As IDataSource
        Get
            Return _Datasource
        End Get
        Set(ByVal value As IDataSource)
            _Datasource = value
            grdBatches.DataSource = Datasource
            grdBatches.DataBind()
            Helpers.MakeAccessable(grdBatches)
        End Set
    End Property

    Public Property AutoGenerateEditButton() As Boolean
        Get
            Return _autoGenerateEditButton
        End Get
        Set(value As Boolean)
            _autoGenerateEditButton = value
        End Set
    End Property

    Public Property PageSize() As Int32
        Get
            Return _pageSize
        End Get
        Set(value As Int32)
            _pageSize = value
            grdBatches.PageSize = _pageSize
        End Set
    End Property

    Public Property AllowPaging() As Boolean
        Get
            Return _allowPaging
        End Get
        Set(value As Boolean)
            _allowPaging = value
            grdBatches.AllowPaging = _allowPaging
        End Set
    End Property

    Public Property AllowSorting() As Boolean
        Get
            Return _allowSorting
        End Get
        Set(value As Boolean)
            _allowSorting = value
            grdBatches.AllowSorting = _allowSorting
        End Set
    End Property

    Public Property DatasourceID() As String
        Get
            Return _DatasourceID
        End Get
        Set(ByVal value As String)
            _DatasourceID = value
            grdBatches.DataSourceID = _DatasourceID
            Helpers.MakeAccessable(grdBatches)
        End Set
    End Property

    Public Sub SetBatches(ByVal bColl As IEnumerable(Of IBatch))
        grdBatches.DataSource = bColl
        grdBatches.DataBind()
        Helpers.MakeAccessable(grdBatches)
    End Sub
End Class