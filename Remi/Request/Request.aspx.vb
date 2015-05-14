Imports Remi.Bll
Imports Remi.Validation
Imports Remi.Contracts
Imports Remi.BusinessEntities
Imports System.Reflection
Imports System.IO

Public Class Request
    Inherits System.Web.UI.Page

#Region "Methods"
    Protected Sub BuildMenu()
        Dim requestNumber As String = hdnRequestNumber.Value
        Dim myMenu As WebControls.Menu
        Dim mi As New MenuItem
        myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)
        hypNew.NavigateUrl = String.Format("/Request/Request.aspx?type={0}", hdnRequestType.Value)

        mi = New MenuItem
        mi.Text = "Create Request"
        mi.Target = "_blank"
        mi.NavigateUrl = String.Format("/Request/Request.aspx?type={0}", hdnRequestType.Value)
        myMenu.Items(0).ChildItems.Add(mi)

        Dim rec = (From rb In New Remi.Dal.Entities().Instance().Requests Where rb.RequestNumber = requestNumber And rb.BatchID > 0).FirstOrDefault()

        If (rec IsNot Nothing) Then
            mi = New MenuItem
            mi.Text = "Batch"
            mi.Target = "_blank"
            mi.NavigateUrl = String.Format("/ScanForInfo/Default.aspx?RN={0}", requestNumber)
            myMenu.Items(0).ChildItems.Add(mi)
            hypBatch.Visible = True
            hypBatch.NavigateUrl = String.Format("/ScanForInfo/Default.aspx?RN={0}", requestNumber)

            Dim batch As BatchView = BatchManager.GetBatchView(requestNumber, True, False, True, False, False, False, False, False, False, False)
            setup.Visible = True
            setupEnv.Visible = True
            pnlSetup.Visible = True
            setup.JobID = batch.JobID
            setup.ProductID = batch.ProductID
            setup.JobName = batch.JobName
            setup.ProductName = batch.ProductGroup
            setup.QRANumber = rec.RequestNumber
            setup.BatchID = rec.BatchID
            setup.TestStageType = TestStageType.Parametric
            setup.IsProjectManager = (From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = batch.ProductGroup Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault()
            setup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
            setup.HasEditItemAuthority = UserManager.GetCurrentUser.HasEditItemAuthority(batch.ProductGroup, batch.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(batch.DepartmentID)
            setup.OrientationID = 0
            setup.RequestTypeID = hdnRequestTypeID.Value
            setup.UserID = UserManager.GetCurrentUser.ID
            setup.DataBind()

            setupEnv.JobID = batch.JobID
            setupEnv.BatchID = rec.BatchID
            setupEnv.ProductID = batch.ProductID
            setupEnv.JobName = batch.JobName
            setupEnv.ProductName = batch.ProductGroup
            setupEnv.QRANumber = batch.QRANumber
            setupEnv.TestStageType = TestStageType.EnvironmentalStress
            setupEnv.IsProjectManager = (From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = batch.ProductGroup Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault()
            setupEnv.IsAdmin = UserManager.GetCurrentUser.IsAdmin
            setupEnv.HasEditItemAuthority = UserManager.GetCurrentUser.HasEditItemAuthority(batch.ProductGroup, batch.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(batch.DepartmentID)
            setupEnv.OrientationID = 0
            setupEnv.RequestTypeID = hdnRequestTypeID.Value
            setupEnv.UserID = UserManager.GetCurrentUser.ID
            setupEnv.DataBind()

            mi = New MenuItem
            mi.Text = "Results"
            mi.Target = "_blank"
            mi.NavigateUrl = String.Format("/Relab/Results.aspx?Batch={0}", rec.BatchID)
            myMenu.Items(0).ChildItems.Add(mi)
            hypResults.Visible = True
            hypResults.NavigateUrl = String.Format("/Relab/Results.aspx?Batch={0}", rec.BatchID)
        End If

        If ((From dr As DataRow In UserManager.GetCurrentUser.RequestTypes.Rows Where dr.Field(Of Boolean)("IsAdmin") = True And dr.Field(Of Int32)("RequestTypeID") = hdnRequestTypeID.Value).FirstOrDefault() IsNot Nothing) Then
            mi = New MenuItem
            mi.Text = "Admin"
            mi.Target = "_blank"
            mi.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", hdnRequestType.Value, hdnRequestTypeID.Value)
            myMenu.Items(0).ChildItems.Add(mi)
            hypAdmin.Visible = True
            hypAdmin.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", hdnRequestType.Value, hdnRequestTypeID.Value)
        End If
    End Sub
#End Region

#Region "Page Load"
    Protected Overrides Sub OnInit(e As System.EventArgs)
        Dim req As String = IIf(Request.QueryString.Item("req") Is Nothing, String.Empty, Request.QueryString.Item("req"))
        Dim type As String = IIf(Request.QueryString.Item("type") Is Nothing, String.Empty, Request.QueryString.Item("type"))
        Dim debug As Boolean = IIf(Request.QueryString.Item("debug") Is Nothing, False, Request.QueryString.Item("debug"))
        Dim rf As RequestFieldsCollection

        If ((From rt As DataRow In UserManager.GetCurrentUser.RequestTypes.Rows Where rt.Field(Of String)("RequestType") = type Select rt).FirstOrDefault() Is Nothing) Then
            Response.Redirect(String.Format("/Request/Default.aspx"), True)
        End If

        If (Not String.IsNullOrEmpty(req)) Then
            rf = RequestManager.GetRequestFieldSetup(type, False, req)
        Else
            rf = RequestManager.GetRequestFieldSetup(type, False, String.Empty)
        End If

        Dim asm As AjaxControlToolkit.ToolkitScriptManager = Master.FindControl("AjaxScriptManager1")

        If (rf IsNot Nothing) Then
            hdnRequestNumber.Value = rf(0).RequestNumber

            If (rf(0).NewRequest) Then
                chkDisplayChanges.Visible = False
            Else
                chkDisplayChanges.Visible = True
            End If

            If (rf(0).IsFromExternalSystem And Not debug) Then
                If (rf(0).NewRequest) Then
                    Response.Redirect(String.Format("/Request/Default.aspx?rt={0}", type), True)
                Else
                    Response.Redirect((From rl In rf Where rl.IntField = "RequestLink" Select rl.Value).FirstOrDefault(), True)
                End If
            End If

            hdnRequestType.Value = rf(0).RequestType
            hdnRequestTypeID.Value = rf(0).RequestTypeID
            lblRequest.Text = rf(0).RequestNumber
            Dim lastCategory As String = String.Empty

            For Each res In rf
                Dim tRow As New TableRow()
                Dim tCell As New TableCell()
                Dim tCell2 As New TableCell()
                Dim lblName As New Label
                Dim rfv As New RequiredFieldValidator
                Dim id As String = "0"
                Dim fieldCount As Int32 = 1
                tCell.CssClass = "RequestCell1"
                tCell2.CssClass = "RequestCell2"

                If (lastCategory <> res.Category) Then
                    Dim tRowCat As New TableRow()
                    Dim tCellCat As New TableCell()
                    tCellCat.ColumnSpan = 2
                    tCellCat.Text = res.Category
                    tCellCat.CssClass = "RequestCellSpan"

                    tRowCat.Cells.Add(tCellCat)
                    tbl.Rows.Add(tRowCat)
                    lastCategory = res.Category
                End If

                id = res.FieldSetupID

                lblName.Text = String.Format("{0}{1}", If(res.IsRequired, "<b><font color='red'>*</font></b>", ""), res.Name)
                lblName.EnableViewState = True
                lblName.ID = String.Format("lbl{0}", id)
                tCell.Controls.Add(lblName)

                tRow.Cells.Add(tCell)

                If (res.IsRequired) Then
                    rfv.EnableViewState = True
                    rfv.Enabled = True
                    rfv.ErrorMessage = "This Field Is Required"
                    rfv.ID = String.Format("rfv{0}", id)
                    rfv.Display = ValidatorDisplay.Static
                End If

                Dim hdnUniqueID As String = (From s In Request.Form.AllKeys Where s.Contains(String.Format("hdn{0}", res.FieldSetupID)) Select s).FirstOrDefault()

                If Request.Form(hdnAddMore.UniqueID) IsNot Nothing Then
                    If (Request.Form(hdnAddMore.UniqueID).ToString() = res.FieldSetupID.ToString()) Then
                        If (String.IsNullOrEmpty(hdnUniqueID)) Then
                            res.DefaultDisplayNum = res.DefaultDisplayNum.ToString()
                        Else
                            res.DefaultDisplayNum = Request.Form(hdnUniqueID)
                        End If
                    ElseIf (Request.Form(hdnUniqueID) IsNot Nothing) Then
                        res.DefaultDisplayNum = Request.Form(hdnUniqueID)
                    End If
                ElseIf (Request.Form(hdnUniqueID) IsNot Nothing) Then
                    res.DefaultDisplayNum = Request.Form(hdnUniqueID)
                End If

                For i As Int32 = 1 To res.DefaultDisplayNum
                    If (res.MaxDisplayNum > 1) Then
                        id = String.Format("{0}-{1}", res.FieldSetupID.ToString(), fieldCount.ToString())

                        If (fieldCount > 1) Then
                            tCell2.Controls.Add(New LiteralControl("<br />"))
                        End If

                        If (res.Sibling.Count > 0) Then
                            res.Value = res.Sibling(i - 1).Value
                        End If
                    End If

                    Select Case res.FieldType.ToUpper()
                        Case "ATTACHMENT"
                            Dim fu As New FileUpload
                            fu.ID = String.Format("fu{0}", id)
                            fu.EnableViewState = True

                            Dim btnfu As New Button
                            btnfu.ID = String.Format("btnfu{0}", id)
                            btnfu.Text = "Upload"
                            btnfu.CssClass = "buttonSmall"
                            btnfu.EnableViewState = True
                            AddHandler btnfu.Click, AddressOf upload_Click

                            Dim hyp As New HyperLink
                            hyp.ID = String.Format("hyp{0}", id)
                            hyp.Text = res.Value
                            hyp.EnableViewState = True
                            hyp.NavigateUrl = String.Format("~\Handlers\Download.ashx?file={0}&path={1}", hyp.Text, String.Concat(Server.MapPath(Remi.Core.REMIConfiguration.UploadDirectory()), lblRequest.Text))

                            Dim txt As New TextBox
                            txt.ID = String.Format("txt{0}", id)
                            txt.Width = 250
                            txt.Text = res.Value
                            txt.EnableViewState = True
                            txt.Style.Add("display", "none")

                            Dim img As New Image
                            img.EnableViewState = True
                            img.ID = String.Format("img{0}", id)
                            img.ImageUrl = "~\Design\Icons\png\24x24\delete.png"
                            img.EnableViewState = True
                            img.Attributes.Add("onclick", "Javascript: Img_Click('" + id + "')")

                            If (Not String.IsNullOrEmpty(res.Value)) Then
                                fu.Style.Add("display", "none")
                                btnfu.Style.Add("display", "none")
                                hyp.Style.Add("display", "")
                                img.Style.Add("display", "")
                            Else
                                hyp.Style.Add("display", "none")
                                img.Style.Add("display", "none")
                            End If

                            asm.RegisterPostBackControl(btnfu)

                            Dim up As New UpdatePanel
                            up.ID = String.Format("up{0}", id)
                            up.UpdateMode = UpdatePanelUpdateMode.Conditional
                            up.ChildrenAsTriggers = True
                            up.EnableViewState = True
                            up.ContentTemplateContainer.Controls.Add(fu)
                            up.ContentTemplateContainer.Controls.Add(btnfu)
                            up.ContentTemplateContainer.Controls.Add(txt)
                            up.ContentTemplateContainer.Controls.Add(hyp)
                            up.ContentTemplateContainer.Controls.Add(img)
                            AddHandler up.Unload, AddressOf UpdatePanel_Unload

                            tCell2.Controls.Add(up)
                        Case "CHECKBOX"
                            Dim chk As New CheckBox
                            chk.ID = String.Format("chk{0}", id)
                            chk.EnableViewState = True

                            Dim checked As Boolean = False
                            Boolean.TryParse(res.Value, checked)

                            chk.Checked = checked
                            chk.Text = String.Empty

                            tCell2.Controls.Add(chk)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = chk.ID
                            End If
                        Case "DATETIME"
                            Dim dt As New TextBox
                            dt.Text = res.Value
                            dt.EnableViewState = True
                            dt.ID = String.Format("dt{0}", id)
                            dt.Width = 500

                            Dim ce As New AjaxControlToolkit.CalendarExtender
                            ce.Enabled = True
                            ce.EnableViewState = True
                            ce.ID = String.Format("ce{0}", id)
                            ce.TargetControlID = dt.ID

                            tCell2.Controls.Add(dt)
                            tCell2.Controls.Add(ce)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = dt.ID
                            End If
                        Case "DROPDOWN"
                            Dim ddl As New DropDownList
                            ddl.ID = String.Format("ddl{0}", id)
                            ddl.EnableViewState = True
                            AddHandler ddl.SelectedIndexChanged, AddressOf Me.ddl_SelectedIndexChanged
                            ddl.AutoPostBack = True

                            If (res.ParentFieldSetupID > 0) Then
                                For Each rec In (From p In rf Where p.FieldSetupID = res.ParentFieldSetupID Select p)
                                    If (res.CustomLookupHierarchy IsNot Nothing) Then
                                        For Each ch In res.CustomLookupHierarchy
                                            If (ch.ParentLookup = (From p In rf Where p.FieldSetupID = res.ParentFieldSetupID Select p.Value).FirstOrDefault()) Then
                                                ddl.Items.Add(ch.ChildLookup)
                                            End If
                                        Next

                                        If (ddl.Items.Count = 0) Then
                                            For Each o In res.OptionsType
                                                ddl.Items.Add(o)
                                            Next
                                        End If
                                    End If
                                Next
                            Else
                                For Each o In res.OptionsType
                                    ddl.Items.Add(o)
                                Next
                            End If

                            If (String.IsNullOrEmpty(res.Value) And Not String.IsNullOrEmpty(res.DefaultValue)) Then
                                ddl.SelectedValue = res.DefaultValue
                            Else
                                ddl.SelectedValue = res.Value
                            End If

                            tCell2.Controls.Add(ddl)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = ddl.ID
                            End If

                            If (res.IntField = "RequestedTest" And res.HasIntegration And res.NewRequest) Then
                                Dim jobID As Int32 = JobManager.GetJob(ddl.SelectedValue).ID

                                setup.Visible = True
                                setupEnv.Visible = True
                                pnlSetup.Visible = True
                                setup.JobID = jobID
                                setup.ProductID = 0
                                setup.JobName = ddl.SelectedValue
                                setup.ProductName = String.Empty
                                setup.QRANumber = lblRequest.Text
                                setup.BatchID = 0
                                setup.TestStageType = TestStageType.Parametric
                                setup.IsProjectManager = False
                                setup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                                setup.HasEditItemAuthority = True
                                setup.OrientationID = 0
                                setup.RequestTypeID = hdnRequestTypeID.Value
                                setup.UserID = UserManager.GetCurrentUser.ID
                                setup.DataBind()

                                setupEnv.JobID = jobID
                                setupEnv.BatchID = 0
                                setupEnv.ProductID = 0
                                setupEnv.JobName = ddl.SelectedValue
                                setupEnv.ProductName = String.Empty
                                setupEnv.QRANumber = lblRequest.Text
                                setupEnv.TestStageType = TestStageType.EnvironmentalStress
                                setupEnv.IsProjectManager = False
                                setupEnv.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                                setup.HasEditItemAuthority = True
                                setupEnv.OrientationID = 0
                                setupEnv.RequestTypeID = hdnRequestTypeID.Value
                                setupEnv.UserID = UserManager.GetCurrentUser.ID
                                setupEnv.DataBind()
                            End If
                        Case "LINK"
                            Dim lnk As New HyperLink
                            lnk.ID = String.Format("lnk{0}", id)
                            lnk.EnableViewState = True
                            lnk.Text = res.Name
                            lnk.Target = "_blank"
                            lnk.NavigateUrl = res.Value
                            tCell2.Controls.Add(lnk)

                            Dim lnktxt As New TextBox
                            lnktxt.Text = res.Value
                            lnktxt.EnableViewState = True
                            lnktxt.ID = String.Format("lnktxt{0}", id)
                            lnktxt.Width = 250

                            If (res.IntField = "RequestLink") Then
                                lnktxt.Style.Add("display", "none")
                            End If

                            tCell2.Controls.Add(lnktxt)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = lnktxt.ID
                            End If
                        Case "RADIOBUTTON"
                            Dim rb As New RadioButtonList
                            rb.ID = String.Format("rb{0}", id)
                            rb.EnableViewState = True
                            rb.RepeatDirection = RepeatDirection.Horizontal
                            rb.CssClass = "RemoveBorder"

                            For Each o In res.OptionsType
                                rb.Items.Add(o)
                            Next

                            rb.SelectedValue = res.Value

                            tCell2.Controls.Add(rb)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = rb.ID
                            End If
                        Case "TEXTAREA"
                            Dim txtArea As New TextBox
                            txtArea.EnableViewState = True
                            txtArea.ID = String.Format("txtArea{0}", id)
                            txtArea.TextMode = TextBoxMode.MultiLine
                            txtArea.Width = Unit.Percentage(100)
                            txtArea.Rows = 20
                            txtArea.Text = res.Value
                            tCell2.Controls.Add(txtArea)

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = txtArea.ID
                            End If
                        Case "TEXTBOX"
                            Dim txt As New TextBox
                            txt.Text = res.Value
                            txt.EnableViewState = True
                            txt.ID = String.Format("txt{0}", id)
                            txt.Width = 500
                            tCell2.Controls.Add(txt)

                            Dim cv As New CompareValidator
                            cv.ID = String.Format("cv{0}", id)
                            cv.Operator = ValidationCompareOperator.DataTypeCheck
                            cv.ControlToValidate = txt.ID
                            cv.Font.Bold = True

                            Select Case res.FieldValidation.ToUpper
                                Case "INT"
                                    cv.Type = ValidationDataType.Integer
                                    cv.ErrorMessage = "Value Must Be Numeric"
                                    tCell2.Controls.Add(New LiteralControl("<br />"))
                                    tCell2.Controls.Add(cv)
                                Case "DOUBLE"
                                    cv.Type = ValidationDataType.Double
                                    cv.ErrorMessage = "Value Must Be Double"
                                    tCell2.Controls.Add(New LiteralControl("<br />"))
                                    tCell2.Controls.Add(cv)
                                Case "STRING"
                                    cv.Type = ValidationDataType.String
                                    cv.ErrorMessage = "Value Must Be String"
                            End Select

                            If (res.IsRequired And fieldCount = 1) Then
                                rfv.ControlToValidate = txt.ID
                            End If
                    End Select

                    If (res.MaxDisplayNum > 1) Then
                        If (res.DefaultDisplayNum = fieldCount) Then
                            Dim hdnMore As New HiddenField
                            hdnMore.ID = String.Format("hdn{0}", res.FieldSetupID)
                            hdnMore.Value = res.DefaultDisplayNum.ToString()
                            hdnMore.EnableViewState = True
                            tCell2.Controls.Add(hdnMore)

                            Dim btnMore As New Button
                            btnMore.EnableViewState = True
                            btnMore.ID = res.FieldSetupID
                            btnMore.Text = "Add More"
                            btnMore.CssClass = "buttonSmall"
                            btnMore.Visible = res.DefaultDisplayNum <> res.MaxDisplayNum
                            btnMore.OnClientClick = "SetAddMore(" + res.FieldSetupID.ToString() + ")"
                            tCell2.Controls.Add(New LiteralControl("<br />"))
                            tCell2.Controls.Add(btnMore)
                        End If
                        fieldCount += 1
                    End If
                Next

                If (Not String.IsNullOrEmpty(res.Description)) Then
                    Dim img As New Image
                    img.EnableViewState = True
                    img.ID = String.Format("img{0}", res.FieldSetupID)
                    img.ImageUrl = "~\Design\Icons\png\24x24\help.png"
                    img.Attributes.Add("onmouseover", String.Format("Tip('{0}',true,null,true,true,WIDTH,'',TITLEBGCOLOR,'#6494C8')", res.Description))
                    img.Attributes.Add("onmouseout", "UnTip()")

                    tCell2.Controls.Add(img)
                End If

                If (res.IsRequired) Then
                    rfv.Font.Bold = True
                    tCell2.Controls.Add(New LiteralControl("<br />"))
                    tCell2.Controls.Add(rfv)
                End If

                tRow.Cells.Add(tCell2)
                tbl.Rows.Add(tRow)
            Next

            hdnAddMore.Value = String.Empty

            If (rf(0).HasDistribution) Then
                Dim tRowDistribution As New TableRow()
                Dim tCellDistribution As New TableCell()
                Dim tCell2Distribution As New TableCell()
                tCellDistribution.CssClass = "RequestCell1"
                tCell2Distribution.CssClass = "RequestCell2"
                Dim lblDistribution As New Label
                lblDistribution.Text = "Distribution"
                lblDistribution.EnableViewState = True
                lblDistribution.ID = "lblDistribution"
                tCellDistribution.Controls.Add(lblDistribution)
                tRowDistribution.Cells.Add(tCellDistribution)

                Dim txtDistribution As New TextBox
                txtDistribution.Text = String.Empty
                txtDistribution.EnableViewState = True
                txtDistribution.ID = String.Format("txtDistribution")
                txtDistribution.Width = 150

                Dim aceDistribution As New AjaxControlToolkit.AutoCompleteExtender
                aceDistribution.TargetControlID = "txtDistribution"
                aceDistribution.ServiceMethod = "GetActiveDirectoryNames"
                aceDistribution.ServicePath = "~/webservice/AutoCompleteService.asmx"
                aceDistribution.MinimumPrefixLength = 1
                aceDistribution.CompletionSetCount = 20
                aceDistribution.OnClientItemSelected = "GetValue"

                Dim lst As New ListBox
                lst.ID = "lstDistribution"
                lst.EnableViewState = True
                lst.Style.Add("border-style", "none")
                lst.Style.Add("border-width", "0px")
                lst.Style.Add("border", "none")

                If (Not String.IsNullOrEmpty(Request.Form(hdnDistribution.UniqueID))) Then
                    Dim distribution() As String = Regex.Split(Request.Form(hdnDistribution.UniqueID), ",")

                    If (distribution.Count > 0) Then
                        For Each s As String In distribution
                            lst.Items.Add(s)
                        Next
                    End If
                Else
                    Dim valueDist As List(Of String) = RequestManager.GetRequestDistribution(rf(0).RequestID)
                    lst.DataSource = valueDist
                    lst.DataBind()

                    hdnDistribution.Value = String.Join(",", New List(Of String)(valueDist).ToArray())
                End If

                tCell2Distribution.Controls.Add(txtDistribution)
                tCell2Distribution.Controls.Add(aceDistribution)
                tCell2Distribution.Controls.Add(New LiteralControl("<br />"))
                tCell2Distribution.Controls.Add(lst)
                tRowDistribution.Cells.Add(tCell2Distribution)
                tbl.Rows.Add(tRowDistribution)
            End If

            pnlRequest.Controls.Add(tbl)
        End If

        MyBase.OnInit(e)
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Init
        notMain.Notifications.Clear()

        If (Page.IsPostBack) Then
            Page.SetFocus(Helpers.GetPostBackControl(Page))
        Else
            tbl.Attributes.Remove("border")

            If (String.IsNullOrEmpty(hdnRequestTypeID.Value)) Then
                Response.Redirect(String.Format("/Request/Default.aspx"), True)
            End If

            BuildMenu()
        End If
    End Sub
#End Region

#Region "Button Events"
    Protected Sub upload_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim id As String = DirectCast(sender, Button).ID
        Dim fu As FileUpload = DirectCast(Helpers.FindControlRecursive(tbl, id.Replace("btnfu", "fu")), FileUpload)
        Dim txt As TextBox = DirectCast(Helpers.FindControlRecursive(tbl, id.Replace("btnfu", "txt")), TextBox)
        Dim hyp As HyperLink = DirectCast(Helpers.FindControlRecursive(tbl, id.Replace("btnfu", "hyp")), HyperLink)
        Dim img As Image = DirectCast(Helpers.FindControlRecursive(tbl, id.Replace("btnfu", "img")), Image)

        If (Not String.IsNullOrEmpty(fu.PostedFile.FileName)) Then
            hyp.Style.Add("display", "")
            img.Style.Add("display", "")
            fu.Style.Add("display", "none")
            DirectCast(sender, Button).Style.Add("display", "none")
            hyp.Text = fu.FileName
            hyp.NavigateUrl = String.Format("~\Handlers\Download.ashx?file={0}&path={1}", hyp.Text, String.Concat(Server.MapPath(Remi.Core.REMIConfiguration.UploadDirectory()), lblRequest.Text))

            Dim uploadDir = Server.MapPath(String.Concat(Remi.Core.REMIConfiguration.UploadDirectory(), lblRequest.Text))

            If (Not Directory.Exists(uploadDir)) Then
                Directory.CreateDirectory(uploadDir)
            End If

            fu.SaveAs(String.Concat(uploadDir, "\", fu.FileName))
            txt.Text = fu.FileName
        Else
            txt.Text = String.Empty
        End If
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSave.Click
        Dim req As String = IIf(Request.QueryString.Item("req") Is Nothing, String.Empty, Request.QueryString.Item("req"))
        Dim rf As RequestFieldsCollection

        If (Not String.IsNullOrEmpty(req)) Then
            rf = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, False, req)
        Else
            rf = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, False, String.Empty)
        End If

        If (rf IsNot Nothing) Then
            For Each res In rf
                Dim id As String = "0"
                Dim fieldCount As Int32 = 1
                id = res.FieldSetupID

                For i As Int32 = 1 To res.MaxDisplayNum
                    Dim con As New Control

                    If (res.MaxDisplayNum > 1) Then
                        id = String.Format("{0}-{1}", res.FieldSetupID.ToString(), fieldCount.ToString())
                    End If

                    Select Case res.FieldType.ToUpper()
                        Case "ATTACHMENT"
                            con = Helpers.FindControlRecursive(tbl, String.Format("txt{0}", id))
                        Case "CHECKBOX"
                            con = Helpers.FindControlRecursive(tbl, String.Format("chk{0}", id))
                        Case "DATETIME"
                            con = Helpers.FindControlRecursive(tbl, String.Format("dt{0}", id))
                        Case "DROPDOWN"
                            con = Helpers.FindControlRecursive(tbl, String.Format("ddl{0}", id))
                        Case "LINK"
                            con = Helpers.FindControlRecursive(tbl, String.Format("lnktxt{0}", id))
                        Case "RADIOBUTTON"
                            con = Helpers.FindControlRecursive(tbl, String.Format("rb{0}", id))
                        Case "TEXTAREA"
                            con = Helpers.FindControlRecursive(tbl, String.Format("txtArea{0}", id))
                        Case "TEXTBOX"
                            con = Helpers.FindControlRecursive(tbl, String.Format("txt{0}", id))
                    End Select

                    If (con IsNot Nothing) Then
                        If (res.FieldType.ToUpper() = "CHECKBOX") Then
                            res.Value = If(Request.Form(con.UniqueID) = "on", True, False)
                        Else
                            res.Value = Request.Form(con.UniqueID)
                        End If
                    Else
                        res.Value = String.Empty
                    End If

                    If (res.MaxDisplayNum > 1) Then
                        res.Sibling(fieldCount - 1).Value = res.Value
                        fieldCount += 1
                    End If
                Next
            Next

            Dim distribution() As String

            If (Not String.IsNullOrEmpty(hdnDistribution.Value)) Then
                distribution = Request.Form(hdnDistribution.UniqueID).ToString().Split(New [Char]() {","c}, StringSplitOptions.RemoveEmptyEntries)
            Else
                distribution = New String() {""}
            End If

            Dim saveSuccess As Boolean = RequestManager.SaveRequest(hdnRequestType.Value, rf, UserManager.GetCurrentUser.UserName, distribution.Where(Function(s) s <> String.Empty).ToList())

            If (saveSuccess) Then
                notMain.Notifications.AddWithMessage("Saved Request Successful!", NotificationType.Information)
                Dim requestNumber As String = rf(0).RequestNumber
                Dim rec = (From rb In New Remi.Dal.Entities().Instance().Requests Where rb.RequestNumber = requestNumber And rb.BatchID > 0).FirstOrDefault()

                If (rec IsNot Nothing) Then
                    If (setup.Visible) Then
                        setup.BatchID = rec.BatchID
                        setup.QRANumber = requestNumber
                        notMain.Notifications.AddWithMessage("Saved Parametric Setup Successful!", NotificationType.Information)
                        setup.Save()
                    End If

                    If (setupEnv.Visible) Then
                        setupEnv.BatchID = rec.BatchID
                        setupEnv.QRANumber = requestNumber
                        notMain.Notifications.AddWithMessage("Saved Environmental Setup Successful!", NotificationType.Information)
                        setupEnv.Save()
                    End If
                End If

                If (rf(0).NewRequest) Then
                    Response.Redirect(String.Format("~/Request/Request.aspx?type={0}&req={1}", hdnRequestType.Value, requestNumber), True)
                End If

                BuildMenu()
            Else
                notMain.Notifications.AddWithMessage("Saved Failed!", NotificationType.Errors)
            End If
        End If
    End Sub
#End Region

#Region "Events"
    Protected Sub UpdatePanel_Unload(ByVal sender As Object, ByVal e As EventArgs)
        Dim mi As MethodInfo = GetType(ScriptManager).GetMethods((BindingFlags.NonPublic Or BindingFlags.Instance)).Where(Function(i) i.Name.Equals("System.Web.UI.IScriptManagerInternal.RegisterUpdatePanel")).FirstOrDefault()
        mi.Invoke(ScriptManager.GetCurrent(Page), New Object() {CType(sender, UpdatePanel)})
    End Sub

    Protected Sub ddl_SelectedIndexChanged(ByVal sender As Object, ByVal e As EventArgs)
        Dim req As String = IIf(Request.QueryString.Item("req") Is Nothing, String.Empty, Request.QueryString.Item("req"))
        Dim ddl As DropDownList = DirectCast(sender, DropDownList)
        Dim id As Int32
        Dim val As String = ddl.SelectedValue
        Dim rfParent As New RequestFields
        Dim rfChild As New RequestFields
        Int32.TryParse(ddl.ID.Replace("ddl", String.Empty), id)

        Dim rf As RequestFieldsCollection
        If (Not String.IsNullOrEmpty(req)) Then
            rf = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, False, req)
        Else
            rf = RequestManager.GetRequestFieldSetup(hdnRequestType.Value, False, String.Empty)
        End If

        For Each field In rf
            If (field.IntField = "RequestedTest" And field.HasIntegration And field.NewRequest And field.FieldSetupID = id) Then
                Dim jobID As Int32 = JobManager.GetJob(val).ID

                setup.Visible = True
                setupEnv.Visible = True
                pnlSetup.Visible = True
                setup.JobID = jobID
                setup.ProductID = 0
                setup.JobName = ddl.SelectedValue
                setup.ProductName = String.Empty
                setup.QRANumber = lblRequest.Text
                setup.BatchID = 0
                setup.TestStageType = TestStageType.Parametric
                setup.IsProjectManager = False
                setup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                setup.HasEditItemAuthority = True
                setup.OrientationID = 0
                setup.RequestTypeID = hdnRequestTypeID.Value
                setup.UserID = UserManager.GetCurrentUser.ID
                setup.DataBind()

                setupEnv.JobID = jobID
                setupEnv.BatchID = 0
                setupEnv.ProductID = 0
                setupEnv.JobName = ddl.SelectedValue
                setupEnv.ProductName = String.Empty
                setupEnv.QRANumber = lblRequest.Text
                setupEnv.TestStageType = TestStageType.EnvironmentalStress
                setupEnv.IsProjectManager = False
                setupEnv.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                setupEnv.HasEditItemAuthority = True
                setupEnv.OrientationID = 0
                setupEnv.RequestTypeID = hdnRequestTypeID.Value
                setupEnv.UserID = UserManager.GetCurrentUser.ID
                setupEnv.DataBind()
            End If
        Next

        For Each rec In (From p In rf Where p.ParentFieldSetupID = id Select p)
            Dim values As New List(Of String)

            If (rec.CustomLookupHierarchy IsNot Nothing) Then
                For Each ch In rec.CustomLookupHierarchy
                    If (ch.ParentLookup = val) Then
                        values.Add(ch.ChildLookup)
                    End If
                Next

                Dim con As DropDownList = DirectCast(Helpers.FindControlRecursive(tbl, String.Format("ddl{0}", rec.FieldSetupID)), DropDownList)
                con.Items.Clear()
                con.ClearSelection()

                If (values.Count = 0) Then
                    values = rec.OptionsType
                End If

                For Each o In values
                    con.Items.Add(o)
                Next
            End If
        Next
    End Sub

    Protected Sub chkDisplayChanges_CheckedChanged(sender As Object, e As EventArgs)
        If (DirectCast(sender, CheckBox).Checked) Then
            pnlDisplayChanges.Visible = True
            grdDisplayChanges.DataSource = RequestManager.GetRequestAuditLogs(lblRequest.Text)
            grdDisplayChanges.DataBind()
        Else
            pnlDisplayChanges.Visible = False
        End If
    End Sub

    Protected Sub grdDisplayChanges_PreRender() Handles grdDisplayChanges.PreRender
        Helpers.MakeAccessable(grdDisplayChanges)
    End Sub
#End Region
End Class