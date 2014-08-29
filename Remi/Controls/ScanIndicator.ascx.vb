Partial Class Controls_ScanIndicator
    Inherits System.Web.UI.UserControl
    Public Sub ShowNone()
        pnlFailScan.Visible = False
        pnlSuccessScan.Visible = False
        pnlInformation.Visible = False
    End Sub

    Public Sub ShowSuccess(ByVal direction As Remi.BusinessEntities.ScanDirection)
        pnlFailScan.Visible = False
        pnlSuccessScan.Visible = True
        Select Case direction
            Case Remi.BusinessEntities.ScanDirection.Inward
                litScanPass.Text = "Scanned IN Successfuly"
            Case Remi.BusinessEntities.ScanDirection.Outward
                litScanPass.Text = "Scanned OUT Successfuly"
        End Select
        pnlInformation.Visible = False
    End Sub

    Public Sub ShowFail(ByVal direction As Remi.BusinessEntities.ScanDirection)
        pnlFailScan.Visible = True
        Select Case direction
            Case Remi.BusinessEntities.ScanDirection.Inward
                litScanFail.Text = "Scan IN Failed"
            Case Remi.BusinessEntities.ScanDirection.Outward
                litScanFail.Text = "Scan OUT Failed"
        End Select
        pnlSuccessScan.Visible = False
        pnlInformation.Visible = False
    End Sub

    Public Sub ShowInfo(ByVal direction As Remi.BusinessEntities.ScanDirection)
        pnlFailScan.Visible = False
        pnlSuccessScan.Visible = False
        pnlInformation.Visible = True
        Select Case direction
            Case Remi.BusinessEntities.ScanDirection.Inward
                litScanInfo.Text = "Scan IN Failed"
            Case Remi.BusinessEntities.ScanDirection.Outward
                litScanInfo.Text = "Scan OUT Failed"
        End Select
    End Sub
End Class