Imports Remi.Bll
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Contracts

Public Class Admin_Lookups
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsAdmin Then
                Response.Redirect("~/")
            End If

            ddlLookupList.DataSource = (From l In New REMI.Dal.Entities().Instance().LookupTypes Select l.Name).OrderBy(Function(l) l)
            ddlLookupList.DataBind()


            gdvTargetAccess.DataSource = (From ta In New REMI.Dal.Entities().Instance.TargetAccesses Select ta).ToList()
            gdvTargetAccess.DataBind()

            ApplicationBindData()
        End If
        BindLookups(ddlLookupList.SelectedValue, 1)
    End Sub

    Protected Sub SetGvwHeader() Handles gdvTargetAccess.PreRender
        Helpers.MakeAccessable(gdvTargetAccess)
    End Sub

    Protected Sub SetGvwHeaderLookups() Handles gdvLookups.PreRender
        Helpers.MakeAccessable(gdvLookups)
    End Sub

    Protected Sub SetGvwApplicationsHeader() Handles gdvApplications.PreRender
        Helpers.MakeAccessable(gdvApplications)
    End Sub

    Protected Sub BindLookups(ByVal type As String, ByVal removeFirst As Int32)
        gdvLookups.DataSource = LookupsManager.GetLookups(type, 0, 0, removeFirst)
        gdvLookups.DataBind()
    End Sub

    Protected Sub gdvLookups_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        gdvLookups.EditIndex = e.NewEditIndex
        BindLookups(ddlLookupList.SelectedValue, 1)
        Dim lblParent As Label = gdvLookups.Rows(e.NewEditIndex).FindControl("lblParent")
        Dim ddlParentID As DropDownList = gdvLookups.Rows(e.NewEditIndex).FindControl("ddlParentID")
        Dim lblDescription As Label = gdvLookups.Rows(e.NewEditIndex).FindControl("lblDescription")
        Dim txtDescription As TextBox = gdvLookups.Rows(e.NewEditIndex).FindControl("txtDescription")
        Dim hdnParentID As HiddenField = gdvLookups.Rows(e.NewEditIndex).FindControl("hdnParentID")
        Dim chkActive As CheckBox = gdvLookups.Rows(e.NewEditIndex).FindControl("chkActive")

        ddlParentID.DataSource = LookupsManager.GetLookups(ddlLookupList.SelectedValue, 0, 0, 0)
        ddlParentID.DataBind()

        chkActive.Enabled = True
        lblDescription.Visible = False
        lblParent.Visible = False
        txtDescription.Visible = True
        ddlParentID.Visible = True
        ddlParentID.SelectedValue = hdnParentID.Value
    End Sub

    Protected Sub gdvLookups_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        gdvLookups.EditIndex = -1
        BindLookups(ddlLookupList.SelectedValue, 1)
    End Sub

    Protected Sub gdvLookups_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtDescription As TextBox = gdvLookups.Rows(e.RowIndex).FindControl("txtDescription")
        Dim ddlParentID As DropDownList = gdvLookups.Rows(e.RowIndex).FindControl("ddlParentID")
        Dim chkActive As CheckBox = gdvLookups.Rows(e.RowIndex).FindControl("chkActive")
        Dim active As Int32 = 1
        Dim parentID As Int32 = 0

        If (Not Request.Form(chkActive.UniqueID) = "on") Then
            active = 0
        End If

        Int32.TryParse(Request.Form(ddlParentID.UniqueID), parentID)

        LookupsManager.SaveLookup(ddlLookupList.SelectedValue, gdvLookups.DataKeys(e.RowIndex).Values(0), active, Request.Form(txtDescription.UniqueID), parentID)
        gdvLookups.EditIndex = -1
        BindLookups(ddlLookupList.SelectedValue, 1)
    End Sub

    Protected Sub gdvApplications_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        gdvApplications.EditIndex = e.NewEditIndex
        ApplicationBindData()

        Dim lblVersion As Label = gdvApplications.Rows(e.NewEditIndex).FindControl("lblVersion")
        Dim txtVersion As TextBox = gdvApplications.Rows(e.NewEditIndex).FindControl("txtVersion")
        Dim chkATA As CheckBox = gdvApplications.Rows(e.NewEditIndex).FindControl("chkATA")

        lblVersion.Visible = False
        txtVersion.Visible = True
        chkATA.Enabled = True
    End Sub

    Protected Sub gdvApplications_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        gdvApplications.EditIndex = -1
        ApplicationBindData()
    End Sub

    Protected Sub ApplicationBindData()
        gdvApplications.DataSource = (From a In New REMI.Dal.Entities().Instance.ApplicationVersions.Include("Application") Order By a.Application.ApplicationName Select New With {.ID = a.Application.ID, .ApplicationName = a.Application.ApplicationName, .VersionNumber = a.VerNum, .ApplicableToAll = a.ApplicableToAll}).ToList()
        gdvApplications.DataBind()
    End Sub

    Protected Sub gdvApplications_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim lblVersion As Label = gdvApplications.Rows(e.RowIndex).FindControl("lblVersion")
        Dim txtVersion As TextBox = gdvApplications.Rows(e.RowIndex).FindControl("txtVersion")
        Dim chkATA As CheckBox = gdvApplications.Rows(e.RowIndex).FindControl("chkATA")
        Dim applicableToAll As Int32 = 0

        If (Request.Form(chkATA.UniqueID) = "on") Then
            applicableToAll = 1
        End If

        VersionManager.SaveVersion(gdvApplications.DataKeys(e.RowIndex).Values(0), txtVersion.Text, applicableToAll)
        gdvApplications.EditIndex = -1
        ApplicationBindData()
    End Sub

    Protected Sub gdvTargetAccess_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "deleteitem"
                TargetAccessManager.DeleteTargetAccess(Convert.ToInt32(e.CommandArgument))
                gdvTargetAccess.DataSource = (From ta In New REMI.Dal.Entities().Instance.TargetAccesses Select ta).ToList()
                gdvTargetAccess.DataBind()
        End Select
    End Sub

    Protected Sub chkDenyAccess_OnCheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim chk As CheckBox = DirectCast(sender, CheckBox)
        Dim selRowIndex As Int32 = DirectCast(chk.Parent.Parent, GridViewRow).RowIndex
        Dim id As Int32 = gdvTargetAccess.DataKeys(selRowIndex).Values(0)

        TargetAccessManager.ChangeAccess(id, chk.Checked)
        gdvTargetAccess.DataSource = (From ta In New REMI.Dal.Entities().Instance.TargetAccesses Select ta).ToList()
        gdvTargetAccess.DataBind()
    End Sub

    Protected Sub lnkAddLookupAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddLookupAction.Click
        Dim value As String = Request.Form(gdvLookups.FooterRow.FindControl("txtValue").UniqueID)
        Dim description As String = Request.Form(gdvLookups.FooterRow.FindControl("txtDescription").UniqueID)
        Dim parentID As Int32 = 0
        Int32.TryParse(Request.Form(gdvLookups.FooterRow.FindControl("ddlFooterParentID").UniqueID), parentID)

        REMI.Bll.LookupsManager.SaveLookup(ddlLookupList.SelectedItem.Value, value, 1, description, parentID)
        Response.Redirect("/Admin/Lookups.aspx")
    End Sub

    Protected Sub btnAddTarget_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim target As String = Request.Form(gdvTargetAccess.FooterRow.FindControl("txtTargetName").UniqueID)
        Dim workstation As String = Request.Form(gdvTargetAccess.FooterRow.FindControl("txtWorkStationname").UniqueID)
        Dim deny As String = Request.Form(gdvTargetAccess.FooterRow.FindControl("chkDeny").UniqueID)
        Dim isDeny As Boolean = False

        If (deny = "on") Then
            isDeny = True
        End If

        TargetAccessManager.AddTargetAccess(target, workstation, isDeny)
        gdvTargetAccess.DataSource = (From ta In New REMI.Dal.Entities().Instance.TargetAccesses Select ta).ToList()
        gdvTargetAccess.DataBind()
    End Sub
End Class