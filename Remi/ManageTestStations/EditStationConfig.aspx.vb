Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts
Imports Remi.Core
Imports System.IO

Partial Class ManageStations_EditStationConfig
    Inherits System.Web.UI.Page

    Protected isEditMode As Boolean
    Dim dtConfig As DataTable = LookupsManager.GetLookups("Configuration", 0, 0, 0)

#Region "Page Events"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim trackingID As String = Request.QueryString.Get("BarcodeSuffix")
        Dim id As Int32
        Int32.TryParse(trackingID, id)
        Dim host As String = Request(ddlHosts.UniqueID)
        txtXMLDisplay.Visible = False
        lblXMLTitle.Visible = False
        btnAddNode.Visible = False
        ddlHosts.Items.Clear()
        Dim hosts As TrackingLocationCollection = TrackingLocationManager.GetTrackingLocationHostsByID(id)
        hosts.Insert(0, New TrackingLocation())
        ddlHosts.DataSource = hosts
        ddlHosts.DataValueField = "HostID"
        ddlHosts.DataTextField = "HostName"
        ddlHosts.DataBind()
        pnlOverAll.Visible = False

        If (String.IsNullOrEmpty(trackingID)) Then
            ddlHosts.Visible = False
            lvlHosts.Visible = False
        End If

        Dim trackingName As String = hosts(1).DisplayName
        lblTrackingName.Text = "Edit " + trackingName + " Configuration"

        If (Me.IsPostBack) Then
            hdnTrackingID.Value = id
            hypCancel.NavigateUrl = REMIWebLinks.GetTrackingLocationInfoLink(id)
            hypRefresh.NavigateUrl = REMIWebLinks.GetSetStationConfigurationLink(id)
            pnlLeftMenuActions.Visible = True
            hdnHostID.Value = host

            If (hdnHostID.Value <> "0") Then
                ddlSwitchPlugin.Items.Clear()
                ddlSwitchPlugin.Items.Add(String.Empty)
                ddlSwitchPlugin.DataSource = TrackingLocationManager.GetTrackingLocationPlugins(hdnTrackingID.Value)
                ddlSwitchPlugin.DataBind()

                If (ddlSwitchPlugin.Items.Count > 2) Then 'includes the space record
                    ddlSwitchPlugin.Visible = True
                    lblSwitchPlugin.Visible = True
                    ddlSwitchPlugin.SelectedIndex = 0
                End If
            Else
                ddlSwitchPlugin.Visible = False
                lblSwitchPlugin.Visible = False
            End If

            If (Not (String.IsNullOrEmpty(trackingName)) And Not (String.IsNullOrEmpty(host) And host <> "0")) Then
                txtXMLDisplay.TextMode = TextBoxMode.MultiLine
                txtXMLDisplay.Rows = 40
                txtXMLDisplay.Columns = 60
                txtXMLDisplay.ReadOnly = True
                txtXMLDisplay.Visible = True
                lblXMLTitle.Visible = True
                pnlOverAll.Visible = True

                Dim record = (From r In New REMI.Dal.Entities().Instance().StationConfigurationUploads Where r.TrackingLocationHostID = host And r.IsProcessed = 0 Select r)

                If (record.Count > 0) Then
                    pnlOverAll.Visible = False
                    lblXMLTitle.Visible = False
                    txtXMLDisplay.Visible = False
                    lblProcessing.Visible = True
                    btnUpload.Visible = False
                    lblMissingConfiguration2.Visible = False
                    lblMissingConfiguration.Visible = False
                    ddlCopyFrom.Visible = False
                    ddlSwitchPlugin.Visible = False
                    lblSwitchPlugin.Visible = False

                    If (DateTime.Now.Hour.Equals(13)) Then
                        btnProcessPendingXML.Visible = False
                    Else
                        btnProcessPendingXML.Visible = True
                    End If
                Else
                    Dim pluginID As Int32
                    Int32.TryParse(ddlSwitchPlugin.SelectedValue, pluginID)

                    If (pluginID = 0) Then
                        Int32.TryParse(Request.Form(ddlSwitchPlugin.UniqueID), pluginID)
                    End If

                    btnProcessPendingXML.Visible = False
                    lblProcessing.Visible = False
                    Dim notValidBindControls As String() = New String() {"btnEditMode", "btnViewMode", "btnUpdate", "btnSave", "btnAddDetail", "btnAddNode", "btnSaveNode", "btnDeleteSub", "imgDeleteRow", "btnUpload"}
                    If (REMI.Helpers.GetPostBackControl(Me.Page) IsNot Nothing) Then
                        If (Not (notValidBindControls.Contains(REMI.Helpers.GetPostBackControl(Me.Page).ID))) Then
                            btnAddNode.Visible = True
                            pnlAddNode.CssClass = "hidden"

                            Dim NoPlugin = (From r In New REMI.Dal.Entities().Instance().TrackingLocationsHostsConfigurations Where r.TrackingLocationHostID = host And r.TrackingLocationsPlugin Is Nothing Select r).FirstOrDefault()

                            If (NoPlugin IsNot Nothing) Then
                                ddlSwitchPlugin.Visible = False
                                lblSwitchPlugin.Visible = False
                            End If

                            If (ddlSwitchPlugin.Visible And pluginID <> 0) Then
                                BindData()
                            ElseIf (ddlSwitchPlugin.Visible = False) Then
                                BindData()
                            Else
                                pnlOverAll.Visible = False
                                txtXMLDisplay.Visible = True
                                txtXMLDisplay.ReadOnly = False
                                txtXMLDisplay.Text = String.Empty
                            End If
                        End If
                    End If
                    If (pluginID > 0) Then
                        ddlSwitchPlugin.SelectedValue = pluginID
                    End If
                End If
            End If
            If (Not (String.IsNullOrEmpty(host))) Then
                ddlHosts.Items.FindByValue(host).Selected = True
            End If
        End If
    End Sub

    Protected Sub SetGvwHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        Helpers.MakeAccessable(grdvStationConfig)
    End Sub
#End Region

#Region "Methods"
    <System.Web.Services.WebMethod()> _
    Public Shared Function AddRowDetail(ByVal hostID As Int32, ByVal configID As Int32, ByVal lookupText As String, ByVal lookupID As Int32, ByVal isAttribute As Boolean) As String
        TrackingLocationManager.SaveStationConfigurationDetails(configID, 0, lookupID, lookupText, hostID, UserManager.GetCurrentValidUserLDAPName, isAttribute)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteAll(ByVal hostID As Int32, ByVal pluginID As Int32) As String
        Dim success As Boolean = TrackingLocationManager.DeleteStationConfiguration(hostID, UserManager.GetCurrentValidUserLDAPName, pluginID)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteConfig(ByVal configID As Int32) As String
        Dim success As Boolean = TrackingLocationManager.DeleteStationConfigurationDetail(configID, UserManager.GetCurrentValidUserLDAPName)

        Return String.Empty
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function DeleteRow(ByVal hostConfig As Int32, ByVal profileID As Int32) As String
        Dim success As Boolean = TrackingLocationManager.DeleteStationConfigurationHeader(hostConfig, UserManager.GetCurrentValidUserLDAPName, profileID)

        Return String.Empty
    End Function

    Private Sub BindData()
        Dim pluginID As Int32
        Int32.TryParse(ddlSwitchPlugin.SelectedValue, pluginID)

        If (pluginID = 0) Then
            Int32.TryParse(Request.Form(ddlSwitchPlugin.UniqueID), pluginID)
        End If

        Dim dt As DataTable = TrackingLocationManager.GetStationConfigurationHeader(hdnHostID.Value, pluginID)

        ddlPluginName.Items.Clear()
        ddlPluginName.Items.Add(String.Empty)
        ddlPluginName.DataSource = TrackingLocationManager.GetTrackingLocationPlugins(hdnTrackingID.Value)
        ddlPluginName.DataBind()

        If (dt.Rows.Count > 0) Then
            ddlPluginName.SelectedValue = dt.Rows(0).Item(6).ToString()
        End If

        Dim xml As XDocument = TrackingLocationManager.GetStationConfigurationXML(hdnHostID.Value, ddlPluginName.SelectedItem.Text)

        If (dt.Rows.Count = 0) Then
            Dim dtSimilar As DataTable = TrackingLocationManager.GetSimilarStationConfigurations(hdnHostID.Value)
            ddlCopyFrom.DataSource = dtSimilar
            ddlCopyFrom.DataBind()
            txtXMLDisplay.Visible = False
            lblXMLTitle.Visible = False

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
            lblXMLTitle.Visible = True
            txtXMLDisplay.Visible = True
            ddlCopyFrom.Visible = False
            lblMissingConfiguration.Visible = False
            lblMissingConfiguration2.Visible = False
            txtXMLDisplay.Text = xml.ToString()
            btnUpload.Visible = False
            btnCopyFrom.Visible = False
        End If

        grdvStationConfig.DataSource = dt
        grdvStationConfig.AutoGenerateColumns = False
        grdvStationConfig.DataBind()

        If (grdvStationConfig.Rows.Count = 0) Then
            btnViewMode.Visible = False
            btnEditMode.Visible = False
            btnUpdate.Visible = False
            ddlPluginName.Enabled = False
            ddlPluginName.Visible = False
            txtXMLDisplay.Text = String.Empty
        Else
            btnViewMode.Visible = True
            btnEditMode.Visible = True
            btnUpdate.Visible = IsInEditMode
            ddlPluginName.Enabled = IsInEditMode
            ddlPluginName.Visible = True
            btnDeleteAll.Attributes.Add("onclick", "javascript: deleteAllNodes('" & Convert.ToInt32(hdnHostID.Value) & "', '" & pluginID & "');")

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
    Protected Sub btnProcessPendingXML_Click(sender As Object, e As EventArgs)
        TrackingLocationManager.StationConfigurationProcess()

        Response.Redirect(hypCancel.NavigateUrl)
    End Sub

    Protected Sub btnUpload_Click(sender As Object, e As EventArgs)
        If txtXMLDisplay.Text <> "" Then
            Try
                Dim xml As XDocument = XDocument.Parse(txtXMLDisplay.Text)

                TrackingLocationManager.StationConfigurationUpload(Convert.ToInt32(hdnHostID.Value), xml, UserManager.GetCurrentValidUserLDAPName, Request.Form(ddlSwitchPlugin.UniqueID))
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
            txtXMLDisplay.Visible = False
            btnUpload.Visible = False
            lblMissingConfiguration2.Visible = False
            lblMissingConfiguration.Visible = False
            ddlCopyFrom.Visible = False
            btnCopyFrom.Visible = False
            txtXMLDisplay.Text = String.Empty
        End If
    End Sub

    Protected Sub btnEditMode_Click(sender As Object, e As EventArgs) Handles btnEditMode.Click
        IsInEditMode = True
        btnEditMode.Enabled = Not (IsInEditMode)
        btnViewMode.Enabled = IsInEditMode
        btnUpdate.Visible = IsInEditMode
        ddlPluginName.Enabled = IsInEditMode
        DirectCast(DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub

    Protected Sub btnViewMode_Click(sender As Object, e As EventArgs) Handles btnViewMode.Click
        IsInEditMode = False
        btnEditMode.Enabled = Not (IsInEditMode)
        btnViewMode.Enabled = IsInEditMode
        btnUpdate.Visible = IsInEditMode
        ddlPluginName.Enabled = IsInEditMode
        DirectCast(DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub

    Protected Sub btnCopyFrom_Click(sender As Object, e As EventArgs) Handles btnCopyFrom.Click
        Dim hostID As Int32
        Dim copyFromHostID As Int32

        Int32.TryParse(hdnHostID.Value, hostID)
        Int32.TryParse(ddlCopyFrom.SelectedValue, copyFromHostID)

        Dim success As Boolean = TrackingLocationManager.CopyStationConfiguration(hdnHostID.Value, copyFromHostID, UserManager.GetCurrentValidUserLDAPName, Request.Form(ddlSwitchPlugin.UniqueID))

        BindData()
    End Sub

    Protected Sub btnUpdate_Click(sender As Object, e As EventArgs) Handles btnUpdate.Click
        Dim pluginID As Int32
        Int32.TryParse(ddlPluginName.SelectedValue, pluginID)

        For Each row As GridViewRow In grdvStationConfig.Rows
            Dim parentID As Int32
            Dim lblConfigID As Int32
            Int32.TryParse(DirectCast(row.FindControl("lblConfigID"), Label).Text, lblConfigID)
            Int32.TryParse(Request.Form(DirectCast(row.FindControl("ddlParentNames"), DropDownList).UniqueID), parentID)
            Dim viewOrder As Int32 = Request.Form(DirectCast(row.FindControl("txtViewOrder"), TextBox).UniqueID)
            Dim nodeName As String = Request.Form(DirectCast(row.FindControl("txtNodeName"), TextBox).UniqueID)

            Dim result As Boolean = TrackingLocationManager.SaveStationConfiguration(lblConfigID, parentID, viewOrder, nodeName, Convert.ToInt32(hdnHostID.Value), UserManager.GetCurrentValidUserLDAPName, pluginID)

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

                        Dim resultDetail As Boolean = TrackingLocationManager.SaveStationConfigurationDetails(lblConfigID, txtConfID, ddlLookupID, txtLookupValue, Convert.ToInt32(hdnHostID.Value), UserManager.GetCurrentValidUserLDAPName, isAttribute)
                    Next
                End If
            End If
        Next
        BindData()
    End Sub

    Protected Sub btnAddNode_Click(sender As Object, e As EventArgs)
        DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("btnAddNode").Visible = False
        DirectCast(DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = ""

        Dim cmbParent As DropDownList = DirectCast(DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("ddlAddParentNames"), DropDownList)
        If cmbParent IsNot Nothing Then
            Dim list = ((From dt1 In TrackingLocationManager.GetStationConfigurationHeader(hdnHostID.Value, ddlSwitchPlugin.SelectedValue).AsEnumerable() _
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

        nodeName = Request.Form(REMI.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("txtAddNodeName").UniqueID)
        Int32.TryParse(Request.Form(REMI.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("txtAddViewOrder").UniqueID), viewOrder)
        Int32.TryParse(Request.Form(REMI.Helpers.GetPostBackControl(Me.Page).Parent.FindControl("ddlAddParentNames").UniqueID), parentID)

        TrackingLocationManager.SaveStationConfiguration(0, parentID, viewOrder, nodeName, hdnHostID.Value, UserManager.GetCurrentValidUserLDAPName, ddlSwitchPlugin.SelectedValue)

        DirectCast(DirectCast(REMI.Helpers.GetPostBackControl(Me.Page), System.Web.UI.WebControls.Button).Parent.FindControl("pnlAddNode"), Panel).CssClass = "hidden"
        BindData()
    End Sub
#End Region

#Region "GridView Events"
    Protected Sub grdvStationConfigDetails_RowDataBound(sender As Object, e As GridViewRowEventArgs)
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

    Protected Sub grdvStationConfig_RowDataBound(sender As Object, e As GridViewRowEventArgs) Handles grdvStationConfig.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim pluginID As Int32

            If (isEditMode) Then
                Int32.TryParse(ddlSwitchPlugin.SelectedValue, pluginID)

                If (pluginID = 0) Then
                    Int32.TryParse(Request.Form(ddlSwitchPlugin.UniqueID), pluginID)
                End If

                Dim dtHeader As DataTable = TrackingLocationManager.GetStationConfigurationHeader(hdnHostID.Value, pluginID)

                Dim cmbParent As DropDownList = DirectCast(e.Row.FindControl("ddlParentNames"), DropDownList)
                If cmbParent IsNot Nothing Then
                    Dim val As Int32
                    Int32.TryParse(grdvStationConfig.DataKeys(e.Row.RowIndex).Values(1).ToString(), val)

                    Dim list = ((From dt1 In TrackingLocationManager.GetStationConfigurationHeader(hdnHostID.Value, pluginID).AsEnumerable() _
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
            Dim configID As Int32 = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "ID"))
            Dim dt As DataTable = TrackingLocationManager.GetStationConfigurationDetails(configID)
            Dim grdvDetails As GridView = DirectCast(e.Row.FindControl("grdvDetails"), GridView)
            Dim chkIsAttributeAdd As CheckBox = DirectCast(e.Row.FindControl("chkIsAttributeAdd"), CheckBox)
            chkIsAttributeAdd.InputAttributes.Add("class", "hidden")

            grdvDetails.CssClass = "hidden"
            addDetail.ImageAlign = ImageAlign.Left
            addDetail.ImageUrl = "/Design/Icons/png/16x16/add.png"
            addDetail.ToolTip = "Add Node To " & DirectCast(e.Row.FindControl("lblNodeName"), Label).Text
            addDetail.Attributes.Add("onclick", "javascript: btnAddDetail_Click('" & e.Row.FindControl("txtValueAdd").ClientID & "', '" & e.Row.FindControl("ddlLookupsAdd").ClientID & "', '" & e.Row.FindControl("btnSave").ClientID & "', '" & e.Row.FindControl("chkIsAttributeAdd").ClientID & "');")
            Dim ddlLookupsAdd As DropDownList = DirectCast(e.Row.FindControl("ddlLookupsAdd"), DropDownList)
            ddlLookupsAdd.DataSource = dtConfig
            ddlLookupsAdd.DataBind()

            Dim btnSave As Image = DirectCast(e.Row.FindControl("btnSave"), Image)
            btnSave.Attributes.Add("onclick", "AddDetail('" & hdnHostID.Value & "', " & configID & ",'" & e.Row.FindControl("txtValueAdd").ClientID & "', '" & e.Row.FindControl("ddlLookupsAdd").ClientID & "', '" & grdvDetails.ClientID & "','" & e.Row.FindControl("chkIsAttributeAdd").ClientID & "');")

            If (isEditMode) Then
                addDetail.CssClass = ""
            End If

            If (isEditMode) Then
                Dim tfTrackingConfID As New TemplateField
                tfTrackingConfID.ShowHeader = False
                tfTrackingConfID.HeaderText = "Config ID"
                tfTrackingConfID.ItemTemplate = New REMI.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "TextBox", "txtConfID", Nothing, True, String.Empty, Nothing)
                tfTrackingConfID.ItemStyle.CssClass = "hidden"
                tfTrackingConfID.ControlStyle.CssClass = "hidden"
                tfTrackingConfID.HeaderStyle.CssClass = "hidden"
                tfTrackingConfID.FooterStyle.CssClass = "hidden"
                grdvDetails.Columns.Add(tfTrackingConfID)
            Else
                Dim bfTrackingConfID As New BoundField
                bfTrackingConfID.ShowHeader = False
                bfTrackingConfID.DataField = "TrackingConfigID"
                bfTrackingConfID.HeaderText = "Config ID"
                bfTrackingConfID.ControlStyle.CssClass = "hidden"
                bfTrackingConfID.ItemStyle.CssClass = "hidden"
                bfTrackingConfID.HeaderStyle.CssClass = "hidden"
                bfTrackingConfID.FooterStyle.CssClass = "hidden"
                grdvDetails.Columns.Add(bfTrackingConfID)
            End If

            If (isEditMode) Then
                Dim tfLookupName As New TemplateField
                tfLookupName.ShowHeader = True
                tfLookupName.HeaderText = "Type"
                tfLookupName.ItemTemplate = New REMI.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "dropdownlist", "ddlLookupID", dtConfig, True, String.Empty, Nothing)
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
                tfLookupValue.ItemTemplate = New REMI.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "TextBox", "txtLookupValue", Nothing, True, String.Empty, Nothing)
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
                tfAttribute.ItemTemplate = New REMI.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "CheckBox", "chkIsAttribute", Nothing, True, String.Empty, Nothing)
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
                tfDelete.ItemTemplate = New REMI.Bll.GridViewTemplate(DataControlRowType.DataRow, "", "", "Image", "imgDeleteSub", Nothing, True, "/Design/Icons/png/16x16/delete.png", attr)
                grdvDetails.Columns.Add(tfDelete)
            End If

            Dim btnDetail As Image = DirectCast(e.Row.FindControl("btnDetail"), Image)
            Dim imgDeleteRow As Image = DirectCast(e.Row.FindControl("imgDeleteRow"), Image)
            btnDetail.Attributes.Add("onclick", "javascript: gvrowtoggle(" & e.Row.RowIndex & ", '" & grdvDetails.ClientID & "')")

            imgDeleteRow.Attributes.Add("onclick", "javascript: deleteRow('" & configID & "', '" & e.Row.ClientID & "', '" & pluginID & "');")
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