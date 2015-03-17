Imports REMI.Bll
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Core

Partial Class ScanForInfo_ProductGroup
    Inherits System.Web.UI.Page

#Region "Events"
    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        notMain.Clear()
        Dim id As Int32
        Int32.TryParse(ddlProductGroup.SelectedValue, id)

        If (UserManager.GetCurrentUser.ByPassProduct Or (From up In UserManager.GetCurrentUser.ProductGroups.Rows Where up("ID") = id Select up("id")).FirstOrDefault() <> Nothing) Then
            ProcessName(id)
        End If
    End Sub

    Protected Sub lnkSummaryView_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkRefresh.Click
        grdTrackingLog.DataSourceID = "odsTrackingLog"
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub

    Protected Sub ddlTime_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTime.SelectedIndexChanged
        grdTrackingLog.DataSourceID = "odsTrackingLog"
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub

    Protected Sub ddlFilterBatches_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlFilterBatches.SelectedIndexChanged
        Dim getAllBatches As Integer
        Dim bs As New BatchSearch()

        If ddlFilterBatches.SelectedValue IsNot Nothing AndAlso Not String.IsNullOrEmpty(ddlFilterBatches.SelectedValue) Then
            getAllBatches = CInt(ddlFilterBatches.SelectedValue)
        End If

        bs.ProductID = Me.hdnProductID.Value

        If (getAllBatches = 0) Then
            bs.ExcludedStatus = Contracts.BatchSearchBatchStatus.Complete
        End If

        If (getAllBatches > -1) Then
            bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
        End If
    End Sub

    Protected Sub grdReady_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdReady.EditIndex = e.NewEditIndex
        BindReady(ddlMRevision.SelectedValue)
        Dim lblIsReady As Label = grdReady.Rows(e.NewEditIndex).FindControl("lblIsReady")
        Dim lblComment As Label = grdReady.Rows(e.NewEditIndex).FindControl("lblComment")
        Dim rblIsReady As RadioButtonList = grdReady.Rows(e.NewEditIndex).FindControl("rblIsReady")
        Dim txtComment As TextBox = grdReady.Rows(e.NewEditIndex).FindControl("txtComment")
        Dim lblIsNestReady As Label = grdReady.Rows(e.NewEditIndex).FindControl("lblIsNestReady")
        Dim rblIsNestReady As RadioButtonList = grdReady.Rows(e.NewEditIndex).FindControl("rblIsNestReady")
        Dim txtJIRA As TextBox = grdReady.Rows(e.NewEditIndex).FindControl("txtJIRA")
        Dim hplJIRA As HyperLink = grdReady.Rows(e.NewEditIndex).FindControl("hplJIRA")

        hplJIRA.Visible = False
        lblIsNestReady.Visible = False
        lblIsReady.Visible = False
        lblComment.Visible = False
        rblIsReady.Visible = True
        rblIsNestReady.Visible = True
        txtComment.Visible = True
        txtJIRA.Visible = True

        If (rblIsReady.Items.FindByText(lblIsReady.Text) IsNot Nothing) Then
            rblIsReady.SelectedValue = rblIsReady.Items.FindByText(lblIsReady.Text).Value
        End If

        If (rblIsNestReady.Items.FindByText(lblIsNestReady.Text) IsNot Nothing) Then
            rblIsNestReady.SelectedValue = rblIsNestReady.Items.FindByText(lblIsNestReady.Text).Value
        End If
    End Sub

    Protected Sub grdReady_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtComment As TextBox = grdReady.Rows(e.RowIndex).FindControl("txtComment")
        Dim rblIsReady As RadioButtonList = grdReady.Rows(e.RowIndex).FindControl("rblIsReady")
        Dim rblIsNestReady As RadioButtonList = grdReady.Rows(e.RowIndex).FindControl("rblIsNestReady")
        Dim txtJIRA As TextBox = grdReady.Rows(e.RowIndex).FindControl("txtJIRA")

        Dim jira As Int32
        Dim ptrID As Int32
        Dim productID As Int32
        Dim testID As Int32
        Dim isReady As Int32
        Dim isNestReady As Int32
        Dim psID As Int32
        Int32.TryParse(grdReady.DataKeys(e.RowIndex).Values(0), testID)
        Int32.TryParse(Me.hdnProductID.Value, productID)
        Int32.TryParse(grdReady.DataKeys(e.RowIndex).Values(1).ToString(), ptrID)
        Int32.TryParse(grdReady.DataKeys(e.RowIndex).Values(2).ToString(), psID)
        Int32.TryParse(rblIsReady.SelectedValue, isReady)
        Int32.TryParse(rblIsNestReady.SelectedValue, isNestReady)

        If (txtJIRA.Text.LastIndexOf("-") < 0) Then
            Int32.TryParse(txtJIRA.Text, jira)
        Else
            Int32.TryParse(txtJIRA.Text.Substring(txtJIRA.Text.LastIndexOf("-") + 1), jira)
        End If

        ProductGroupManager.SaveProductReady(productID, testID, psID, ptrID, isReady, txtComment.Text, isNestReady, jira)

        grdReady.EditIndex = -1
        BindReady(ddlMRevision.SelectedValue)
    End Sub

    Protected Sub grdReady_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdReady.EditIndex = -1
        BindReady(ddlMRevision.SelectedValue)
    End Sub

    Protected Sub grdReady_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdReady.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(0).Enabled = UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsDeveloper Or UserManager.GetCurrentUser.IsTestCenterAdmin

            Select Case DirectCast(e.Row.Cells(4).FindControl("lblIsReady"), Label).Text.Trim().ToLower
                Case "yes"
                    e.Row.Cells(4).BackColor = Drawing.Color.LightGreen
                Case "no"
                    e.Row.Cells(4).BackColor = Drawing.Color.OrangeRed
                Case Else
                    e.Row.Cells(4).BackColor = Drawing.Color.LightGray
            End Select

            Select Case DirectCast(e.Row.Cells(5).FindControl("lblIsNestReady"), Label).Text.Trim().ToLower
                Case "yes"
                    e.Row.Cells(5).BackColor = Drawing.Color.LightGreen
                Case "no"
                    e.Row.Cells(5).BackColor = Drawing.Color.OrangeRed
                Case Else
                    e.Row.Cells(5).BackColor = Drawing.Color.LightGray
            End Select
        End If
    End Sub

    Protected Sub grdTargetDates_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdTargetDates.EditIndex = e.NewEditIndex
        BindTargetData()
        Dim txtValueText As TextBox = grdTargetDates.Rows(e.NewEditIndex).FindControl("txtValueText")
        Dim lblValueText As Label = grdTargetDates.Rows(e.NewEditIndex).FindControl("lblValueText")
        lblValueText.Visible = False
        txtValueText.Visible = True
    End Sub

    Protected Sub grdTargetDates_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdTargetDates.EditIndex = -1
        BindTargetData()
    End Sub

    Protected Sub grdTargetDates_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdTargetDates.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(0).Enabled = UserManager.GetCurrentUser.HasEditItemAuthority(ddlProductGroup.SelectedItem.Text, 0)
        End If
    End Sub

    Protected Sub grdTargetDates_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtValueText As TextBox = grdTargetDates.Rows(e.RowIndex).FindControl("txtValueText")
        Dim psID As Int32
        Dim productID As Int32
        Dim keyName As String = grdTargetDates.DataKeys(e.RowIndex).Values(1)
        Int32.TryParse(Me.hdnProductID.Value, productID)
        Int32.TryParse(grdTargetDates.DataKeys(e.RowIndex).Values(0), psID)

        ProductGroupManager.SaveSetting(productID, keyName, txtValueText.Text, String.Empty)

        grdTargetDates.EditIndex = -1
        BindTargetData()
    End Sub

    Protected Sub ddlMRevision_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlMRevision.SelectedIndexChanged
        BindReady(ddlMRevision.SelectedValue)
    End Sub

    Sub BindReady(ByVal revision As String)
        grdReady.DataSource = ProductGroupManager.GetProductTestReady(Me.hdnProductID.Value, revision)
        grdReady.DataBind()
    End Sub

    Sub BindTargetData()
        Dim instance = New Remi.Dal.Entities().Instance()
        Dim mSettings = (From ps In instance.ProductSettings Where ps.KeyName.StartsWith("M") And ps.Product.ID = Me.hdnProductID.Value Select ps.ID, ps.KeyName, ps.ValueText)

        If (mSettings.FirstOrDefault() Is Nothing) Then
            ProductGroupManager.CreateSetting(Me.hdnProductID.Value, "M1", String.Empty, String.Empty)
            ProductGroupManager.CreateSetting(Me.hdnProductID.Value, "M2", String.Empty, String.Empty)
            ProductGroupManager.CreateSetting(Me.hdnProductID.Value, "M3", String.Empty, String.Empty)
            ProductGroupManager.CreateSetting(Me.hdnProductID.Value, "M4", String.Empty, String.Empty)

            mSettings = (From setting In instance.ProductSettings Where setting.KeyName.StartsWith("M") And setting.Product.ID = Me.hdnProductID.Value Select setting.ID, setting.KeyName, setting.ValueText)
        End If

        grdTargetDates.DataSource = mSettings.ToList()
        grdTargetDates.DataBind()
    End Sub
#End Region

    Protected Sub ProcessName(ByVal id As Int32)
        Try
            Dim litTitle As Literal = Master.FindControl("litPageTitle")

            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - " + ddlProductGroup.Items.FindByValue(id.ToString()).Text
            End If

            If ddlProductGroup.Items.FindByValue(id.ToString()) IsNot Nothing Then
                ddlProductGroup.SelectedValue = id
                lblProductGroupName.Text = ddlProductGroup.Items.FindByValue(id.ToString()).Text
                Me.hdnProductID.Value = id
            End If

            hypEditSettings.NavigateUrl = REMIWebLinks.GetSetProductSettingsLink(id)
            HypEditTestConfiguration.NavigateUrl = REMIWebLinks.GetSetProductConfigurationLink(id)

            SetupMenuItems(ddlProductGroup.Items.FindByValue(id.ToString()).Text, id)
            accMain.SelectedIndex = 1
            BindTargetData()

            Dim targets = (From ps In New Remi.Dal.Entities().Instance().ProductSettings Where ps.KeyName.StartsWith("M") And ps.Product.ID = Me.hdnProductID.Value Select ps.KeyName, ps.ValueText).ToList()
            ddlMRevision.DataSource = targets
            ddlMRevision.DataBind()

            targets = (From t In targets Where Not String.IsNullOrEmpty(t.ValueText) Select t).ToList()

            ddlMRevision.SelectedValue = (From t In targets Where DateTime.Now > Convert.ToDateTime(t.ValueText) Order By Convert.ToDateTime(t.ValueText) Descending Select t.KeyName).FirstOrDefault()

            BindReady(ddlMRevision.SelectedValue)

            gvwContacts.DataSource = ProductGroupManager.GetProductContacts(Me.hdnProductID.Value)
            gvwContacts.DataBind()
        Catch ex As Exception
            notMain.Notifications = Helpers.GetExceptionMessages(ex)
        End Try
    End Sub

    Protected Sub SetupMenuItems(ByVal productGroup As String, ByVal id As Int32)
        Dim myMenu As WebControls.Menu
        Dim mi As MenuItem
        myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

        If UserManager.GetCurrentUser.HasEditItemAuthority(productGroup, 0) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
            liEditSettings.Visible = True

            mi = (From m As MenuItem In myMenu.Items(0).ChildItems Where m.Text = "Edit Product" Select m).FirstOrDefault()

            If (mi IsNot Nothing) Then
                mi.NavigateUrl = REMIWebLinks.GetSetProductSettingsLink(id)
            Else
                mi = New MenuItem
                mi.Text = "Edit Product"
                mi.NavigateUrl = REMIWebLinks.GetSetProductSettingsLink(id)
                myMenu.Items(0).ChildItems.Add(mi)
            End If
        End If

        If (UserManager.GetCurrentUser.HasUploadConfigXML() Or UserManager.GetCurrentUser.HasEditItemAuthority(productGroup, 0)) Then
            liEditConfigSettings.Visible = True

            mi = (From m As MenuItem In myMenu.Items(0).ChildItems Where m.Text = "Edit Config" Select m).FirstOrDefault()

            If (mi IsNot Nothing) Then
                mi.NavigateUrl = REMIWebLinks.GetSetProductConfigurationLink(id)
            Else
                mi = New MenuItem
                mi.Text = "Edit Config"
                mi.NavigateUrl = REMIWebLinks.GetSetProductConfigurationLink(id)
                myMenu.Items(0).ChildItems.Add(mi)
            End If
        End If
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim litTitle As Literal = Master.FindControl("litPageTitle")
            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - Product Information"
            End If

            chkByPass.Checked = UserManager.GetCurrentUser.ByPassProduct.ToString()
            hdnUserID.Value = UserManager.GetCurrentUser.ID
            ddlProductGroup.DataSourceID = "odsProducts"
            ddlProductGroup.DataBind()

            Dim id As Int32
            Int32.TryParse(Request.QueryString("Name"), id)

            If (id > 0) Then
                ddlProductGroup.SelectedValue = id
                btnSubmit_Click(sender, e)
            End If
        End If
    End Sub

    Protected Sub SetgvwContactsHeaders() Handles gvwContacts.PreRender
        Helpers.MakeAccessable(gvwContacts)
    End Sub

    Protected Sub SetGvwHeaders() Handles grdTrackingLog.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
    End Sub

    Protected Sub SetgrdTargetDatesHeaders() Handles grdTargetDates.PreRender
        Helpers.MakeAccessable(grdTargetDates)
    End Sub

    Protected Sub SetgrdgrdReadyHeaders() Handles grdReady.PreRender
        Helpers.MakeAccessable(grdReady)
    End Sub
End Class