Imports Remi.Bll
Imports Remi.Validation

Partial Class Developer_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsDeveloper Then
                Response.Redirect("~/")
            End If

            ddlMode.DataSource = LookupsManager.GetLookups("ConfigModes", 0, 0, String.Empty, String.Empty, 0, True, 1, False)
            ddlMode.DataBind()

            ddlType.DataSource = LookupsManager.GetLookups("ConfigTypes", 0, 0, String.Empty, String.Empty, 0, True, 1, False)
            ddlType.DataBind()

            Dim instance = New Remi.Dal.Entities().Instance()
            ddlName.DataSource = (From v In instance.Configurations Select v.Name).Distinct.ToList()
            ddlName.DataBind()

            ddlVersions.DataSource = (From v In instance.Configurations Select v.Version).Distinct.ToList()
            ddlVersions.DataBind()
        End If
    End Sub

    Protected Sub btnQuery_Click(sender As Object, e As EventArgs)
        notMain.Notifications.Clear()
        Dim modeID As Int32
        Dim configTypeID As Int32
        Dim ver As Version
        Int32.TryParse(ddlMode.SelectedValue, modeID)
        Int32.TryParse(ddlType.SelectedValue, configTypeID)
        ver = New Version(ddlVersions.SelectedValue)

        Dim xml As String = ConfigManager.GetConfig(ddlName.SelectedValue, ver, modeID, configTypeID)

        If (Not String.IsNullOrEmpty(xml)) Then
            txtXML.Visible = True
            btnSave.Visible = True
            txtXML.Text = xml
        Else
            notMain.Notifications.AddWithMessage("That Config Does Not Exist!", NotificationType.Warning)
            txtXML.Text = String.Empty
            txtXML.Visible = False
            btnSave.Visible = False
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim modeID As Int32
        Dim configTypeID As Int32
        Dim ver As Version
        Int32.TryParse(ddlMode.SelectedValue, modeID)
        Int32.TryParse(ddlType.SelectedValue, configTypeID)
        ver = New Version(ddlVersions.SelectedValue)

        If (ConfigManager.SaveConfig(ddlName.SelectedValue, ver, modeID, configTypeID, txtXML.Text)) Then
            notMain.Notifications.AddWithMessage("Successfully Saved.", NotificationType.Information)
            txtXML.Text = String.Empty
            txtXML.Visible = False
            btnSave.Visible = False
        Else
            notMain.Notifications.AddWithMessage("The Config Did Not Save!", NotificationType.Errors)
        End If
    End Sub
End Class