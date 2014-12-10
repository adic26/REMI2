Imports REMI.Bll
Imports REMI.BusinessEntities

Partial Class Admin_TrackingLocationTypes
    Inherits System.Web.UI.Page

    Dim EditID As Integer
    Dim tlType As TrackingLocationType

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority Then
                Response.Redirect("~/")
            End If

            If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                pnlAddEdit.Enabled = False
                lnkAddTrackingLocationAction.Enabled = False
                lnkAddTT.Enabled = False
                Hyperlink6.Enabled = False
                Hyperlink5.Enabled = False
                HyperLink9.Enabled = False
            End If

            ddlFunction.DataSource = Helpers.GetTrackingLocationFunctions
            ddlFunction.DataBind()
        End If
    End Sub

    Protected Sub UpdategvTestStationTypesHeader() Handles gvTestStationTypes.PreRender
        Helpers.MakeAccessable(gvTestStationTypes)
    End Sub

    Protected Sub lnkAddTT_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTT.Click
        pnlAddEdit.Visible = True
        pnlViewAll.Visible = False
    End Sub

    Protected Sub gvTestStationTypes_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "edit"
                EditID = Convert.ToInt32(e.CommandArgument)
                hdnEditID.Value = EditID
                pnlAddEdit.Visible = True
                pnlViewAll.Visible = False

                tlType = TrackingLocationManager.GetTrackingLocationTypeByID(EditID)

                If Not tlType Is Nothing Then
                    SetValuesForEdit(tlType)
                End If

                Exit Select
        End Select
    End Sub

    Protected Sub SetValuesForEdit(ByVal tlType As TrackingLocationType)
        If tlType.ID > 0 Then
            lblAddEditTitle.Text = "Editing: " & tlType.Name
        Else
            lblAddEditTitle.Text = "Add a new Tracking Location Type"
        End If

        ddlFunction.SelectedValue = ddlFunction.Items.FindByText(tlType.TrackingLocationFunction.ToString()).Value

        txtName.Text = tlType.Name
        txtUnitCapacity.Text = tlType.UnitCapacity
        txtWorkInstructionLocation.Text = tlType.WILocation
    End Sub

    Protected Sub SetValuesForSave(ByVal tlType As TrackingLocationType)
        tlType.TrackingLocationFunction = DirectCast([Enum].Parse(GetType(TrackingLocationFunction), ddlFunction.SelectedItem.Text), TrackingLocationFunction)
        tlType.Name = txtName.Text
        Integer.TryParse(txtUnitCapacity.Text, tlType.UnitCapacity)
        tlType.WILocation = txtWorkInstructionLocation.Text
    End Sub

    Protected Sub lnkAddTrackingLocationAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTrackingLocationAction.Click
        Int32.TryParse(hdnEditID.Value, EditID)

        If EditID > 0 Then
            tlType = TrackingLocationManager.GetTrackingLocationTypeByID(EditID)
        End If

        If tlType IsNot Nothing Then
            tlType.LastUser = UserManager.GetCurrentValidUserLDAPName
        Else
            tlType = New TrackingLocationType
        End If

        SetValuesForSave(tlType)

        TrackingLocationManager.SaveTLType(tlType)
        notMain.Notifications.Add(tlType.Notifications)

        gvTestStationTypes.DataBind()
        pnlAddEdit.Visible = False
        pnlViewAll.Visible = True
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        Response.Redirect(Helpers.GetCurrentPageName)
    End Sub

    Protected Sub lnkViewTrackingLocations_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkViewTrackingLocations.Click
        Response.Redirect(Helpers.GetCurrentPageName)
    End Sub
End Class