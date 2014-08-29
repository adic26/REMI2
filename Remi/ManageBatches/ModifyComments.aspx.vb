Imports REMI.BusinessEntities
Imports REMI.Bll

Partial Class ManageBatches_ModifyComments
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
            hypCancel.NavigateUrl = b.SetCommentsManagerLink
            lblComments.Text = b.GetJoinedComments()
            pnlEditExceptions.Visible = True
            pnlLeftMenuActions.Visible = True
        Else
            lblComments.Text = String.Empty
            pnlLeftMenuActions.Visible = False
            pnlEditExceptions.Visible = False
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If
    End Sub

    Public Sub AddComment()
        notMain.Notifications.Add(BatchManager.AddNewComment(hdnQRANumber.Value, txtRFBands.Text))
    End Sub

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        AddComment()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class