Imports Remi.Bll
Imports Remi.Validation
Imports REMI.Contracts
Imports Remi.BusinessEntities
Imports System.Web.Script.Serialization
Imports System.Web
Imports System.Linq
Imports Newtonsoft.Json

Public Class Reports
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            ddlRequestType.DataSource = RequestManager.GetRequestTypes()
            ddlRequestType.DataBind()

            Dim requestType As String = IIf(Request.QueryString.Item("rt") Is Nothing, String.Empty, Request.QueryString.Item("rt"))

            If (requestType.Trim().Length > 0) Then
                ddlRequestType.Items.FindByText(requestType).Selected = True
            End If

            UpdateSearch()
        End If

        If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
            ddlRequestType.SelectedIndex = 0
        End If
    End Sub

    Private Sub UpdateSearch()
        srcRequest.RequestType = ddlRequestType.SelectedItem.Value
        srcRequest.Visible = True
    End Sub

    Protected Sub ddlRequestType_SelectedIndexChanged(sender As Object, e As EventArgs)
        UpdateSearch()
    End Sub
End Class