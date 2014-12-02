Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts
Imports Remi.Core
Imports System.IO

Partial Class ManageProducts_EditProductConfig
    Inherits System.Web.UI.Page

    Protected isEditMode As Boolean
    Dim dtConfig As DataTable = LookupsManager.GetLookups("Configuration", 0, 0, String.Empty, String.Empty, 0, 0)

#Region "Page Events"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim productID As String = Request.QueryString.Get("Product")
        Dim id As Int32
        Int32.TryParse(productID, id)
        Dim test As String = Request(ddlTests.UniqueID)
        txtXMLDisplay.Visible = False
        lblXMLTitle.Visible = False
        lblPCName.Visible = False
        txtPCName.Visible = False
        btnAddNode.Visible = False
        ddlTests.Items.Clear()
        Dim tests As List(Of Test) = TestManager.GetTestsByType(TestType.Parametric, False)
        tests.Insert(0, New Test())
        ddlTests.DataSource = tests
        ddlTests.DataValueField = "ID"
        ddlTests.DataTextField = "Name"
        ddlTests.DataBind()
        pnlOverAll.Visible = False
        ddlProductConfig.Visible = pnlOverAll.Visible
        lblConfigs.Visible = pnlOverAll.Visible
        btnUploadNew.Visible = pnlOverAll.Visible

        If (String.IsNullOrEmpty(productID)) Then
            ddlTests.Visible = False
            lvlTests.Visible = False
        End If
        Dim productName As String = ProductGroupManager.GetProductNameByID(id)
        lblProductName.Text = "Edit " + productName + " Configuration"

        If (Me.IsPostBack) Then
            hdnProductID.Value = id
            hypCancel.NavigateUrl = REMIWebLinks.GetProductInfoLink(id)
            hypRefresh.NavigateUrl = REMIWebLinks.GetSetProductConfigurationLink(id)
            pnlLeftMenuActions.Visible = True
            hdnTestID.Value = test

            If (Not (String.IsNullOrEmpty(productName)) And Not (String.IsNullOrEmpty(test))) Then
                ddlProductConfig.DataSource = (From pc In New REMI.Dal.Entities().Instance().ProductConfigurationUploads Where pc.Test.ID = hdnTestID.Value And pc.Product.ID = id Select New With {.PCName = pc.PCName, .PCID = pc.ID}).ToList
                ddlProductConfig.DataBind()

                Dim pcID As Int32

                If (Not (String.IsNullOrEmpty(Request(ddlProductConfig.UniqueID))) And ddlProductConfig.Items.FindByValue(Request(ddlProductConfig.UniqueID)) IsNot Nothing) Then
                    ddlProductConfig.SelectedValue = Request(ddlProductConfig.UniqueID)
                    pcID = Request(ddlProductConfig.UniqueID)
                ElseIf (ddlProductConfig.Items.FindByValue(ddlProductConfig.SelectedValue) IsNot Nothing) Then
                    pcID = ddlProductConfig.SelectedValue
                End If

                If (ddlProductConfig.Items.Count = 0) Then
                    btnUploadNew.Visible = False
                    ddlProductConfig.Visible = False
                    lblConfigs.Visible = False
                Else
                    btnUploadNew.Visible = True
                    ddlProductConfig.Visible = True
                    lblConfigs.Visible = True
                End If

                txtXMLDisplay.TextMode = TextBoxMode.MultiLine
                txtXMLDisplay.Rows = 20
                txtXMLDisplay.Columns = 60
                pnlOverAll.Visible = True
                txtXMLDisplay.ReadOnly = pnlOverAll.Visible
                txtXMLDisplay.Visible = pnlOverAll.Visible
                lblXMLTitle.Visible = pnlOverAll.Visible
                txtPCName.Visible = False
                lblPCName.Visible = False

                Dim record = (From r In New REMI.Dal.Entities().Instance().ProductConfigurationUploads Where r.Test.ID = hdnTestID.Value And r.Product.ID = id And r.IsProcessed = 0 And r.ID = pcID Select r)

                If (record.Count > 0) Then
                    btnCopyFrom.Visible = False
                    pnlOverAll.Visible = False
                    ddlProductConfig.Visible = False
                    lblConfigs.Visible = False
                    btnUploadNew.Visible = False
                    lblXMLTitle.Visible = pnlOverAll.Visible
                    txtPCName.Visible = False
                    lblPCName.Visible = False
                    txtXMLDisplay.Visible = pnlOverAll.Visible
                    lblProcessing.Visible = True

                    If (DateTime.Now.Hour.Equals(13)) Then
                        btnProcessPendingXML.Visible = False
                    Else
                        btnProcessPendingXML.Visible = True
                    End If

                    btnUpload.Visible = pnlOverAll.Visible
                    lblMissingConfiguration2.Visible = pnlOverAll.Visible
                    lblMissingConfiguration.Visible = pnlOverAll.Visible
                    ddlCopyFrom.Visible = pnlOverAll.Visible
                Else
                    lblProcessing.Visible = False
                    btnProcessPendingXML.Visible = False
                    Dim notValidBindControls As String() = New String() {"btnEditMode", "btnViewMode", "btnUpdate", "btnSave", "btnAddDetail", "btnAddNode", "btnSaveNode", "btnDeleteSub", "imgDeleteRow", "btnUpload"}
                    If (REMI.Helpers.GetPostBackControl(Me.Page) IsNot Nothing) Then
                        If (Not (notValidBindControls.Contains(REMI.Helpers.GetPostBackControl(Me.Page).ID))) Then
                            btnAddNode.Visible = pnlOverAll.Visible
                            pnlAddNode.CssClass = "hidden"
                            BindData()
                        End If
                    End If
                End If
            Else
                txtXMLDisplay.Text = String.Empty
            End If

            If (Not (String.IsNullOrEmpty(test))) Then
                ddlTests.Items.FindByValue(test).Selected = True
            End If
        End If
    End Sub

    Protected Sub SetGvwHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        Helpers.MakeAccessable(grdvProductConfig)
        Helpers.MakeAccessable(grdvVersions)
        Helpers.MakeAccessable(grdVersion)
    End Sub
#End Region

#Region "Methods"
    <System.Web.Services.WebMethod()> _
    Public Shared Function AddRowDetail(ByVal pcID As Int32, ByVal lookupText As String, ByVal lookupID As Int32, ByVal isAttribute As Boolean, ByVal lookupAlt As String) As String
        ProductGroupManager.SaveProductConfigurationDetails(pcID, 0, lookupID, lookupText, UserManager.GetCurrentValidUserLDAPName, isAttribute, lookupAlt)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteConfig(ByVal configID As Int32) As String
        Dim success As Boolean = ProductGroupManager.DeleteProductConfigurationDetail(configID, UserManager.GetCurrentValidUserLDAPName)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteAll(ByVal pcUID As Int32) As String
        Dim success As Boolean = ProductGroupManager.DeleteProductConfiguration(pcUID, UserManager.GetCurrentValidUserLDAPName)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteRow(ByVal pcID As Int32) As String
        Dim success As Boolean = ProductGroupManager.DeleteProductConfigurationHeader(pcID, UserManager.GetCurrentValidUserLDAPName)

        Return String.Empty
    End Function

    Private Sub BindData()
        Dim pcID As Int32

        If (Not (String.IsNullOrEmpty(Request(ddlProductConfig.UniqueID))) And ddlProductConfig.Items.FindByValue(Request(ddlProductConfig.UniqueID)) IsNot Nothing) Then
            ddlProductConfig.SelectedValue = Request(ddlProductConfig.UniqueID)
            pcID = Request(ddlProductConfig.UniqueID)
        ElseIf (ddlProductConfig.Items.FindByValue(ddlProductConfig.SelectedValue) IsNot Nothing) Then
            pcID = ddlProductConfig.SelectedValue
        End If

        Dim dt As DataTable = ProductGroupManager.GetProductConfigurationHeader(pcID)
        Dim xml As XDocument = ProductGroupManager.GetProductConfigurationXML(pcID)


        If (dt.Rows.Count = 0) Then
            Dim dtSimilar As DataTable = ProductGroupManager.GetSimilarTestConfigurations(Convert.ToInt32(hdnProductID.Value), hdnTestID.Value)
            ddlCopyFrom.DataSource = dtSimilar
            ddlCopyFrom.DataBind()
            txtXMLDisplay.Visible = False
            lblXMLTitle.Visible = False
            lblPCName.Visible = True
            txtPCName.Visible = True

            If (dtSimilar.Rows.Count > 0) Then
                ddlCopyFrom.Visible = True
                btnCopyFrom.Visible = True
                lblMissingConfiguration.Visible = True
            Else
                ddlCopyFrom.Visible = False
                lblMissingConfiguration.Visible = False
                btnCopyFrom.Visible = False
            End If

            btnAddNode.Visible = False
            lblMissingConfiguration2.Visible = True
            txtXMLDisplay.Visible = True
            txtXMLDisplay.ReadOnly = False
            btnUpload.Visible = True
            btnDeleteAll.Visible = False
        Else
            btnAddNode.Visible = True
            btnEditMode.Visible = True
            btnViewMode.Visible = True

            txtXMLDisplay.Text = xml.ToString()
            lblXMLTitle.Visible = True
            txtXMLDisplay.Visible = True
            ddlCopyFrom.Visible = False
            lblMissingConfiguration.Visible = False
            lblMissingConfiguration2.Visible = False
            btnUpload.Visible = False
            btnCopyFrom.Visible = False
            txtPCName.Visible = False
            lblPCName.Visible = False
        End If

        grdvProductConfig.DataSource = dt
        grdvProductConfig.AutoGenerateColumns = False
        grdvProductConfig.DataBind()

        VersionBindData(pcID)

        grdVersion.DataSource = (From pcv In New Remi.Dal.Entities().Instance().ProductConfigurationVersions Where pcv.ProductConfigurationUpload.ID = pcID Select pcv.VersionNum, pcv.PCXML).ToList()
        grdVersion.DataBind()

        If (grdvProductConfig.Rows.Count = 0) Then
            btnViewMode.Visible = False
            btnEditMode.Visible = False
            btnUpdate.Visible = False
            txtXMLDisplay.Text = String.Empty

        Else
            btnViewMode.Visible = True
            btnEditMode.Visible = True
            btnUpdate.Visible = IsInEditMode
            btnDeleteAll.Attributes.Add("onclick", "javascript: deleteAllNodes('" & Convert.ToInt32(ddlProductConfig.SelectedValue) & "');")

            If (UserManager.GetCurrentUser.IsAdmin) Then
                btnDeleteAll.Visible = True
            Else
                btnDeleteAll.Visible = False
            End If
        End If

        If (isEditMode) Then
            btnEditMode.Enabled = False
            btnViewMode.Enabled = True
        End If

        If (Not (isEditMode)) Then
            btnEditMode.Enabled = True
            btnViewMode.Enabled = False
        End If
    End Sub
#End Region

#Region "Properties"
    Protected Property IsInEditMode() As Boolean
        Get
            Return Me.isEditMode
        End Get
        Set(value As Boolean)
            Me.isEditMode = value
        End Set
    End Property
#End Region

#Region "Button Clicks"
    Protected Sub btnUploadNew_OnClick(ByVal sender As Object, ByVal e As EventArgs)
        pnlOverAll.Visible = False
        lblXMLTitle.Visible = False
        txtPCName.Visible = True
        lblPCName.Visible = True
        txtXMLDisplay.Visible = True
        btnUpload.Visible = True
        txtXMLDisplay.Text = String.Empty
        txtXMLDisplay.ReadOnly = False
    End Sub

    Protected Sub btnProcessPendingXML_Click(sender As Object, e As EventArgs)
        ProductGroupManager.ProductConfigurationProcess()

        Response.Redirect(hypCancel.NavigateUrl)
    End Sub

    Protected Sub btnUpload_Click(sender As Object, e As EventArgs)
        If txtXMLDisplay.Text <> "" Then
            Try
                Dim xml As XDocument = XDocument.Parse(txtXMLDisplay.Text)

                ProductGroupManager.ProductConfigurationUpload(Convert.ToInt32(hdnProductID.Value), Convert.ToInt32(hdnTestID.Value), xml, UserManager.GetCurrentValidUserLDAPName, txtPCName.Text)
                lblProcessing.Visible = True

                If (DateTime.Now.Hour.Equals(1)) Then
                    btnProcessPendingXML.Visible = False
                Else
                    btnProcessPendingXML.Visible = True
                End If
            Catch ex As Exception
            End Try

            pnlOverAll.Visible = False
            lblXMLTitle.Visible = False
            txtPCName.Visible = False
            lblPCName.Visible = False
            txtXMLDisplay.Visible = False
            btnUpload.Visible = False
            lblMissingConfiguration2.Visible = False
            lblMissingConfiguration.Visible = False
            ddlCopyFrom.Visible = False
            btnCopyFrom.Visible = False
            txtXMLDisplay.Text = String.Empty
        End If
    End Sub

    Protected Sub btnEditMode_Click(ByVal sender As Object, ByVal e As EventArgs) Handles btnEditMode.Click
        IsInEditMode = True
        btnEditMode.Enabled = Not (IsInEditMode)
        btnViewMode.Enabled = IsInEditMode
        btnUpdate.Visible = IsInEditMode
        DirectCast(DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub

    Protected Sub btnViewMode_Click(sender As Object, e As EventArgs) Handles btnViewMode.Click
        IsInEditMode = False
        btnEditMode.Enabled = Not (IsInEditMode)
        btnViewMode.Enabled = IsInEditMode
        btnUpdate.Visible = IsInEditMode
        DirectCast(DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub

    Protected Sub btnCopyFrom_Click(sender As Object, e As EventArgs) Handles btnCopyFrom.Click
        Dim productID As Int32
        Dim copyFromproductID As Int32

        Int32.TryParse(hdnProductID.Value, productID)
        Int32.TryParse(Request.Form(ddlCopyFrom.UniqueID).ToString(), copyFromproductID)

        Dim success As Boolean = ProductGroupManager.CopyTestConfiguration(productID, hdnTestID.Value, copyFromproductID, UserManager.GetCurrentValidUserLDAPName)

        BindData()
    End Sub

    Protected Sub btnUpdate_Click(sender As Object, e As EventArgs) Handles btnUpdate.Click
        For Each row As GridViewRow In grdvProductConfig.Rows
            Dim parentID As Int32
            Dim lblConfigID As Int32
            Dim viewOrder As Int32
            Int32.TryParse(DirectCast(row.FindControl("lblConfigID"), Label).Text, lblConfigID)
            Int32.TryParse(Request.Form(DirectCast(row.FindControl("ddlParentNames"), DropDownList).UniqueID), parentID)
            Int32.TryParse(Request.Form(DirectCast(row.FindControl("txtViewOrder"), TextBox).UniqueID), viewOrder)
            Dim nodeName As String = Request.Form(DirectCast(row.FindControl("txtNodeName"), TextBox).UniqueID)

            Dim result As Boolean = ProductGroupManager.SaveProductConfiguration(lblConfigID, parentID, viewOrder, nodeName, UserManager.GetCurrentValidUserLDAPName, Convert.ToInt32(ddlProductConfig.SelectedValue))

            If (result) Then
                Dim gv As GridView = DirectCast(row.FindControl("grdvDetails"), GridView)
                If (gv.Rows.Count > 0) Then
                    For Each rowDetail As GridViewRow In gv.Rows
                        Dim ddlLookupID As Int32
                        Dim txtConfID As Int32
                        Dim isAttribute As Boolean = False

                        Dim txtLookupValue As String = Request.Form(DirectCast(DirectCast(rowDetail.Cells(2), System.Web.UI.WebControls.DataControlFieldCell).Parent, System.Web.UI.WebControls.GridViewRow).UniqueID + "$txtLookupValue")
                        Int32.TryParse(Request.Form(DirectCast(DirectCast(rowDetail.Cells(0), System.Web.UI.WebControls.DataControlFieldCell).Parent, System.Web.UI.WebControls.GridViewRow).UniqueID + "$txtConfID"), txtConfID)
                        Int32.TryParse(Request.Form(DirectCast(DirectCast(rowDetail.Cells(1), System.Web.UI.WebControls.DataControlFieldCell).Parent, System.Web.UI.WebControls.GridViewRow).UniqueID + "$ddlLookupID"), ddlLookupID)

                        If (Request.Form(DirectCast(DirectCast(rowDetail.Cells(1), System.Web.UI.WebControls.DataControlFieldCell).Parent, System.Web.UI.WebControls.GridViewRow).UniqueID + "$chkIsAttribute") = "on") Then
                            isAttribute = True
                        End If

                        Dim resultDetail As Boolean = ProductGroupManager.SaveProductConfigurationDetails(lblConfigID, txtConfID, ddlLookupID, txtLookupValue, UserManager.GetCurrentValidUserLDAPName, isAttribute, String.Empty)
                    Next
                End If
            End If
        Next

        Dim xml As String = ProductGroupManager.GetProductConfigurationXML(ddlProductConfig.SelectedValue).ToString()
        Dim saveXMLVersion As Boolean = ProductGroupManager.SaveProductConfigurationXMLVersion(xml, UserManager.GetCurrentValidUserLDAPName, ddlProductConfig.SelectedValue)

        BindData()
    End Sub

    Protected Sub btnAddNode_Click(sender As Object, e As EventArgs)
        DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("btnAddNode").Visible = False
        DirectCast(DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = ""

        Dim cmbParent As DropDownList = DirectCast(DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("ddlAddParentNames"), DropDownList)
        If cmbParent IsNot Nothing Then
            Dim list = ((From dt1 In ProductGroupManager.GetProductConfigurationHeader(Convert.ToInt32(ddlProductConfig.SelectedValue)).AsEnumerable() _
                                                  Select New With { _
                                                      .ParentName = dt1.Field(Of String)("NodeName") + " " + dt1.Field(Of Int32)("ViewOrder").ToString(), _
                                                      .ParentID = dt1.Field(Of Int32)("ID") _
                                                      } _
                                                    ).Union(From t In New String() {String.Empty} Select New With {.ParentName = String.Empty, .ParentID = 0})).OrderBy(Function(p) p.ParentName + " ")

            cmbParent.DataSource = list
            cmbParent.DataBind()

            If (cmbParent.Items.Count = 0) Then
                btnEditMode.Visible = False
                btnViewMode.Visible = False
            End If
        End If
    End Sub

    Protected Sub btnSaveNode_Click(sender As Object, e As EventArgs)
        Dim parentID As Int32
        Dim viewOrder As Int32
        Dim nodeName As String

        nodeName = Request.Form(Remi.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("txtAddNodeName").UniqueID)
        Int32.TryParse(Request.Form(Remi.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("txtAddViewOrder").UniqueID), viewOrder)
        Int32.TryParse(Request.Form(Remi.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("ddlAddParentNames").UniqueID), parentID)

        ProductGroupManager.SaveProductConfiguration(0, parentID, viewOrder, nodeName, UserManager.GetCurrentValidUserLDAPName, Convert.ToInt32(ddlProductConfig.SelectedValue))
        DirectCast(DirectCast(Remi.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub
#End Region

#Region "GridView Events"
    Protected Sub grdVersions_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles grdVersion.RowCommand
        Dim xmlstr As String = e.CommandArgument
        Dim xml As XDocument = XDocument.Parse(xmlstr)

        Select Case e.CommandName.ToLower()
            Case "xml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("XMLFile", "xml"), xml)
                Exit Select
        End Select
    End Sub

    Sub VersionBindData(ByVal pcID As Int32)
        grdvVersions.DataSource = VersionManager.remispVersionProductLink(ddlTests.Items.FindByValue(hdnTestID.Value).Text, pcID)
        grdvVersions.DataBind()
    End Sub

    Protected Sub grdvVersions_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdvVersions.EditIndex = e.NewEditIndex
        VersionBindData(ddlProductConfig.SelectedValue)

        Dim chkATA As CheckBox = grdvVersions.Rows(e.NewEditIndex).FindControl("chkATA")
        Dim ddlVersions As DropDownList = grdvVersions.Rows(e.NewEditIndex).FindControl("ddlVersions")
        Dim lblVersion As Label = grdvVersions.Rows(e.NewEditIndex).FindControl("lblVersion")
        ddlVersions.Visible = True
        lblVersion.Visible = False

        Dim versions As List(Of Int32) = (From q As DataRow In VersionManager.remispVersionProductLink(ddlTests.Items.FindByValue(hdnTestID.Value).Text, ddlProductConfig.SelectedValue).Rows.Cast(Of DataRow)() Where q.Field(Of Int32)("PCVersion") > 0 And q.Field(Of Int32)("PCVersion") = lblVersion.Text Select q.Field(Of Int32)("PCVersion")).ToList()

        ddlVersions.DataSource = (From v In New Remi.Dal.Entities().Instance().ProductConfigurationVersions _
                                  Where v.ProductConfigurationUpload.ID = ddlProductConfig.SelectedValue And Not (versions.Contains(v.VersionNum)) _
                                  Select v.ID, v.VersionNum).ToList()
        ddlVersions.DataBind()

        If grdvVersions.DataKeys(e.NewEditIndex).Values(1) IsNot DBNull.Value Then
            ddlVersions.SelectedValue = grdvVersions.DataKeys(e.NewEditIndex).Values(1)
        End If

        chkATA.Enabled = True
    End Sub

    Protected Sub grdvVersions_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdvVersions.EditIndex = -1
        VersionBindData(ddlProductConfig.SelectedValue)
    End Sub

    Protected Sub grdvVersions_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim lblVersion As Label = grdvVersions.Rows(e.RowIndex).FindControl("lblVersion")
        Dim lblReleaseVersion As Label = grdvVersions.Rows(e.RowIndex).FindControl("lblReleaseVersion")
        Dim lblID As Label = grdvVersions.Rows(e.RowIndex).FindControl("lblID")
        Dim chkATA As CheckBox = grdvVersions.Rows(e.RowIndex).FindControl("chkATA")
        Dim ddlVersions As DropDownList = grdvVersions.Rows(e.RowIndex).FindControl("ddlVersions")
        Dim applicableToAll As Int32 = 0
        Dim versionID As Int32 = 0
        Dim apvID As Int32 = 0
        Dim avID As Int32 = 0

        If (Request.Form(chkATA.UniqueID) = "on") Then
            applicableToAll = 1
        End If

        Int32.TryParse(Request.Form(ddlVersions.UniqueID), versionID)
        Int32.TryParse(grdvVersions.DataKeys(e.RowIndex).Values(0).ToString(), apvID)
        Int32.TryParse(grdvVersions.DataKeys(e.RowIndex).Values(2).ToString(), avID)

        VersionManager.SaveVersion(lblID.Text, lblReleaseVersion.Text, applicableToAll)

        If (versionID > 0) Then
            VersionManager.SaveVersionProductLink(apvID, versionID, avID)
        End If

        grdvVersions.EditIndex = -1
        VersionBindData(ddlProductConfig.SelectedValue)
    End Sub

    Protected Sub grdvproductConfigDetails_RowDataBound(sender As Object, e As GridViewRowEventArgs)
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (isEditMode) Then
                Dim cmbLookupID As DropDownList = DirectCast(e.Row.FindControl("ddlLookupID"), DropDownList)
                cmbLookupID.SelectedValue = DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(2).ToString()

                Dim txtLookupValue As TextBox = DirectCast(e.Row.FindControl("txtLookupValue"), TextBox)
                txtLookupValue.Text = DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(3).ToString()

                Dim lblConfID As TextBox = DirectCast(e.Row.FindControl("txtConfID"), TextBox)
                lblConfID.Text = DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(4).ToString()

                Dim imgDeleteSub As Image = DirectCast(e.Row.Cells(3).FindControl("imgDeleteSub"), System.Web.UI.WebControls.Image)
                imgDeleteSub.Attributes.Item("onclick") = imgDeleteSub.Attributes.Item("onclick").Replace("REPLACEME", lblConfID.Text).Replace("REPLACE", e.Row.ClientID)

                Dim chkIsAttribute As CheckBox = DirectCast(e.Row.FindControl("chkIsAttribute"), CheckBox)
                chkIsAttribute.Checked = DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(5).ToString()
            End If
        End If
    End Sub

    Protected Sub grdvProductConfig_RowDataBound(sender As Object, e As GridViewRowEventArgs) Handles grdvProductConfig.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (isEditMode) Then
                Dim dtHeader As DataTable = ProductGroupManager.GetProductConfigurationHeader(Convert.ToInt32(ddlProductConfig.SelectedValue))

                Dim cmbParent As DropDownList = DirectCast(e.Row.FindControl("ddlParentNames"), DropDownList)
                If cmbParent IsNot Nothing Then
                    Dim val As Int32
                    Int32.TryParse(grdvProductConfig.DataKeys(e.Row.RowIndex).Values(1).ToString(), val)

                    Dim list = ((From dt1 In dtHeader.AsEnumerable() _
                                                  Select New With { _
                                                      .ParentName = dt1.Field(Of String)("NodeName") + " " + dt1.Field(Of Int32)("ViewOrder").ToString(), _
                                                      .ParentID = dt1.Field(Of Int32)("ID") _
                                                      } _
                                                    ).Union(From t In New String() {String.Empty} Select New With {.ParentName = String.Empty, .ParentID = 0})).OrderBy(Function(p) p.ParentName + " ")

                    cmbParent.DataSource = list
                    cmbParent.DataBind()
                    cmbParent.SelectedValue = val
                End If
            End If

            Dim addDetail As Image = DirectCast(e.Row.FindControl("btnAddDetail"), Image)
            Dim pcID As Int32 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "ID"))
            Dim dt As DataTable = ProductGroupManager.GetProductConfigurationDetails(pcID)
            Dim grdvDetails As GridView = DirectCast(e.Row.FindControl("grdvDetails"), GridView)
            Dim chkIsAttributeAdd As CheckBox = DirectCast(e.Row.FindControl("chkIsAttributeAdd"), CheckBox)
            chkIsAttributeAdd.InputAttributes.Add("class", "hidden")

            grdvDetails.CssClass = "hidden"
            addDetail.ImageAlign = ImageAlign.Left
            addDetail.ImageUrl = "/Design/Icons/png/16x16/add.png"
            addDetail.ToolTip = "Add Node To " & DirectCast(e.Row.FindControl("lblNodeName"), Label).Text
            addDetail.Attributes.Add("onclick", "javascript: btnAddDetail_Click('" & e.Row.FindControl("txtValueAdd").ClientID & "', '" & e.Row.FindControl("ddlLookupsAdd").ClientID & "', '" & e.Row.FindControl("btnSave").ClientID & "', '" & e.Row.FindControl("chkIsAttributeAdd").ClientID & "', '" & e.Row.FindControl("rblLookupsAdd").ClientID & "');")
            Dim ddlLookupsAdd As DropDownList = DirectCast(e.Row.FindControl("ddlLookupsAdd"), DropDownList)
            ddlLookupsAdd.DataSource = dtConfig
            ddlLookupsAdd.DataBind()

            Dim rblLookupsAdd As RadioButtonList = DirectCast(e.Row.FindControl("rblLookupsAdd"), RadioButtonList)
            rblLookupsAdd.Attributes.Add("onclick", "Javascript: SwitchDropText('" & e.Row.FindControl("rblLookupsAdd").ClientID & "', '" & e.Row.FindControl("txtLookupsAdd").ClientID & "', '" & e.Row.FindControl("ddlLookupsAdd").ClientID & "')")

            Dim btnSave As Image = DirectCast(e.Row.FindControl("btnSave"), Image)
            btnSave.Attributes.Add("onclick", "AddDetail('" & pcID & "','" & e.Row.FindControl("txtValueAdd").ClientID & "', '" & e.Row.FindControl("ddlLookupsAdd").ClientID & "', '" & grdvDetails.ClientID & "','" & e.Row.FindControl("chkIsAttributeAdd").ClientID & "', '" & e.Row.FindControl("txtLookupsAdd").ClientID & "');")

            If (isEditMode) Then
                addDetail.CssClass = ""
            End If

            If (isEditMode) Then
                Dim tfProdConfID As New TemplateField
                tfProdConfID.ShowHeader = False
                tfProdConfID.HeaderText = "Config ID"
                tfProdConfID.ItemTemplate = New Remi.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "TextBox", "txtConfID", Nothing, True, String.Empty, Nothing)
                tfProdConfID.ItemStyle.CssClass = "hidden"
                tfProdConfID.ControlStyle.CssClass = "hidden"
                tfProdConfID.HeaderStyle.CssClass = "hidden"
                tfProdConfID.FooterStyle.CssClass = "hidden"
                grdvDetails.Columns.Add(tfProdConfID)
            Else
                Dim bfProdConfID As New BoundField
                bfProdConfID.ShowHeader = False
                bfProdConfID.DataField = "ProdConfID"
                bfProdConfID.HeaderText = "Config ID"
                bfProdConfID.ControlStyle.CssClass = "hidden"
                bfProdConfID.ItemStyle.CssClass = "hidden"
                bfProdConfID.HeaderStyle.CssClass = "hidden"
                bfProdConfID.FooterStyle.CssClass = "hidden"
                grdvDetails.Columns.Add(bfProdConfID)
            End If

            If (isEditMode) Then
                Dim tfLookupName As New TemplateField
                tfLookupName.ShowHeader = True
                tfLookupName.HeaderText = "Type"
                tfLookupName.ItemTemplate = New Remi.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "dropdownlist", "ddlLookupID", dtConfig, True, String.Empty, Nothing)
                grdvDetails.Columns.Add(tfLookupName)
            Else
                Dim bfLookupName As New BoundField
                bfLookupName.DataField = "LookupName"
                bfLookupName.HeaderText = "Lookup Name"
                grdvDetails.Columns.Add(bfLookupName)
            End If

            If (isEditMode) Then
                Dim tfLookupValue As New TemplateField
                tfLookupValue.ShowHeader = True
                tfLookupValue.HeaderText = "Value"
                tfLookupValue.ItemTemplate = New Remi.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "TextBox", "txtLookupValue", Nothing, True, String.Empty, Nothing)
                grdvDetails.Columns.Add(tfLookupValue)
            Else
                Dim bfLookupValue As New BoundField
                bfLookupValue.DataField = "LookupValue"
                bfLookupValue.HeaderText = "Value"
                grdvDetails.Columns.Add(bfLookupValue)
            End If

            If (isEditMode) Then
                Dim tfAttribute As New TemplateField
                tfAttribute.ShowHeader = True
                tfAttribute.HeaderText = "Attribute"
                tfAttribute.ItemTemplate = New Remi.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "CheckBox", "chkIsAttribute", Nothing, True, String.Empty, Nothing)
                grdvDetails.Columns.Add(tfAttribute)
            Else
                Dim bfAttribute As New BoundField
                bfAttribute.DataField = "IsAttribute"
                bfAttribute.HeaderText = "Attribute"
                grdvDetails.Columns.Add(bfAttribute)
            End If

            If (isEditMode) Then
                Dim tfDelete As New TemplateField
                Dim attr As New Dictionary(Of String, String)
                attr.Add("onclick", "javascript: deleteDetail(REPLACEME, this, 'REPLACE');")
                tfDelete.ItemTemplate = New Remi.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "Image", "imgDeleteSub", Nothing, True, "/Design/Icons/png/16x16/delete.png", attr)
                grdvDetails.Columns.Add(tfDelete)
            End If

            Dim btnDetail As Image = DirectCast(e.Row.FindControl("btnDetail"), Image)
            Dim imgDeleteRow As Image = DirectCast(e.Row.FindControl("imgDeleteRow"), Image)
            btnDetail.Attributes.Add("onclick", "javascript: gvrowtoggle(" & e.Row.RowIndex & ", '" & grdvDetails.ClientID & "')")

            imgDeleteRow.Attributes.Add("onclick", "javascript: deleteRow('" & pcID & "', '" & e.Row.ClientID & "');")
            grdvDetails.HorizontalAlign = HorizontalAlign.Left

            If (dt.Rows.Count = 0) Then
                btnDetail.CssClass = "hidden"
                If (isEditMode) Then
                    imgDeleteRow.CssClass = ""
                    imgDeleteRow.ImageAlign = ImageAlign.Left
                End If
            Else
                btnDetail.CssClass = ""
                btnDetail.ImageAlign = ImageAlign.Left
            End If

            grdvDetails.DataSource = dt
            grdvDetails.DataBind()
            Helpers.MakeAccessable(grdvDetails)
        End If
    End Sub
#End Region
End Class