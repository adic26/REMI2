Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports System.Data
Partial Class _Default
    Inherits System.Web.UI.Page

#Region "Daily List Display Methods"
    Protected Sub SetGridViewHeader(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwDailyList.PreRender
        Helpers.MakeAccessable(DirectCast(sender, GridView))
    End Sub

    ''' <summary>
    ''' Gets and sets the daily list data.
    ''' </summary>
    ''' <remarks></remarks>
    Protected Sub DatabindDailyList()
        notDailyList.Clear()
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreRender
        For Each r As GridViewRow In gvwDailyList.Rows
            For Each c As TableCell In r.Cells
                c.Text = System.Web.HttpUtility.HtmlDecode(c.Text)
            Next
        Next
    End Sub
#End Region

#Region "Left Menu Methods"
    Protected Sub ddlProductGroups_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlProductGroups.SelectedIndexChanged
        DatabindDailyList()
    End Sub

    Protected Sub ddlTestCenters_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestCenters.SelectedIndexChanged
        DatabindDailyList()
    End Sub

    Protected Sub lkbViewDailyList_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbViewDailyList.Click
        DatabindDailyList()
    End Sub

    Protected Sub chkGetFailParams_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles chkGetFailParams.CheckedChanged
        DatabindDailyList()
    End Sub

    Protected Sub rbtnTestStageCompletion_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles rbtnTestStageCompletion.SelectedIndexChanged
        DatabindDailyList()
    End Sub
#End Region

#Region "Notification Methods"
    Protected Sub SetNotifications(ByVal notifications As NotificationCollection)
        notDailyList.Notifications() = notifications
    End Sub
#End Region

    Protected Sub lnkExport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkExport.Click
        Helpers.ExportToExcel(Helpers.GetDateTimeFileName("DailyList", "xls"), gvwDailyList)
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Response.Redirect("/ScanForInfo/Default.aspx", True)

        Dim litTitle As Literal = Master.FindControl("litPageTitle")
        If litTitle IsNot Nothing Then
            litTitle.Text = "Daily List - " + DateTime.Now.ToString("f")
        End If
        Dim prodList As DataTable = ProductGroupManager.GetProductList(UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False)
        Dim newRow As DataRow = prodList.NewRow
        newRow("ID") = 0
        newRow("ProductGroupName") = "All Products"
        prodList.Rows.InsertAt(newRow, 0)
        ddlProductGroups.DataSource = prodList
        ddlProductGroups.DataBind()
    End Sub

    Protected Sub odsDailyList_Selecting(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.ObjectDataSourceSelectingEventArgs) Handles odsDailyList.Selecting
        If Not Page.IsPostBack Then
            'ensure the ddl is databound
            If ddlTestCenters.Items.Count = 0 Then
                ddlTestCenters.DataBind()
            End If

            ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
            e.InputParameters.Item("TestCenterLocation") = ddlTestCenters.SelectedValue
        End If
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function AddException(ByVal jobname As String, ByVal teststagename As String, ByVal testname As String, ByVal qraNumber As String, ByVal unitcount As String) As Boolean
        Dim tex As New TestException()
        Dim nc As Notification
        Dim count As Integer = 1
        Dim hasSuccess As Boolean = True

        tex.TestStageName = teststagename
        tex.TestName = testname
        tex.JobName = jobname
        tex.QRAnumber = qraNumber

        While count <= unitcount
            tex.UnitNumber = count
            nc = ExceptionManager.AddException(tex)
            count += 1

            If (nc.Message <> "Exception saved ok.") Then
                hasSuccess = False
            End If
        End While

        Return hasSuccess
    End Function
End Class