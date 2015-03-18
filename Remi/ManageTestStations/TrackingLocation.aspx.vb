Imports REMI.Bll
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Core

Partial Class ManageTestStations_TrackingLocation
    Inherits System.Web.UI.Page

    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
    End Sub

    Protected Sub SetgrdTrackingLogHeaders() Handles grdTrackingLog.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
    End Sub

    Protected Sub SetgrdDetailHeaders() Handles grdDetail.PreRender
        Helpers.MakeAccessable(grdDetail)
    End Sub

    Protected Sub ProcessBarcode(ByVal tmpID As Integer)
        Try
            Dim tl As TrackingLocation = TrackingLocationManager.GetTrackingLocationByID(tmpID)
            If tl IsNot Nothing Then
                Dim tlColl As New TrackingLocationCollection()
                tlColl.Add(tl)

                grdDetail.DataSource = tlColl
                grdDetail.DataBind()
                grdDetail.Columns(8).Visible = UserManager.GetCurrentUser.HasDocumentAuthority()

                Dim litTitle As Literal = Master.FindControl("litPageTitle")

                If litTitle IsNot Nothing Then
                    litTitle.Text = "REMI - " + tl.DisplayName
                End If

                hdnBarcodePrefix.Value = tl.ID
                bscBatches.DataBind()
                grdTrackingLog.DataBind()

                Dim myMenu As WebControls.Menu
                Dim mi As New MenuItem
                myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

                If UserManager.GetCurrentUser.HasUploadConfigXML() Then
                    liEditConfig.Visible = True
                    HypEditStationConfiguration.NavigateUrl = REMIWebLinks.GetSetStationConfigurationLink(tl.ID)

                    mi = (From m As MenuItem In myMenu.Items(0).ChildItems Where m.Text = "Edit Config" Select m).FirstOrDefault()

                    If (mi IsNot Nothing) Then
                        mi.NavigateUrl = REMIWebLinks.GetSetStationConfigurationLink(tl.ID)
                    Else
                        mi = New MenuItem
                        mi.Text = "Edit Config"
                        mi.NavigateUrl = REMIWebLinks.GetSetStationConfigurationLink(tl.ID)
                        myMenu.Items(0).ChildItems.Add(mi)
                    End If
                End If
            Else
                notMain.Notifications.AddWithMessage("Select a tracking location from the menu.", NotificationType.Information)
            End If
        Catch ex As Exception
            notMain.Notifications = Helpers.GetExceptionMessages(ex)
        End Try
    End Sub

    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        If Not Page.IsPostBack Then
            ddlTestCenters.DataBind()
            ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID

            If (ddlTrackingLocation.Items.Count = 0) Then
                ddlTrackingLocation.DataBind()
            End If
        End If

        notMain.Clear()
        Dim tmpBarcodeSuffix As Int32 = If(Request(ddlTrackingLocation.UniqueID) = 0, If(Request("BarcodeSuffix") = 0, If(ddlTrackingLocation.Items.Count = 0, 0, ddlTrackingLocation.Items(0).Value), Request("BarcodeSuffix")), Request(ddlTrackingLocation.UniqueID))
        Dim locationID As Int32 = (From tl In New REMI.Dal.Entities().Instance().TrackingLocations Where tl.ID = tmpBarcodeSuffix Select tl.Lookup.LookupID).FirstOrDefault()

        If (locationID = ddlTestCenters.SelectedValue) Then
            ProcessBarcode(tmpBarcodeSuffix)
            lblTrackingLocation.Text = ddlTrackingLocation.Items.FindByValue(tmpBarcodeSuffix).Text
        ElseIf (locationID <> ddlTestCenters.SelectedValue) Then
            ddlTrackingLocation.DataBind()

            If (ddlTrackingLocation.Items.Count > 0) Then
                tmpBarcodeSuffix = ddlTrackingLocation.Items(0).Value
                ProcessBarcode(tmpBarcodeSuffix)
                ddlTrackingLocation.SelectedValue = tmpBarcodeSuffix
                lblTrackingLocation.Text = ddlTrackingLocation.Items.FindByValue(tmpBarcodeSuffix).Text
            Else
                hdnBarcodePrefix.Value = 0
                bscBatches.Datasource = Nothing
                bscBatches.DataBind()
                grdTrackingLog.DataSource = Nothing
                grdTrackingLog.DataBind()
            End If
        Else
            Dim litTitle As Literal = Master.FindControl("litPageTitle")
            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - Tracking Location Information"
                lblTrackingLocation.Text = ""
            End If
            End If
    End Sub

#Region "Click Events"
    Protected Sub lnkSummaryView_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkRefresh.Click
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub

    Protected Sub ddlTime_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTime.SelectedIndexChanged
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub
#End Region
End Class