Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Partial Class Admin_TrackingLocation
    Inherits System.Web.UI.Page
    Protected Sub Page_Load() Handles Me.Load
        If Not Page.IsPostBack AndAlso (Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.IsTestCenterAdmin) Then
            Response.Redirect("~/")
        End If

        If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
            Hyperlink3.Enabled = False
            Hyperlink1.Enabled = False
            ddlTestCenters.Enabled = False

            If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                Hyperlink2.Enabled = False
                HyperLink7.Enabled = False
                Hyperlink5.Enabled = False
                Hyperlink8.Enabled = False
                HyperLink9.Enabled = False
            End If
        End If

        Dim asm As AjaxControlToolkit.ToolkitScriptManager = Master.FindControl("AjaxScriptManager1")

        If (asm.IsInAsyncPostBack) Then
            gvMain.DataSource = TrackingLocationManager.GetList(ddlTestCenters.SelectedValue, 0)
            gvMain.DataBind()
        End If
    End Sub

    Protected Sub upTLLeftNav_PreRender() Handles upTLLeftNav.PreRender
        upLoad.Update()
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreRender
        If Not Page.IsPostBack Then
            ddlTestCenters.DataBind()

            Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
            If (ddlTestCenters.Items.Contains(l)) Then
                ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
            End If
        End If
    End Sub

    Protected Sub grdPlugin_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles grdPlugin.RowCommand
        Dim id As Int32
        Dim trackingLocationID As Int32

        Int32.TryParse(e.CommandArgument, id)
        Int32.TryParse(hdnSelectedTrackingLocationID.Value, trackingLocationID)

        Select Case e.CommandName.ToLower()
            Case "deleteitem"
                TrackingLocationManager.DeletePlugin(id)
                PluginDataBind(trackingLocationID)
                Exit Select
        End Select
    End Sub

    Protected Sub gvMain_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Dim ID As Integer
        Integer.TryParse(e.CommandArgument, ID)

        Select Case e.CommandName.ToLower()
            Case "edit"
                Dim tmpTL As TrackingLocationCollection = TrackingLocationManager.GetTrackingLocationHostsByID(ID)

                If tmpTL IsNot Nothing Then
                    grdHosts.Visible = True
                    grdPlugin.Visible = True
                    HostSubmit.Visible = True
                    btnPluginAdd.Visible = True
                    hdnSelectedTrackingLocationID.Value = tmpTL(0).ID
                    ShowAddEditPanel(tmpTL)
                End If
                Exit Select
            Case "deleteitem"
                notMain.Notifications.Add(TrackingLocationManager.Delete(ID))

                gvMain.DataSource = TrackingLocationManager.GetList(ddlTestCenters.SelectedValue, 0)
                gvMain.DataBind()
                Exit Select
            Case "checkavailability"
                Dim row As GridViewRow = CType(CType(e.CommandSource, LinkButton).Parent.Parent, GridViewRow)
                Dim state As String = TrackingLocationManager.CheckStatus(e.CommandArgument).ToString()
                row.Cells(6).Text = state
                Exit Select
        End Select
    End Sub

    Private Sub SetEditParamters(ByVal tl As TrackingLocationCollection)
        tl(0).Name = Helpers.CleanInputText(txtName.Text, 400)
        If ddlGeoLoc.SelectedItem IsNot Nothing Then
            tl(0).GeoLocationID = ddlGeoLoc.SelectedItem.Value
            tl(0).GeoLocationName = ddlGeoLoc.SelectedItem.Text
        Else
            tl(0).GeoLocationID = ddlGeoLoc.Items(0).Value
            tl(0).GeoLocationName = ddlGeoLoc.Items(0).Text
        End If
        tl(0).Status = TrackingLocationStatus.Available
        tl(0).TrackingLocationTypeID = ddlFixtureType.SelectedValue
        tl(0).Decommissioned = chkRetire.Checked
        tl(0).IsMultiDeviceZone = chkIsMultiDeviceZone.Checked
        tl(0).LocationStatus = ddlStatus.SelectedValue
    End Sub

    Protected Sub UpdateHeaders() Handles gvMain.PreRender
        Helpers.MakeAccessable(gvMain)
        For Each row As GridViewRow In gvMain.Rows
            If row.RowType = DataControlRowType.DataRow Then
                For Each cell As TableCell In row.Cells
                    If cell.Text.ToLower.Contains("unavailable") Then
                        cell.CssClass = "Fail"
                    ElseIf cell.Text.ToLower.Contains("available") Then
                        cell.CssClass = "Pass"
                    ElseIf cell.Text.ToLower.Contains("undermaintenance") Then
                        cell.CssClass = "NeedsRetest"
                    End If
                Next
            End If
        Next
    End Sub
    Protected Sub SetFormFieldsForEdit(ByVal tlc As TrackingLocationCollection)
        ddlFixtureType.DataBind()
        If tlc(0).TrackingLocationTypeID > 0 Then
            Dim tsType As ListItem = ddlFixtureType.Items.FindByValue(tlc(0).TrackingLocationTypeID)
            If tsType IsNot Nothing Then
                ddlFixtureType.SelectedValue = tsType.Value
            Else
                notMain.Notifications.Add(TrackingLocationManager.LogIssue("TrackingLocationsFillformFields", "w34", NotificationType.Warning, "Tracking Location: " + tlc(0).Name))
            End If
        End If

        hdnSelectedTrackingLocationID.Value = tlc(0).ID
        txtName.Text = tlc(0).Name
        chkRetire.Checked = tlc(0).Decommissioned
        chkIsMultiDeviceZone.Checked = tlc(0).IsMultiDeviceZone
        ddlStatus.SelectedValue = tlc(0).LocationStatus

        Dim dt As New DataTable()
        Dim dcHosts As New DataColumn("HostName", GetType(String))
        Dim dcID As New DataColumn("ID", GetType(Int32))
        dt.Columns.AddRange(New DataColumn() {dcHosts, dcID})

        For Each tl As TrackingLocation In tlc
            Dim dr As DataRow
            dr = dt.NewRow()
            dr.Item(0) = tl.HostName
            dr.Item(1) = tl.ID

            Dim status As TrackingLocationStatus = TrackingLocationManager.CheckStatus(tl.HostName)
            If (tl.Status <> status) Then
                TrackingLocationManager.SaveHostStatus(tl.HostName, UserManager.GetCurrentUser.LDAPName, status)
            End If

            dt.Rows.Add(dr)
        Next

        grdHosts.DataSource = dt
        grdHosts.DataBind()

        grdPlugin.DataSource = TrackingLocationManager.GetTrackingLocationPlugins(tlc(0).ID)
        grdPlugin.DataBind()

        If (tlc(0).GeoLocationID > 0) Then
            ddlGeoLoc.SelectedValue = tlc(0).GeoLocationID
        End If
    End Sub

    Private Sub PluginDataBind(ByVal id As Int32)
        grdPlugin.DataSource = TrackingLocationManager.GetTrackingLocationPlugins(id)
        grdPlugin.DataBind()
    End Sub

    Private Sub HostsDataBind(ByVal id As Int32)
        Dim tmpTL As TrackingLocationCollection = TrackingLocationManager.GetTrackingLocationHostsByID(id)
        Dim dt As New DataTable()
        Dim dcHosts As New DataColumn("HostName", GetType(String))
        Dim dcID As New DataColumn("ID", GetType(Int32))
        dt.Columns.AddRange(New DataColumn() {dcHosts, dcID})

        For Each tl As TrackingLocation In tmpTL
            Dim dr As DataRow
            dr = dt.NewRow()
            dr.Item(0) = tl.HostName
            dr.Item(1) = tl.ID
            dt.Rows.Add(dr)
        Next
        grdHosts.DataSource = dt
        grdHosts.DataBind()
    End Sub

    Protected Sub ShowAddEditPanel(ByVal tlc As TrackingLocationCollection)
        If tlc IsNot Nothing Then
            If (tlc.Count = 0) Then
                tlc.Add(New TrackingLocation)
                grdHosts.Visible = False
                grdPlugin.Visible = False
                HostSubmit.Visible = False
            End If
            notMain.Clear()
            If tlc(0).ID > 0 Then
                lblAddEditTitle.Text = "Editing the " & tlc(0).Name & " Tracking Location"
            Else
                lblAddEditTitle.Text = "Add a new Tracking Location"
            End If
            pnlViewAllTrackingLocations.Visible = False
            pnlAddEditTrackingLocation.Visible = True
            pnlLeftMenuActions.Visible = True

            SetFormFieldsForEdit(tlc)
        End If
    End Sub

    Protected Sub ShowAllTrackingLocations()
        hdnSelectedTrackingLocationID.Value = 0
        pnlViewAllTrackingLocations.Visible = True
        pnlAddEditTrackingLocation.Visible = False
        pnlLeftMenuActions.Visible = False
        gvMain.DataBind()
    End Sub

    Protected Sub lnkAddTrackingLocationAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTrackingLocationAction.Click
        Dim tlc As TrackingLocationCollection
        notMain.Clear()

        If CInt(hdnSelectedTrackingLocationID.Value) > 0 Then
            tlc = TrackingLocationManager.GetTrackingLocationHostsByID(CInt(hdnSelectedTrackingLocationID.Value))
        Else
            tlc = New TrackingLocationCollection
            If (tlc.Count = 0) Then
                tlc.Add(New TrackingLocation())
                tlc(0).HostName = HostNameNew.Text
                grdHosts.Visible = False
                grdPlugin.Visible = False
                btnPluginAdd.Visible = False
                HostSubmit.Visible = False
            End If
        End If

        SetEditParamters(tlc)

        Dim id As Int32 = TrackingLocationManager.SaveTrackingLocation(tlc)

        notMain.Notifications.Add(tlc(0).Notifications)

        If Not notMain.HasErrors Then
            ShowAllTrackingLocations()
        End If
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        ShowAllTrackingLocations()
    End Sub

    Protected Sub lnkViewTrackingLocations_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkViewTrackingLocations.Click
        ShowAllTrackingLocations()
    End Sub

    Protected Sub lnkAddTrackingLocation_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTrackingLocation.Click
        ShowAddEditPanel(New TrackingLocationCollection)
    End Sub

    Protected Sub btnPluginAdd_Click(ByVal sender As Object, ByVal e As EventArgs)
        TrackingLocationManager.SaveTrackingLocationPlugin(hdnSelectedTrackingLocationID.Value, txtPluginName.Text)
        PluginDataBind(hdnSelectedTrackingLocationID.Value)
        txtPluginName.Text = String.Empty
    End Sub

    Protected Sub grdHosts_RowDeleting(ByVal sender As Object, ByVal e As GridViewDeleteEventArgs)
        TrackingLocationManager.DeleteHost(grdHosts.DataKeys(e.RowIndex).Value, DirectCast(grdHosts.Rows(e.RowIndex).FindControl("txtHostName2"), TextBox).Text)
        HostsDataBind(grdHosts.DataKeys(e.RowIndex).Value)
    End Sub

    Protected Sub HostSubmit_Click(ByVal sender As Object, ByVal e As EventArgs)
        TrackingLocationManager.SaveTrackingLocationHost(hdnSelectedTrackingLocationID.Value, HostNameNew.Text)
        HostsDataBind(hdnSelectedTrackingLocationID.Value)
        HostNameNew.Text = String.Empty
    End Sub

    Protected Sub gvMain_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gvMain.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim decomm As Boolean = False
            Dim status As String = String.Empty
            Dim color As System.Drawing.Color

            If (DataBinder.Eval(e.Row.DataItem, "LocationStatus") IsNot Nothing) Then
                status = DataBinder.Eval(e.Row.DataItem, "LocationStatus").ToString()
            End If

            Select Case status
                Case Remi.Contracts.TrackingStatus.Functional.ToString()
                    color = Drawing.Color.White
                Case Remi.Contracts.TrackingStatus.Disabled.ToString()
                    color = Drawing.Color.LightGray
                Case Remi.Contracts.TrackingStatus.NotFunctional.ToString()
                    color = Drawing.Color.Red
                Case Remi.Contracts.TrackingStatus.UnderRepair.ToString()
                    color = Drawing.Color.Orange
            End Select

            If (DataBinder.Eval(e.Row.DataItem, "Decommissioned") IsNot Nothing) Then
                Boolean.TryParse(DataBinder.Eval(e.Row.DataItem, "Decommissioned").ToString(), decomm)
                If (decomm) Then
                    color = Drawing.Color.Yellow
                End If
            End If

            e.Row.BackColor = color
        End If
    End Sub
End Class