Imports Remi.BusinessEntities
Imports Remi.Bll
Imports Remi.Contracts

Partial Class RequestSetup
    Inherits System.Web.UI.UserControl

    Public Sub New()
    End Sub

    Public Property TestStageType() As Int32
        Get
            Dim id As Int32
            Int32.TryParse(hdnTestStageType.Value, id)
            Return id
        End Get
        Set(value As Int32)
            hdnTestStageType.Value = value
        End Set
    End Property

    Public Property QRANumber() As String
        Get
            Return hdnQRANumber.Value
        End Get
        Set(ByVal value As String)
            hdnQRANumber.Value = value
        End Set
    End Property

    Public Property BatchID() As Int32
        Get
            Dim id As Int32
            Int32.TryParse(hdnBatchID.Value, id)
            Return id
        End Get
        Set(ByVal value As Int32)
            hdnBatchID.Value = value
        End Set
    End Property

    Public Property JobName() As String
        Get
            Return hdnJobName.Value
        End Get
        Set(ByVal value As String)
            hdnJobName.Value = value
        End Set
    End Property

    Public Property JobID() As Int32
        Get
            Dim id As Int32
            Int32.TryParse(hdnJobID.Value, id)
            Return id
        End Get
        Set(ByVal value As Int32)
            hdnJobID.Value = value
        End Set
    End Property

    Public Property ProductName() As String
        Get
            Return hdnProductName.Value
        End Get
        Set(ByVal value As String)
            hdnProductName.Value = value
        End Set
    End Property

    Public Property ProductID() As Int32
        Get
            Dim id As Int32
            Int32.TryParse(hdnProductID.Value, id)
            Return id
        End Get
        Set(ByVal value As Int32)
            hdnProductID.Value = value
        End Set
    End Property

    Public Property IsProjectManager As Boolean
        Get
            Dim val As Boolean
            Boolean.TryParse(hdnIsProjectManager.Value, val)
            Return val
        End Get
        Set(value As Boolean)
            hdnIsProjectManager.Value = value
        End Set
    End Property

    Public Property IsAdmin As Boolean
        Get
            Dim val As Boolean
            Boolean.TryParse(hdnIsAdmin.Value, val)
            Return val
        End Get
        Set(value As Boolean)
            hdnIsAdmin.Value = value
        End Set
    End Property

    Public Property HasEditItemAuthority As Boolean
        Get
            Dim val As Boolean
            Boolean.TryParse(hdnHasEditItemAuthority.Value, val)
            Return val
        End Get
        Set(value As Boolean)
            hdnHasEditItemAuthority.Value = value
        End Set
    End Property

    Public Overrides Sub DataBind()
        ViewState.Clear()
        ClearChildViewState()

        notMain.Clear()
        ddlRequestSetupOptions.Items.Clear()
        chklSaveOptions.Items.Clear()

        ddlRequestSetupOptions.Items.Add(New ListItem("Select...", -1))
        ddlRequestSetupOptions.Items.Add(New ListItem("Blank", 0))

        If (Not String.IsNullOrEmpty(QRANumber)) Then
            ddlRequestSetupOptions.Items.Add(New ListItem(QRANumber, BatchID))

            If (HasEditItemAuthority) Then
                Dim li As ListItem = New ListItem(QRANumber, 1, True)
                chklSaveOptions.Items.Add(li)
                chklSaveOptions.SelectedValue = li.Value
            End If
        End If

        If (Not String.IsNullOrEmpty(ProductName)) Then
            ddlRequestSetupOptions.Items.Add(New ListItem(ProductName, ProductID))

            If (IsProjectManager) Then
                chklSaveOptions.Items.Add(New ListItem(ProductName, 2, True))
            End If
        End If

        If (Not String.IsNullOrEmpty(JobName)) Then
            ddlRequestSetupOptions.Items.Add(New ListItem(JobName, JobID))

            If (IsAdmin) Then
                Dim li As ListItem = New ListItem(JobName, 3, True)
                chklSaveOptions.Items.Add(li)

                If (String.IsNullOrEmpty(QRANumber)) Then
                    chklSaveOptions.SelectedValue = li.Value
                End If
            End If
        End If

        If (HasEditItemAuthority Or IsAdmin Or IsProjectManager) Then
            btnSave.Visible = True
        End If

        AddTopNodes(RequestManager.GetRequestSetupInfo(ProductID, JobID, BatchID, TestStageType, 0))

        MyBase.DataBind()
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not IsPostBack) Then
            Me.DataBind()
        End If
    End Sub

    Protected Sub ddlRequestSetupOptions_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlRequestSetupOptions.SelectedIndexChanged
        If (ddlRequestSetupOptions.SelectedItem.Text = "Blank") Then
            AddTopNodes(RequestManager.GetRequestSetupInfo(0, JobID, 0, TestStageType, 1))
        ElseIf (ddlRequestSetupOptions.SelectedValue = ProductID) Then
            AddTopNodes(RequestManager.GetRequestSetupInfo(ProductID, JobID, 0, TestStageType, 0))
        ElseIf (ddlRequestSetupOptions.SelectedValue = JobID) Then
            AddTopNodes(RequestManager.GetRequestSetupInfo(0, JobID, 0, TestStageType, 0))
        ElseIf (ddlRequestSetupOptions.SelectedValue = 0) Then
            AddTopNodes(RequestManager.GetRequestSetupInfo(0, JobID, 0, TestStageType, 1))
        Else
            AddTopNodes(RequestManager.GetRequestSetupInfo(ProductID, JobID, BatchID, TestStageType, 0))
        End If
    End Sub

    Private Sub AddTopNodes(ByVal treeViewData As DataTable)
        tvRequest.Nodes.Clear()

        Dim view As DataView = New DataView(treeViewData)
        Dim lastStageName As String = String.Empty
        Dim row As DataRowView

        For Each row In view
            If Not lastStageName.Equals(row("TestStageName").ToString()) Then
                Dim NewNode As TreeNode = New TreeNode(row("TestStageName").ToString(), row("TestStageID").ToString())
                NewNode.ShowCheckBox = False
                NewNode.SelectAction = TreeNodeSelectAction.Expand

                tvRequest.Nodes.Add(NewNode)
                AddChildNodes(treeViewData, NewNode)
                NewNode.CollapseAll()
            End If

            lastStageName = row("TestStageName").ToString()
        Next
    End Sub

    Private Sub AddChildNodes(ByVal treeViewData As DataTable, ByVal parentTreeViewNode As TreeNode)
        Dim view As DataView = New DataView(treeViewData)
        view.RowFilter = "TestStageID=" + parentTreeViewNode.Value
        Dim row As DataRowView

        For Each row In view
            Dim NewNode As TreeNode = New TreeNode(row("TestName").ToString(), row("TestID").ToString())
            NewNode.ShowCheckBox = True

            Dim isSelected As Boolean
            Boolean.TryParse(row("Selected"), isSelected)

            NewNode.Checked = isSelected
            NewNode.SelectAction = TreeNodeSelectAction.Expand

            parentTreeViewNode.ChildNodes.Add(NewNode)
            AddChildNodes(treeViewData, NewNode)
        Next
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSave.Click
        If (HasEditItemAuthority Or IsAdmin Or IsProjectManager) Then
            If (tvRequest.Nodes.Count > 0) Then
                Dim saveOptions As List(Of Int32) = (From item In chklSaveOptions.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()

                notMain.Notifications.Add(RequestManager.SaveRequestSetup(hdnProductID.Value, hdnJobID.Value, hdnBatchID.Value, saveOptions, tvRequest.CheckedNodes, TestStageType))
                AddTopNodes(RequestManager.GetRequestSetupInfo(ProductID, JobID, BatchID, TestStageType, 0))
            End If
        End If
    End Sub
End Class
