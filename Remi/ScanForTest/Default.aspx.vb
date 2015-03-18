Imports Remi.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Contracts

Partial Class Scanning_Default
    Inherits System.Web.UI.Page

    Dim _notApplicableString As String = "Not Applicable"

#Region "Page Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        txtBarcodeReading.Focus()

        If Not Page.IsPostBack Then
            hdnHostname.Value = REMI.Core.REMIHttpContext.GetCurrentHostname 'set the hostname so as to fill the location list
            hdnUserLocation.Value = UserManager.GetCurrentUser.TestCentre

            Dim litTitle As Literal = Master.FindControl("litPageTitle")
            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - Scan - " + hdnHostname.Value
            End If

            ddlBinType.Visible = False
            chkPick.Visible = False
            chkPick.Checked = False
        End If
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreLoad
        If Not Page.IsPostBack Then
            ddlRequestType.DataSource = UserManager.GetCurrentUser.RequestTypes
            ddlRequestType.DataBind()

            If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
                ddlRequestType.SelectedIndex = 0
            End If

            If (ddlRequestType.Items.Count = 1) Then
                ddlRequestType.Enabled = False
            End If

            BindJobs()
        End If
    End Sub
#End Region

#Region "Methods"
    Protected Sub BindJobs()
        Dim jc As New JobCollection
        jc.Add(New Job("Not Applicable"))
        jc.AddRange(JobManager.GetJobListDT(ddlRequestType.SelectedValue, UserManager.GetCurrentUser.ID, 0))

        ddlJobs.DataSource = jc
        ddlJobs.DataBind()
    End Sub

    Sub BarCodeValidation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(txtBarcodeReading.Text))

        If (bc.DetailAvailable() = QRANumberType.BatchAndUnit And bc.UnitNumber > 0) Then
            arguments.IsValid = True
        ElseIf (bc.DetailAvailable() = QRANumberType.BatchOnly) Then
            arguments.IsValid = True
        Else
            arguments.IsValid = False
        End If
    End Sub

    Protected Sub HandleScan(ByVal returnData As ScanReturnData)
        If returnData.ScanSuccess Then
            sciTracking.ShowSuccess(returnData.Direction)
            lblLocationDetailsTitle.Text = returnData.TrackingLocationName
        Else
            sciTracking.ShowFail(returnData.Direction)
        End If
        notMain.Notifications.Add(returnData.Notifications)
    End Sub
#End Region

#Region "Events"
    Protected Sub ddlPossibleLocations_SelectedIndexChanged(ByVal sender As Object, ByVal e As EventArgs) Handles ddlPossibleLocations.SelectedIndexChanged
        txtBarcodeReading.Text = String.Empty
        ddlBinType.Visible = False
        chkPick.Visible = False
        chkPick.Checked = False
        cblUnit.Items.Clear()
    End Sub

    Protected Sub ddlPossibleLocations_databound() Handles ddlPossibleLocations.DataBound
        If Not Page.IsPostBack Then
            If ddlPossibleLocations.Items.Count > 0 Then
                Dim dt As DataTable = REMIAppCache.GetUserServiceAccess(UserManager.GetCurrentUser.ID)
                Dim hasRemStar As Boolean = If((From ma In dt.AsEnumerable() Where ma.Field(Of String)("ServiceName") = "REMSTAR").FirstOrDefault() IsNot Nothing, True, False)

                If (hasRemStar) Then
                    Dim col As TrackingLocationCollection = TrackingLocationManager.GetTrackingLocationsByHostName(hdnHostname.Value, "REMSTAR", 1, 0, UserManager.GetCurrentUser.TestCentreID)

                    If (col.Count > 0) Then
                        ddlPossibleLocations.SelectedValue = (From pl As ListItem In ddlPossibleLocations.Items Where pl.Value = col(0).ID Select pl.Value).FirstOrDefault()
                    End If

                    ddlBinType.DataSource = REMI.Dal.RemstarDB.GetBinType()
                    ddlBinType.DataBind()
                    ddlBinType.SelectedValue = ddlBinType.Items.FindByText("SMALL-REM2").Value
                Else
                    If (ddlPossibleLocations.Items.FindByText("Lab - " + UserManager.GetCurrentUser.TestCentre) IsNot Nothing) Then
                        ddlPossibleLocations.SelectedValue = ddlPossibleLocations.Items.FindByText("Lab - " + UserManager.GetCurrentUser.TestCentre).Value
                    End If
                End If
            End If
        End If
    End Sub

    Protected Sub ddlJobs_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs.SelectedIndexChanged
        ddlTestStage.Items.Clear()
        ddlTestStage.Items.Add(New ListItem("Not Applicable"))
        odsTestStages.DataBind()
        ddlTestStage.DataBind()
    End Sub

    Protected Sub ddlRequestType_SelectedIndexChanged(sender As Object, e As EventArgs)
        BindJobs()
    End Sub
#End Region

#Region "Button Events"
    Protected Sub btnCancel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnCancel.Click
        txtBarcodeReading.Text = "Enter Request Number..."
        txtBarcodeReading.CssClass = "ScanDeviceTextEntryHint"
        txtBarcodeReading.Focus()
        cblUnit.Items.Clear()
        cblUnit.Visible = False
    End Sub

    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        If (Page.IsValid) Then
            notMain.Clear()
            sciTracking.ShowNone()

            Dim dt As DataTable = REMIAppCache.GetUserServiceAccess(UserManager.GetCurrentUser.ID)
            Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtBarcodeReading.Text), 21))
            Dim units As List(Of String) = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Selected = True Select item.Value).ToList()

            If (bc.Validate()) Then
                Dim department As REMI.Entities.Batch = BatchManager.GetRAWBatchInformation(bc.BatchNumber)
                Dim deptID As Int32

                If (department IsNot Nothing) Then
                    deptID = department.DepartmentID
                    Dim hasRemStar As Boolean = If((From ma In dt.AsEnumerable() Where ma.Field(Of String)("ServiceName") = "REMSTAR" And ma.Field(Of String)("Department") = department.Department.Values).FirstOrDefault() IsNot Nothing, True, False)

                    If (hasRemStar) Then
                        If (ddlPossibleLocations.SelectedItem.Text.ToUpper.Contains("REMSTAR")) Then
                            ddlBinType.Visible = True
                            chkPick.Visible = False
                            chkPick.Checked = False
                        Else
                            chkPick.Visible = True
                            ddlBinType.Visible = False
                        End If
                    Else
                        ddlBinType.Visible = False
                        chkPick.Visible = False
                        chkPick.Checked = False
                    End If
                End If

                If (Not bc.BatchNumber.Contains(ddlRequestType.SelectedItem.Text)) Then
                    notMain.Notifications.AddWithMessage("You Are Not In The Correct Request Area!", NotificationType.Warning)
                Else
                    If (bc.UnitNumber = 0) Then
                        bc = New DeviceBarcodeNumber(String.Format("{0}-{1:d3}", bc.Number, 1))
                    End If

                    If (bc.UnitNumber > 0) Then
                        If (UserManager.GetCurrentUser.HasScanForTestAuthority(deptID)) Then
                            If (units.Count = 0) Then
                                cblUnit.Items.Clear()
                                cblUnit.Items.Add("All")
                                cblUnit.DataSource = TestUnitManager.GetAvailableUnits(bc.BatchNumber, 0)
                                cblUnit.DataBind()
                                cblUnit.Visible = True

                                If (cblUnit.Items.FindByValue(bc.UnitNumber) IsNot Nothing) Then
                                    cblUnit.Items.FindByValue(bc.UnitNumber).Selected = True
                                End If
                            Else
                                If (units.Contains("All")) Then
                                    units.Clear()
                                    units = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Value <> "All" Select item.Value).ToList()
                                End If

                                Dim selectedTestStage As String
                                Dim selectedJobName As String

                                If ddlTestStage.SelectedValue <> _notApplicableString Then
                                    selectedTestStage = ddlTestStage.SelectedValue
                                Else
                                    selectedTestStage = String.Empty
                                End If

                                If ddlJobs.SelectedValue <> _notApplicableString Then
                                    selectedJobName = ddlJobs.SelectedValue
                                Else
                                    selectedJobName = String.Empty
                                End If

                                Dim shelves As New Dictionary(Of Int32, String)

                                If (chkPick.Checked And chkPick.Visible) Then
                                    For Each unit As String In units
                                        bc = New DeviceBarcodeNumber(bc.BatchNumber, unit)
                                        Dim shelfNumber As String = String.Empty
                                        notMain.Notifications.Add(BatchManager.PickBatchFromREMSTAR(bc.Number, shelfNumber))

                                        If (Not String.IsNullOrEmpty(shelfNumber)) Then
                                            shelves.Add(unit, shelfNumber)
                                        End If
                                    Next
                                End If

                                'Scan out remaining units selected
                                For Each unit As String In units
                                    Dim val As String = String.Empty
                                    Dim processScanning As Boolean = True

                                    If (chkPick.Checked And chkPick.Visible And shelves.TryGetValue(unit, val) = False) Then
                                        processScanning = False
                                    End If

                                    If (processScanning) Then
                                        bc = New DeviceBarcodeNumber(bc.BatchNumber, unit)

                                        'if this is a pc where scans can take place the user will have an option of selecting a location
                                        'this will be parsed and added on to the scanned barcode. 
                                        If Not String.IsNullOrEmpty(ddlPossibleLocations.SelectedValue) Then
                                            bc.SetTrackingLocationPart(ddlPossibleLocations.SelectedValue, False)
                                        End If
                                        HandleScan(ScanManager.Scan(bc.Number, selectedTestStage, selectedTestStage, binType:=Request.Form(ddlBinType.UniqueID), jobName:=selectedJobName, productGroup:=String.Empty))
                                    Else
                                        notMain.Notifications.AddWithMessage(String.Format("Unit {0} Was Not In Remstar. Scanning Cancelled", unit), NotificationType.Warning)
                                    End If
                                Next

                                txtBarcodeReading.Text = "Enter Request Number..."
                                txtBarcodeReading.CssClass = "ScanDeviceTextEntryHint"
                                txtBarcodeReading.Focus()
                                cblUnit.Items.Clear()
                                cblUnit.Visible = False
                            End If
                        Else
                            notMain.Notifications.AddWithMessage("That Request Isn't Part Of Your Department", NotificationType.Warning)
                        End If
                    End If
                End If
            End If
        End If
    End Sub
#End Region
End Class