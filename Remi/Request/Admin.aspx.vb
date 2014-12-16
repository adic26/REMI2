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

            hdnRequestType.Value = requestType
            hdnRequestTypeID.Value = requestTypeID

            If (requestTypeID > 0 And requestType.Trim().Length > 0) Then
                BindRequest()
            Else
                Response.Redirect("~/Request/Default.aspx", True)
            End If

            lblRequest.Text = String.Format("Administrate {0}", requestType)
        End If
    End Sub
#End Region

#Region "Methods"
    Protected Sub SetGvwHeader() Handles grdRequestAdmin.PreRender
        Helpers.MakeAccessable(grdRequestAdmin)
    End Sub

    Protected Sub BindRequest()
        grdRequestAdmin.DataSource = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, True, String.Empty)
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

        RequestManager.SaveFieldSetup(hdnRequestTypeID.Value, -1, name, fieldTypeID, fieldValidationID, isRequired, isArchived, optionsTypeID, category, parentFieldID, True, intField, description)

        BindRequest()
    End Sub
#End Region

#Region "Events"
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

                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim rf As REMI.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = fieldID Select f).FirstOrDefault()
                    Dim nextrf As REMI.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = nextFieldID Select f).FirstOrDefault()

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

                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim rf As REMI.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = fieldID Select f).FirstOrDefault()
                    Dim nextrf As REMI.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.ReqFieldSetupID = nextFieldID Select f).FirstOrDefault()

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

        Dim lblName As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblName")
        Dim lblDescription As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblDescription")
        Dim lblFieldType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblFieldType")
        Dim lblValidationType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblValidationType")
        Dim lblOptionsType As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblOptionsType")
        Dim lblCategory As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblCategory")
        Dim lblParentField As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblParentField")
        Dim lblIntField As Label = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("lblIntField")

        Dim hdnFieldTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnFieldTypeID")
        Dim hdnValidationTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnValidationTypeID")
        Dim hdnOptionsTypeID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnOptionsTypeID")
        Dim hdnParentFieldID As HiddenField = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("hdnParentFieldID")

        Dim ddlIntField As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlIntField")
        Dim ddlParentField As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlParentField")
        Dim ddlFieldType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlFieldType")
        Dim ddlValidationType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlValidationType")
        Dim ddlOptionsType As DropDownList = grdRequestAdmin.Rows(e.NewEditIndex).FindControl("ddlOptionsType")
        ddlFieldType.SelectedValue = hdnFieldTypeID.Value
        ddlValidationType.SelectedValue = hdnValidationTypeID.Value
        ddlOptionsType.SelectedValue = hdnOptionsTypeID.Value
        ddlIntField.SelectedValue = lblIntField.Text
        ddlParentField.SelectedValue = hdnParentFieldID.Value

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

        txtName.Visible = True
        txtCategory.Visible = True
        txtDescription.Visible = True

        ddlIntField.Visible = True
        ddlParentField.Visible = True
        ddlValidationType.Visible = True
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

        RequestManager.SaveFieldSetup(hdnRequestTypeID.Value, fieldSetupID, txtName.Text, fieldTypeID, fieldValidationID, chkIsRequired.Checked, chkArchived.Checked, optionsTypeID, txtCategory.Text, parentFieldID, chkIntegrated.Checked, ddlIntField.SelectedValue, txtDescription.Text)
        grdRequestAdmin.EditIndex = -1
        BindRequest()
    End Sub
#End Region
End Class