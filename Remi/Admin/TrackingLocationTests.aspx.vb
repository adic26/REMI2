Imports REMI.Bll

Public Class TrackingLocationTests
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not (Page.IsPostBack) Then
            If Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority Then
                Response.Redirect("~/")
            End If

            If (REMI.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                Hyperlink1.Enabled = False
                Hyperlink3.Enabled = False
                HyperLink9.Enabled = False
            End If

            ddlTestType.DataSource = Helpers.GetTestTypes()
            ddlTestType.DataBind()

            ddlTrackType.Items.Add(New ListItem("ALL", 0))
            ddlTrackType.DataSource = Helpers.GetTrackingLocationFunctions
            ddlTrackType.DataBind()
        End If
    End Sub

    Protected Sub SetGvwHeader() Handles gvwTypeTests.PreRender
        Helpers.MakeAccessable(gvwTypeTests)
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreRender
        For i As Int32 = 0 To gvwTypeTests.Rows.Count - 1
            Dim testName As String = gvwTypeTests.Rows(i).Cells(0).Text
            For j As Int32 = 1 To gvwTypeTests.Rows(i).Cells.Count - 1
                Dim trackingType As String = gvwTypeTests.HeaderRow.Cells(j).Text

                If (Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                    Dim chk As New CheckBox()
                    chk.ID = String.Format("chk{0}", gvwTypeTests.Rows(i).Cells(j).ClientID)
                    chk.InputAttributes.Add("onclick", "AddRemoveTypeToTest_Click('" & testName & "', '" & trackingType & "', '" & gvwTypeTests.Rows(i).Cells(j).ClientID & "');")
                    gvwTypeTests.Rows(i).Cells(j).Controls.Add(chk)


                    If (gvwTypeTests.Rows(i).Cells(j).Text = "1") Then
                        chk.Checked = True
                        gvwTypeTests.Rows(i).Cells(j).BackColor = Drawing.Color.Green
                    End If

                End If
            Next
        Next
    End Sub



    Protected Sub gvwTypeTests_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTypeTests.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row().Cells(0).CssClass = "removeStyle"
            Dim testName As String = e.Row().Cells(0).Text
        End If
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function AddRemoveTypeToTest(ByVal testName As String, ByVal trackingType As String) As Boolean
        Dim success As Boolean = TrackingLocationManager.AddRemoveTypetoTest(trackingType, testName)

        Return success
    End Function
End Class