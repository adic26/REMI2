Imports Remi.BusinessEntities
Imports Remi.Bll
Imports Remi.Contracts

Partial Class Controls_BatchSelectControl
    Inherits System.Web.UI.UserControl

    Private _Datasource As IDataSource
    Private _DataSourceID As String
    Private _dt As DataTable
    Private _bColl As BatchCollection
    Private _BatchSelectControlMode As BatchSelectControlMode
    Private _emptyDataText As String
    Private _allowPaging As Boolean
    Private _allowSorting As Boolean
    Private _autoGenerateEditButton As Boolean
    Private _pageSize As Int32
    Private _isAdmin As Boolean

    Public Enum BatchSelectControlMode
        IncomingMode = 1
        ManageMode = 2
        BasicDisplay = 3
        All = 4
        BatchInfoDisplay = 5
        ProductInfoDisplay = 6
        TestingCompleteDisplay = 7
        HeldInfoDisplay = 8
        SearchInfoDisplay = 9
        OverviewDisplay = 10
        JobDisplay = 11
        TrackingLocationDisplay = 12
    End Enum

    Protected Enum GridviewColumNames
        selectionColumn = 0
        Id = 1
        QRA = 2
        Product = 3
        MechanicalTools = 4
        ProductType = 5
        AccessoryGroup = 6
        TestCenter = 7
        Department = 8
        ActiveTaskAssignee = 9
        NumberofUnits = 10
        NumberOfUnitsExpected = 11
        RequestPurpose = 12
        Job = 13
        Teststage = 14
        CPR = 15
        IsMQual = 16
        Priority = 17
        EstJobCompleletion = 18
        EstTSCompleletion = 19
        TSDue = 20
        ReportDue = 21
        Status = 22
        ReqID = 23
        HasUnitsRequireingReturnToRequestor = 24
        Comments = 25
        WILocation = 26
        TRSLink = 27
        RelabResultLink = 28
        BatchInfoLink = 29
        Move = 30
    End Enum

    Public Sub New()
        DisplayMode = BatchSelectControlMode.BasicDisplay
        AutoGenerateEditButton = False
        EmptyDataText = String.Empty
    End Sub

    Public Property EmptyDataText() As String
        Get
            Return _emptyDataText
        End Get
        Set(ByVal value As String)
            _emptyDataText = value
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

    Public Property DisplayMode() As BatchSelectControlMode
        Get
            Return _BatchSelectControlMode
        End Get
        Set(ByVal value As BatchSelectControlMode)
            _BatchSelectControlMode = value
        End Set
    End Property

    Public ReadOnly Property GetGridView() As GridView
        Get
            Return grdBatches
        End Get
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

    Public Property PageSize() As Int32
        Get
            Return _pageSize
        End Get
        Set(value As Int32)
            _pageSize = value
            grdBatches.PageSize = _pageSize
        End Set
    End Property

    Public Property DataSourceID() As String
        Get
            Return _DataSourceID
        End Get
        Set(value As String)
            _isAdmin = UserManager.GetCurrentUser.IsAdmin
            _DataSourceID = value
            grdBatches.EmptyDataText = EmptyDataText
            grdBatches.DataSourceID = _DataSourceID
            grdBatches.AutoGenerateEditButton = _autoGenerateEditButton
            SetColumns()
        End Set
    End Property

    Public Property DTable() As DataTable
        Get
            Return _dt
        End Get
        Set(value As DataTable)
            _dt = value
        End Set
    End Property

    Public Property BColl() As BatchCollection
        Get
            Return _bColl
        End Get
        Set(value As BatchCollection)
            _bColl = value
        End Set
    End Property

    Public Property Datasource() As IDataSource
        Get
            Return _Datasource
        End Get
        Set(ByVal value As IDataSource)
            _Datasource = value
            _isAdmin = UserManager.GetCurrentUser.IsAdmin
            grdBatches.EmptyDataText = EmptyDataText
            grdBatches.DataSource = Datasource
            grdBatches.AutoGenerateEditButton = _autoGenerateEditButton
            grdBatches.DataBind()
            SetColumns()
        End Set
    End Property

    Protected Sub SetColumns()
        Select Case DisplayMode
            Case BatchSelectControlMode.BasicDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = False
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = False
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.ManageMode
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = True
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = False
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.IncomingMode
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = False
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.All
                grdBatches.Columns(GridviewColumNames.Id).Visible = True
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = True
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = True
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = True
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = True
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = True
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.BatchInfoDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = False
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = True
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = True
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.ProductInfoDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = False
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.TestingCompleteDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = False
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = False
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = False
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = False
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = True
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.ProductType).Visible = False
                grdBatches.Columns(GridviewColumNames.AccessoryGroup).Visible = False
                grdBatches.Columns(GridviewColumNames.CPR).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = True
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.HeldInfoDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = True
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.SearchInfoDisplay
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.OverviewDisplay
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.Priority).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = True
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = True
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = True
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = True
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = True
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = True
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = False
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = True
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.JobDisplay
                grdBatches.Columns(GridviewColumNames.Job).Visible = False
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.Priority).Visible = False
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.ProductType).Visible = False
                grdBatches.Columns(GridviewColumNames.AccessoryGroup).Visible = False
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = False
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = False
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = False
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = False
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.Comments).Visible = False
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = True
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
            Case BatchSelectControlMode.TrackingLocationDisplay
                grdBatches.Columns(GridviewColumNames.QRA).Visible = True
                grdBatches.Columns(GridviewColumNames.Product).Visible = True
                grdBatches.Columns(GridviewColumNames.NumberofUnits).Visible = True
                grdBatches.Columns(GridviewColumNames.Job).Visible = True
                grdBatches.Columns(GridviewColumNames.RequestPurpose).Visible = True
                grdBatches.Columns(GridviewColumNames.Status).Visible = True
                grdBatches.Columns(GridviewColumNames.Comments).Visible = True
                grdBatches.Columns(GridviewColumNames.Priority).Visible = False
                grdBatches.Columns(GridviewColumNames.ProductType).Visible = False
                grdBatches.Columns(GridviewColumNames.AccessoryGroup).Visible = False
                grdBatches.Columns(GridviewColumNames.ReportDue).Visible = False
                grdBatches.Columns(GridviewColumNames.Teststage).Visible = False
                grdBatches.Columns(GridviewColumNames.IsMQual).Visible = False
                grdBatches.Columns(GridviewColumNames.ActiveTaskAssignee).Visible = False
                grdBatches.Columns(GridviewColumNames.TRSLink).Visible = False
                grdBatches.Columns(GridviewColumNames.RelabResultLink).Visible = False
                grdBatches.Columns(GridviewColumNames.TSDue).Visible = False
                grdBatches.Columns(GridviewColumNames.EstTSCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.EstJobCompleletion).Visible = False
                grdBatches.Columns(GridviewColumNames.NumberOfUnitsExpected).Visible = False
                grdBatches.Columns(GridviewColumNames.ReqID).Visible = False
                grdBatches.Columns(GridviewColumNames.TestCenter).Visible = False
                grdBatches.Columns(GridviewColumNames.Department).Visible = True
                grdBatches.Columns(GridviewColumNames.WILocation).Visible = False
                grdBatches.Columns(GridviewColumNames.selectionColumn).Visible = False
                grdBatches.Columns(GridviewColumNames.Id).Visible = False
                grdBatches.Columns(GridviewColumNames.HasUnitsRequireingReturnToRequestor).Visible = False
                grdBatches.Columns(GridviewColumNames.BatchInfoLink).Visible = False
                grdBatches.Columns(GridviewColumNames.MechanicalTools).Visible = True
                grdBatches.Columns(GridviewColumNames.CPR).Visible = False
                grdBatches.Columns(GridviewColumNames.Move).Visible = False
        End Select

        If (grdBatches.Columns(GridviewColumNames.Move).Visible And Not (_isAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.IsProjectManager Or UserManager.GetCurrentUser.IsLabTechOpsManager Or UserManager.GetCurrentUser.IsLabTestCoordinator)) Then
            grdBatches.Columns(GridviewColumNames.Move).Visible = False
        End If
    End Sub

    Public Sub SetBatches(ByVal dt As DataTable)
        _dt = dt
        _isAdmin = UserManager.GetCurrentUser.IsAdmin
        grdBatches.EmptyDataText = EmptyDataText
        grdBatches.AutoGenerateEditButton = _autoGenerateEditButton
        grdBatches.DataSource = dt
        grdBatches.DataBind()
        SetColumns()
    End Sub

    Public Sub SetBatches(ByVal bColl As BatchCollection)
        _bColl = bColl
        _isAdmin = UserManager.GetCurrentUser.IsAdmin
        grdBatches.EmptyDataText = EmptyDataText
        grdBatches.AutoGenerateEditButton = _autoGenerateEditButton
        grdBatches.DataSource = bColl
        grdBatches.DataBind()
        SetColumns()
    End Sub

    Public Sub SetBatches(ByVal bColl As List(Of IBatch))
        grdBatches.EmptyDataText = EmptyDataText
        _isAdmin = UserManager.GetCurrentUser.IsAdmin
        grdBatches.AutoGenerateEditButton = _autoGenerateEditButton
        grdBatches.DataSource = bColl
        grdBatches.DataBind()
        SetColumns()
    End Sub

    Public ReadOnly Property SelectedBatches() As BatchCollection
        Get
            Dim batchcoll As New BatchCollection
            If grdBatches.Rows IsNot Nothing Then
                For Each gr As GridViewRow In grdBatches.Rows
                    If gr.RowType = DataControlRowType.DataRow Then
                        Dim chkRow As CheckBox = gr.FindControl("chkSelect")
                        If chkRow.Checked Then
                            batchcoll.Add(BatchManager.GetItem(grdBatches.DataKeys.Item(gr.RowIndex).Value))
                        End If
                    End If
                Next
            End If
            Return batchcoll
        End Get
    End Property

    Protected Sub chkSelect_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim chkSelect As CheckBox = DirectCast(sender, CheckBox)
        If Not chkSelect.Checked Then
            Dim chkAll As CheckBox = DirectCast(grdBatches.HeaderRow.FindControl("chkAll"), CheckBox)
            chkAll.Checked = False
        End If
    End Sub

    Protected Sub chkAll_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim chkAll As CheckBox = DirectCast(grdBatches.HeaderRow.FindControl("chkAll"), CheckBox)
        If chkAll.Checked Then
            For Each gvRow As GridViewRow In grdBatches.Rows
                Dim chkSel As CheckBox = DirectCast(gvRow.FindControl("chkSelect"), CheckBox)
                chkSel.Checked = True
            Next
        Else
            For Each gvRow As GridViewRow In grdBatches.Rows
                Dim chkSel As CheckBox = DirectCast(gvRow.FindControl("chkSelect"), CheckBox)
                chkSel.Checked = False
            Next
        End If
    End Sub

    Protected Sub UpdateGV() Handles grdBatches.PreRender
        Helpers.MakeAccessable(grdBatches)
    End Sub

    Protected Overridable Sub grdBatches_RowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        If (REMI.Bll.UserManager.GetCurrentUser().HasTaskAssignmentAuthority) Then
            grdBatches.EditIndex = e.NewEditIndex
            grdBatches.DataBind()

            Dim txtActiveTaskAssignee As TextBox = grdBatches.Rows(e.NewEditIndex).FindControl("txtActiveTaskAssignee")
            Dim lblActiveTaskAssignee As Label = grdBatches.Rows(e.NewEditIndex).FindControl("lblActiveTaskAssignee")
            Dim chkBatch As CheckBox = grdBatches.Rows(e.NewEditIndex).FindControl("chkBatch")

            chkBatch.Visible = True
            txtActiveTaskAssignee.Visible = True
            lblActiveTaskAssignee.Visible = False
        End If
    End Sub

    Protected Overridable Sub grdBatches_RowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdBatches.EditIndex = -1
        grdBatches.DataBind()
    End Sub

    Protected Overridable Sub grdBatches_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim chkBatch As CheckBox = grdBatches.Rows(e.RowIndex).FindControl("chkBatch")
        Dim txtActiveTaskAssignee As TextBox = grdBatches.Rows(e.RowIndex).FindControl("txtActiveTaskAssignee")
        Dim lblTestStageName As Label = grdBatches.Rows(e.RowIndex).FindControl("lblTestStageName")
        Dim hypQRANumber As HyperLink = grdBatches.Rows(e.RowIndex).FindControl("hypQRANumber")
        Dim lblJobName As Label = grdBatches.Rows(e.RowIndex).FindControl("lblJobName")
        Dim lblActiveTaskAssignee As Label = grdBatches.Rows(e.RowIndex).FindControl("lblActiveTaskAssignee")
        Dim id As Int32 = 0
        Dim checked As Boolean = True

        If (Not Request.Form(chkBatch.UniqueID) = "on") Then
            checked = False
        End If

        If (Not checked) Then
            Int32.TryParse(TestStageManager.GetTestStage(lblTestStageName.Text, lblJobName.Text).ID, id)
        End If

        TestStageManager.RemoveTaskAssignment(hypQRANumber.Text, id)
        TestStageManager.AddUpdateTaskAssignment(hypQRANumber.Text, id, Request.Form(txtActiveTaskAssignee.UniqueID))

        lblActiveTaskAssignee.Text = Request.Form(txtActiveTaskAssignee.UniqueID)

        If (grdBatches.DataSource.GetType.Name = "BatchCollection") Then
            Dim dt As List(Of IBatch) = DirectCast(grdBatches.DataSource, List(Of IBatch))
            dt.Find(Function(c) c.QRANumber = hypQRANumber.Text).ActiveTaskAssignee = Request.Form(txtActiveTaskAssignee.UniqueID)

            grdBatches.EditIndex = -1
            grdBatches.DataSource = dt
            grdBatches.DataBind()
        End If
    End Sub

    Protected Sub grdBatches_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdBatches.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim statusColumnID As Int32 = GridviewColumNames.Status
            Dim rtrColumnID As Int32 = GridviewColumNames.HasUnitsRequireingReturnToRequestor

            If (Me.AutoGenerateEditButton = True) Then
                statusColumnID += 1
                rtrColumnID += 1

                e.Row.Cells(0).Enabled = UserManager.GetCurrentUser.HasEditItemAuthority(DirectCast(e.Row.DataItem, REMI.BusinessEntities.Batch).ProductGroup, DirectCast(e.Row.DataItem, REMI.BusinessEntities.Batch).DepartmentID)

                Dim btnUp As LinkButton = DirectCast(e.Row.FindControl("btnUp"), LinkButton)
                Dim btnDown As LinkButton = DirectCast(e.Row.FindControl("btnDown"), LinkButton)

                btnUp.Enabled = e.Row.Cells(0).Enabled
                btnDown.Enabled = e.Row.Cells(0).Enabled
            End If

            If (BatchSelectControlMode.TestingCompleteDisplay) Then
                Dim lblRTR As Label = DirectCast(e.Row.FindControl("lblRTR"), Label)
                If (lblRTR.Text = "Yes") Then
                    e.Row.Cells(rtrColumnID).CssClass = "Quarantined"
                End If
            End If

            Select Case e.Row.Cells(statusColumnID).Text
                Case BatchStatus.InProgress.ToString
                    e.Row.Cells(statusColumnID).CssClass = "Pass"
                Case BatchStatus.Held.ToString
                    e.Row.Cells(statusColumnID).CssClass = "Fail"
                Case BatchStatus.Quarantined.ToString
                    e.Row.Cells(statusColumnID).CssClass = "NeedsRetest"
            End Select

            Dim lblJobName As Label = DirectCast(e.Row.FindControl("lblJobName"), Label)
            Dim hypBatchJobLink As HyperLink = DirectCast(e.Row.FindControl("hypBatchJobLink"), HyperLink)

            If (_isAdmin) Then
                lblJobName.Visible = False
                hypBatchJobLink.Visible = True
            Else
                lblJobName.Visible = True
                hypBatchJobLink.Visible = False
            End If
        End If
    End Sub

    Protected Sub grdBatches_RowDataCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Dim index As Integer = 0

        Select Case e.CommandName
            Case "Up"
                index = Convert.ToInt32(e.CommandArgument)

                If (index - 1 > -1 And grdBatches.DataSource.GetType.Name = "BatchCollection") Then
                    Dim list As List(Of IBatch) = DirectCast(grdBatches.DataSource, List(Of IBatch))
                    Dim item As IBatch = list(index)
                    Dim item2 As IBatch = list(index - 1)

                    list.RemoveAt(index)
                    list.Insert(index - 1, item)

                    grdBatches.DataSource = list
                    grdBatches.DataBind()

                    Dim instance = New Remi.Dal.Entities().Instance()
                    Dim batch As Remi.Entities.Batch = (From b In instance.Batches Where b.QRANumber = item.QRANumber).FirstOrDefault()
                    batch.Order = list.IndexOf(item) + 1
                    batch.LastUser = UserManager.GetCurrentValidUserLDAPName

                    Dim batch2 As Remi.Entities.Batch = (From b In instance.Batches Where b.QRANumber = item2.QRANumber).FirstOrDefault()
                    batch2.Order = list.IndexOf(item2) + 1
                    batch.LastUser = UserManager.GetCurrentValidUserLDAPName

                    instance.SaveChanges()
                End If
            Case "Down"
                index = Convert.ToInt32(e.CommandArgument)

                If (index + 1 < grdBatches.Rows.Count And grdBatches.DataSource.GetType.Name = "BatchCollection") Then
                    Dim list As List(Of IBatch) = DirectCast(grdBatches.DataSource, List(Of IBatch))
                    Dim item As IBatch = list(index)
                    Dim item2 As IBatch = list(index + 1)

                    list.RemoveAt(index)
                    list.Insert(index + 1, item)

                    grdBatches.DataSource = list
                    grdBatches.DataBind()

                    Dim instance = New Remi.Dal.Entities().Instance()
                    Dim batch As Remi.Entities.Batch = (From b In instance.Batches Where b.QRANumber = item.QRANumber).FirstOrDefault()
                    batch.Order = list.IndexOf(item) + 1
                    batch.LastUser = UserManager.GetCurrentValidUserLDAPName

                    Dim batch2 As Remi.Entities.Batch = (From b In instance.Batches Where b.QRANumber = item2.QRANumber).FirstOrDefault()
                    batch2.Order = list.IndexOf(item2) + 1
                    batch.LastUser = UserManager.GetCurrentValidUserLDAPName

                    instance.SaveChanges()
                End If
        End Select
    End Sub
End Class