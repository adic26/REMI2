﻿Imports Remi.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Contracts

Partial Class Scanning_Default
    Inherits System.Web.UI.Page

    Dim _notApplicableString As String = "Not Applicable"

#Region "Main Methods"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        txtBarcodeReading.Focus()
        ddlBinType.DataSource = REMI.Dal.RemstarDB.GetBinType()
        ddlBinType.DataBind()
        ddlBinType.SelectedValue = ddlBinType.Items.FindByText("SMALL-REM2").Value

        If Not Page.IsPostBack Then
            hdnHostname.Value = REMI.Core.REMIHttpContext.GetCurrentHostname 'set the hostname so as to fill the location list
            hdnUserLocation.Value = UserManager.GetCurrentUser.TestCentre

            Dim litTitle As Literal = Master.FindControl("litPageTitle")
            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - Scan - " + hdnHostname.Value
            End If
        End If
    End Sub

    Protected Sub ddlPossibleLocations_SelectedIndexChanged(ByVal sender As Object, ByVal e As EventArgs) Handles ddlPossibleLocations.SelectedIndexChanged
        If (ddlPossibleLocations.SelectedItem.Text.Contains("REMSTAR")) Then
            ddlBinType.Visible = True
            chkPick.Visible = False
            chkPick.Checked = False
        Else
            chkPick.Checked = False
            chkPick.Visible = True
            ddlBinType.Visible = False
        End If
    End Sub

    Protected Sub ddlPossibleLocations_databound() Handles ddlPossibleLocations.DataBound
        If Not Page.IsPostBack Then
            If ddlPossibleLocations.Items.Count > 0 Then
                Dim remstar As String() = REMI.Core.REMIConfiguration.RemStarHostNames().Split(New Char() {","}, StringSplitOptions.RemoveEmptyEntries)

                'add remstar if required
                If remstar.Contains(REMI.Core.REMIHttpContext.GetCurrentHostname) AndAlso ddlPossibleLocations.Items.FindByText("REMSTAR") Is Nothing AndAlso UserManager.GetCurrentUser.TestCentre = "Cambridge" Then
                    ddlPossibleLocations.Items.Add(New ListItem("REMSTAR - Cambridge", 25))
                End If

                'select remstar if it is in the list
                If ddlPossibleLocations.Items.FindByText("REMSTAR - " + UserManager.GetCurrentUser.TestCentre) IsNot Nothing Then
                    ddlPossibleLocations.SelectedValue = ddlPossibleLocations.Items.FindByText("REMSTAR - " + UserManager.GetCurrentUser.TestCentre).Value
                    ddlBinType.Visible = True
                    chkPick.Visible = False
                Else
                    If (ddlPossibleLocations.Items.FindByText("Lab - " + UserManager.GetCurrentUser.TestCentre) IsNot Nothing) Then
                        ddlPossibleLocations.SelectedValue = ddlPossibleLocations.Items.FindByText("Lab - " + UserManager.GetCurrentUser.TestCentre).Value
                    End If
                End If
            End If
        End If
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

    Protected Sub ddlJobs_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs.SelectedIndexChanged
        ddlTestStage.Items.Clear()
        ddlTestStage.Items.Add(New ListItem("Not Applicable"))
        odsTestStages.DataBind()
        ddlTestStage.DataBind()
    End Sub

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

            Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtBarcodeReading.Text), 21))
            Dim units As List(Of String) = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Selected = True Select item.Value).ToList()

            If (bc.Validate()) Then
                If (bc.UnitNumber = 0) Then
                    bc = New DeviceBarcodeNumber(String.Format("{0}-{1:d3}", bc.Number, 1))
                End If

                If (bc.UnitNumber > 0) Then
                    Dim deptID As Int32 = (From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber = bc.BatchNumber Select b.DepartmentID).FirstOrDefault()

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
    End Sub
#End Region
End Class