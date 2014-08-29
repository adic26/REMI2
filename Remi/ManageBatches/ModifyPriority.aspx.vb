Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports System.Data
Imports REMI.Contracts

Partial Class ManageBatches_ModifyPriority
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim qra As String = Request.QueryString.Get("QRA")
            If Not String.IsNullOrEmpty(qra) Then
                ProcessQRA(qra)
            End If
        End If
    End Sub

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As Batch

        If bc.Validate Then
            b = BatchManager.GetItem(bc.BatchNumber)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetPriorityManagerLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            SetupTestStageDropDownList(b)

            pnlEditExceptions.Visible = True
            pnlLeftMenuActions.Visible = True
        Else
            pnlLeftMenuActions.Visible = False
            pnlEditExceptions.Visible = False
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If
    End Sub

    Public Sub SaveStatus()
        notMain.Notifications.Add(BatchManager.SetPriority(hdnQRANumber.Value, ddlSelection.SelectedItem.Value))
    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal b As Batch)
        lblCurrentPriority.Text = b.CompletionPriority.ToString
        ddlSelection.DataSource = LookupsManager.GetLookups(LookupType.Priority, Nothing, Nothing, 0)
        ddlSelection.DataBind()
        ddlSelection.SelectedValue = b.CompletionPriorityID
    End Sub

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
