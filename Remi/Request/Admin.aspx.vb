Imports Remi.Bll
Imports Remi.Validation
Imports Remi.Contracts
Imports Remi.BusinessEntities

Public Class ReqAdmin
    Inherits System.Web.UI.Page

#Region "Page_Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            Dim requestType As String = IIf(Request.QueryString.Item("rt") Is Nothing, String.Empty, Request.QueryString.Item("rt"))
            Dim requestTypeID As String = IIf(Request.QueryString.Item("id") Is Nothing, 0, Request.QueryString.Item("id"))

            If ((From dr As DataRow In UserManager.GetCurrentUser.RequestTypes.Rows Where dr.Field(Of Boolean)("IsAdmin") = True And dr.Field(Of Int32)("RequestTypeID") = requestTypeID).FirstOrDefault() Is Nothing) Then
                Response.Redirect("~/Request/Default.aspx", True)
            Else
                hdnRequestType.Value = requestType
                hdnRequestTypeID.Value = requestTypeID

                lblRequest.Text = String.Format("Administrate {0}", requestType)
            End If

            If (requestTypeID > 0 And requestType.Trim().Length > 0) Then
                BindRequest()
            Else
                Response.Redirect("~/Request/Default.aspx", True)
            End If
        End If
    End Sub
#End Region

#Region "Methods"
    Protected Sub SetGvwHeader() Handles grdRequestAdmin.PreRender
        Helpers.MakeAccessable(grdRequestAdmin)
    End Sub

    Protected Sub BindRequest()
        grdRequestAdmin.DataSource = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, chkArchived.Checked, String.Empty)
        grdRequestAdmin.DataBind()
    End Sub
#End Region

#Region "Save"
    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim parentFieldID As Int32
        Dim fieldTypeID As Int32
        Dim fieldValidationID As Int32
        Dim optionsTypeID As Int32
        Dim name As String = Request.Form(grdRequestAdmin.FooterRow.FindControl("txtNewName").UniqueID)
        Dim description As String = Request.Form(grdRequestAdmin.FooterRow.FindControl("txtNewDescription").UniqueID)
        Dim category As String = Request.Form(grdRequestAdmin.FooterRow.FindControl("txtNewCategory").UniqueID)
        Dim intField As String = Request.Form(grdRequestAdmin.FooterRow.FindControl("ddlNewIntField").UniqueID)
        Dim isRequired As Boolean = False
        Dim isArchived As Boolean = False

        Int32.TryParse(Request.Form(grdRequestAdmin.FooterRow.FindControl("ddlNewParentField").UniqueID), parentFieldID)
        Int32.TryParse(Request.Form(grdRequestAdmin.FooterRow.FindControl("ddlNewFieldType").UniqueID), fieldTypeID)
        Int32.TryParse(Request.Form(grdRequestAdmin.FooterRow.FindControl("ddlNewValidationType").UniqueID), fieldValidationID)
        Int32.TryParse(Request.Form(grdRequestAdmin.FooterRow.FindControl("ddlNewOptionsType").UniqueID), optionsTypeID)

        If (Request.Form(grdRequestAdmin.FooterRow.FindControl("chkNewIsRequired").UniqueID) = "on") Then
            isRequired = True
        End If

        If (Request.Form(grdRequestAdmin.FooterRow.FindControl("chkNewArchived").UniqueID) = "on") Then
            isArchived = True
        End If

        RequestManager.SaveFieldSetup(hdnRequestTypeID.Value, -1, name, fieldTypeID, fieldValidationID, isRequired, isArchived, optionsTypeID, category, parentFieldID, True, intField, description, String.Empty)

        BindRequest()
    End Sub
#End Region

#Region "Events"
    Protected Sub chkArchived_CheckedChanged(sender As Object, e As EventArgs)
        BindRequest()
    End Sub

    Protected Sub grdRequestAdmin_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles grdRequestAdmin.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim archived As Boolean = False

            If (DataBinder.Eval(e.Row.DataItem, "IsArchived") IsNot Nothing) Then
                Boolean.TryParse(DataBinder.Eval(e.Row.DataItem, "IsArchived").ToString(), archived)
            End If

            If (archived) Then
                e.Row.BackColor = Drawing.Color.Yellow
            End If
        End If
    End Sub

    Protected Sub grdRequestAdmin_RowDataCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Dim index As Integer = 0

        Select Case e.CommandName
            Case "Up"
                index = Convert.ToInt32(e.CommandArgument)

                If (index - 1 > -1) Then
                    Dim fieldID As Int32 = 0
                    Dim nextFieldID As Int32 = 0
                    Dim displayOrder As Int32 = -1
                    Dim nextDisplayOrder As Int32 = -1
                    Int32.TryParse(grdRequestAdmin.DataKeys(index).Values(0).ToString(), fieldID)
                    Int32.TryParse(grdRequestAdmin.DataKeys(index - 1).Values(0).ToString(), nextFieldID)

                    Dim instance = New Remi.Dal.Entities().Instance()

                    Dim rf As Remi.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = fieldID Select f).FirstOrDefault()
                    Dim nextrf As Remi.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = nextFieldID Select f).FirstOrDefault()

                    If (rf IsNot Nothing) Then
                        displayOrder = rf.DisplayOrder
                    End If

                    If (nextrf IsNot Nothing) Then
                        nextDisplayOrder = nextrf.DisplayOrder
                        rf.DisplayOrder = nextDisplayOrder
                        nextrf.DisplayOrder = displayOrder
                    End If

                    instance.SaveChanges()

                    BindRequest()
                End If
            Case "Down"
                index = Convert.ToInt32(e.CommandArgument)

                If (index + 1 < grdRequestAdmin.Rows.Count) Then
                    Dim fieldID As Int32 = 0
                    Dim nextFieldID As Int32 = 0
                    Dim displayOrder As Int32 = -1
                    Dim nextDisplayOrder As Int32 = -1
                    Int32.TryParse(grdRequestAdmin.DataKeys(index).Values(0).ToString(), fieldID)
                    Int32.TryParse(grdRequestAdmin.DataKeys(index + 1).Values(0).ToString(), nextFieldID)

                    Dim instance = New Remi.Dal.Entities().Instance()

                    Dim rf As Remi.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = fieldID Select f).FirstOrDefault()
                    Dim nextrf As Remi.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = nextFieldID Select f).FirstOrDefault()

                    If (rf IsNot Nothing) Then
                        displayOrder = rf.DisplayOrder
                    End If

                    If (nextrf IsNot Nothing) Then
                        nextDisplayOrder = nextrf.DisplayOrder
                        rf.DisplayOrder = nextDisplayOrder
                        nextrf.DisplayOrder = displayOrder
                    End If

                    instance.SaveChanges()

                    BindRequest()
                End If
        End Select
    End Sub

    Protected Sub grdRequestAdmin_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdRequestAdmin.EditIndex = e.NewEditIndex
        BindRequest()

        Dim requestTypeID As Int32
        Int32.TryParse(hdnRequestTypeID.Value, requestTypeID)

        Dim lblName As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblName")
        Dim lblDescription As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblDescription")
        Dim lblFieldType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblFieldType")
        Dim lblValidationType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblValidationType")
        Dim lblOptionsType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblOptionsType")
        Dim lblCategory As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblCategory")
        Dim lblParentField As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblParentField")
        Dim lblIntField As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblIntField")
        Dim lblDefaultValue As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblDefaultValue")

        Dim hdnFieldTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnFieldTypeID")
        Dim hdnValidationTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnValidationTypeID")
        Dim hdnOptionsTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnOptionsTypeID")
        Dim hdnParentFieldID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnParentFieldID")
        Dim hdnOptionsDefault As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnOptionsDefault")

        Dim ddlIntField As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlIntField")
        Dim ddlParentField As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlParentField")
        Dim ddlFieldType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlFieldType")
        Dim ddlValidationType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlValidationType")
        Dim ddlOptionsType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlOptionsType")
        Dim ddlDefaultValue As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlDefaultValue")

        ddlDefaultValue.DataSource = LookupsManager.GetLookups(lblOptionsType.Text, 0, 0, String.Empty, String.Empty, requestTypeID, False)
        ddlDefaultValue.DataBind()

        ddlFieldType.SelectedValue = hdnFieldTypeID.Value
        ddlValidationType.SelectedValue = hdnValidationTypeID.Value
        ddlOptionsType.SelectedValue = hdnOptionsTypeID.Value
        ddlIntField.SelectedValue = lblIntField.Text
        ddlParentField.SelectedValue = hdnParentFieldID.Value
        ddlDefaultValue.SelectedValue = ddlDefaultValue.Items.FindByText(hdnOptionsDefault.Value).Value

        Dim txtName As TextBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("txtName")
        Dim txtDescription As TextBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("txtDescription")
        Dim txtCategory As TextBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("txtCategory")
        Dim chkIsRequired As CheckBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("chkIsRequired")
        Dim chkArchived As CheckBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("chkArchived")
        Dim chkIntegrated As CheckBox = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("chkIntegrated")

        lblIntField.Visible = False
        lblName.Visible = False
        lblFieldType.Visible = False
        lblValidationType.Visible = False
        lblOptionsType.Visible = False
        lblCategory.Visible = False
        lblParentField.Visible = False
        lblDescription.Visible = False
        lblDefaultValue.Visible = False

        txtName.Visible = True
        txtCategory.Visible = True
        txtDescription.Visible = True

        ddlIntField.Visible = True
        ddlParentField.Visible = True
        ddlValidationType.Visible = True
        ddlDefaultValue.Visible = True
        ddlFieldType.Visible = True
        ddlOptionsType.Visible = True
        chkArchived.Enabled = True
        chkIsRequired.Enabled = True
        chkIntegrated.Enabled = True
    End Sub

    Protected Sub grdRequestAdmin_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdRequestAdmin.EditIndex = -1
        BindRequest()
    End Sub

    Protected Sub grdRequestAdmin_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtName As TextBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("txtName")
        Dim txtDescription As TextBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("txtDescription")
        Dim txtCategory As TextBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("txtCategory")
        Dim chkIsRequired As CheckBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("chkIsRequired")
        Dim chkArchived As CheckBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("chkArchived")
        Dim chkIntegrated As CheckBox = grdRequestAdmin.Rows(e.RowIndex).FindControl("chkIntegrated")

        Dim ddlIntField As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlIntField")
        Dim ddlParentField As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlParentField")
        Dim ddlFieldType As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlFieldType")
        Dim ddlValidationType As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlValidationType")
        Dim ddlOptionsType As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlOptionsType")
        Dim ddlDefaultValue As DropDownList = grdRequestAdmin.Rows(e.RowIndex).FindControl("ddlDefaultValue")

        Dim parentFieldID As Int32
        Dim fieldTypeID As Int32
        Dim fieldValidationID As Int32
        Dim optionsTypeID As Int32
        Dim fieldSetupID As Int32
        Int32.TryParse(ddlParentField.SelectedValue, parentFieldID)
        Int32.TryParse(ddlFieldType.SelectedValue, fieldTypeID)
        Int32.TryParse(ddlValidationType.SelectedValue, fieldValidationID)
        Int32.TryParse(ddlOptionsType.SelectedValue, optionsTypeID)
        Int32.TryParse(grdRequestAdmin.DataKeys(e.RowIndex).Values(0), fieldSetupID)

        RequestManager.SaveFieldSetup(hdnRequestTypeID.Value, fieldSetupID, txtName.Text, fieldTypeID, fieldValidationID, chkIsRequired.Checked, chkArchived.Checked, optionsTypeID, txtCategory.Text, parentFieldID, chkIntegrated.Checked, ddlIntField.SelectedValue, txtDescription.Text, ddlDefaultValue.SelectedItem.Text)
        grdRequestAdmin.EditIndex = -1
        BindRequest()
    End Sub

    Protected Sub chkFilter_CheckedChanged(sender As Object, e As EventArgs)
        If (DirectCast(sender, CheckBox).Checked) Then
            pnlFilter.Visible = True

            ddlParentType.DataSource = LookupsManager.GetLookupTypes()
            ddlParentType.DataBind()

            ddlChildType.DataSource = LookupsManager.GetLookupTypes()
            ddlChildType.DataBind()
        Else
            pnlFilter.Visible = False

            ddlParentType.DataSource = Nothing
            ddlParentType.DataBind()

            cblParent.Items.Clear()

            ddlChildType.DataSource = Nothing
            ddlChildType.DataBind()

            cblChild.Items.Clear()
        End If
    End Sub

    Protected Sub ddlParentType_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim ddl As DropDownList = DirectCast(sender, DropDownList)

        cblParent.DataSource = LookupsManager.GetLookups(ddl.SelectedItem.Text, -1, -1, String.Empty, String.Empty, -1, False, 1)
        cblParent.DataBind()

        ddlChildType.DataSource = LookupsManager.GetLookupTypes()
        ddlChildType.DataBind()
        cblChild.Items.Clear()

        cblParent.Enabled = False
    End Sub

    Protected Sub ddlChildType_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim ddl As DropDownList = DirectCast(sender, DropDownList)

        If (ddl.SelectedItem.Value = 0) Then
            cblChild.Items.Clear()
            cblParent.Enabled = False
        Else
            cblChild.DataSource = LookupsManager.GetLookups(ddl.SelectedItem.Text, -1, -1, String.Empty, String.Empty, -1, True, 0)
            cblChild.DataBind()
            cblParent.Enabled = True
        End If
    End Sub

    Protected Sub cblChild_SelectedIndexChanged(sender As Object, e As EventArgs)
        LookupsManager.SaveLookupHierarchy(ddlParentType.SelectedItem.Value, ddlChildType.SelectedItem.Value, cblParent.SelectedItem.Value, hdnRequestTypeID.Value, cblChild.Items)
    End Sub

    Protected Sub cblParent_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim cbl As CheckBoxList = DirectCast(sender, CheckBoxList)

        If (cbl.SelectedItem Is Nothing) Then
            cblChild.DataSource = LookupsManager.GetLookups(ddlChildType.SelectedItem.Text, -1, -1, String.Empty, String.Empty, -1, True, 0)
            cblChild.DataBind()
        Else
            Dim requestTypeID As Int32
            Int32.TryParse(hdnRequestTypeID.Value, requestTypeID)
            Dim selectedText As String = cbl.SelectedItem.Text

            For Each rec In (From item In cbl.Items.Cast(Of ListItem)() Where item.Selected = True Select item).ToList()
                If (rec.Text <> selectedText) Then
                    cbl.Items.FindByValue(rec.Value).Selected = False
                End If
            Next

            Dim dtLookups As DataTable = LookupsManager.GetLookups(ddlChildType.SelectedItem.Text, -1, -1, ddlParentType.SelectedItem.Text, cbl.SelectedItem.Text, requestTypeID, True, 0)
            cblChild.DataSource = dtLookups
            cblChild.DataBind()

            For Each item As ListItem In cblChild.Items
                item.Selected = (From t As DataRow In dtLookups.Rows Where t.Field(Of Int32)("LookupID") = item.Value Select t.Field(Of Int32)("RequestAssigned")).FirstOrDefault()
            Next
        End If
    End Sub
#End Region

End Class