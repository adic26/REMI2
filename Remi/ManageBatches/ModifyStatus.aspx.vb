Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Imports REMI.Contracts
Partial Class ManageBatches_ModifyStatus
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
#Region "Test Exceptions methods"

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As Batch

        If bc.Validate Then
            b = BatchManager.GetItem(bc.BatchNumber)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetStatusManagerLink
            SetupTestStageDropDownList(b.Status.ToString)


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
        notMain.Notifications.Add(BatchManager.SetStatus(hdnQRANumber.Value, DirectCast([Enum].Parse(GetType(BatchStatus), ddlSelection.SelectedItem.Text), BatchStatus)))

    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal currentStatus As String)
        ddlSelection.DataSource = Helpers.GetBatchStatus
        ddlSelection.DataBind()
        lblCurrentStatus.Text = currentStatus
    End Sub
#End Region

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
