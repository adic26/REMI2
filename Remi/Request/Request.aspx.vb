Imports Remi.Bll
Imports Remi.Validation
Imports Remi.Contracts
Imports Remi.BusinessEntities 

Public Class Request
    Inherits System.Web.UI.Page

    Protected Sub ValidateBtn_Click(sender As Object, e As EventArgs)
        If Page.IsValid Then
        Else
        End If
    End Sub

    Protected Overrides Sub OnInit(e As System.EventArgs)
        Dim req As String = IIf(Request.QueryString.Item("req") Is Nothing, String.Empty, Request.QueryString.Item("req"))
        Dim type As String = IIf(Request.QueryString.Item("type") Is Nothing, String.Empty, Request.QueryString.Item("type"))
        Dim rf As RequestFieldsCollection

        If (Not String.IsNullOrEmpty(req)) Then
            rf = RequestManager.GetRequestFieldSetup(type, False, req)
        Else
            rf = RequestManager.GetRequestFieldSetup(type, False, String.Empty)
        End If

        If (rf IsNot Nothing) Then
            hdnRequestNumber.Value = rf(0).RequestNumber

            If (rf(0).NewRequest) Then
                chkDisplayChanges.Visible = False
            Else
                chkDisplayChanges.Visible = True
            End If

            If (rf(0).IsFromExternalSystem) Then
                If (rf(0).NewRequest) Then
                    Response.Redirect(String.Format("/Request/Default.aspx?rt={0}", type), True)
                Else
                    Response.Redirect((From rl In rf Where rl.IntField = "RequestLink" Select rl.Value).FirstOrDefault(), True)
                End If
            End If

            hdnRequestType.Value = rf(0).RequestType
            hdnRequestTypeID.Value = rf(0).RequestTypeID
            lblRequest.Text = rf(0).RequestNumber

            For Each res In rf
                Dim tRow As New TableRow()
                Dim tCell As New TableCell()
                Dim tCell2 As New TableCell()
                Dim lblName As New Label
                Dim rfv As New RequiredFieldValidator

                tCell.CssClass = "RequestCell1"
                tCell2.CssClass = "RequestCell2"

                lblName.Text = String.Format("{0}{1}", If(res.IsRequired, "<b><font color='red'>*</font></b>", ""), res.Name)
                lblName.EnableViewState = True
                lblName.ID = String.Format("lbl{0}", res.FieldSetupID)
                tCell.Controls.Add(lblName)
                tRow.Cells.Add(tCell)

                If (res.IsRequired) Then
                    rfv.EnableViewState = True
                    rfv.Enabled = True
                    rfv.ErrorMessage = "This Field Is Requierd"
                    rfv.ID = String.Format("rfv{0}", res.FieldSetupID)
                    rfv.Display = ValidatorDisplay.Static
                End If

                Select Case res.FieldType.ToUpper()
                    Case "CHECKBOX"
                        Dim chk As New CheckBox
                        chk.ID = String.Format("chk{0}", res.FieldSetupID)
                        chk.EnableViewState = True

                        Dim checked As Boolean = False
                        Boolean.TryParse(res.Value, checked)

                        chk.Checked = checked
                        chk.Text = String.Empty

                        tCell2.Controls.Add(chk)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = chk.ID
                        End If
                    Case "DATETIME"
                        Dim dt As New TextBox
                        dt.Text = res.Value
                        dt.EnableViewState = True
                        dt.ID = String.Format("dt{0}", res.FieldSetupID)
                        dt.Width = 500

                        Dim ce As New AjaxControlToolkit.CalendarExtender
                        ce.Enabled = True
                        ce.EnableViewState = True
                        ce.ID = String.Format("ce{0}", res.FieldSetupID)
                        ce.TargetControlID = dt.ID

                        tCell2.Controls.Add(dt)
                        tCell2.Controls.Add(ce)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = dt.ID
                        End If
                    Case "DROPDOWN"
                        Dim ddl As New DropDownList
                        ddl.ID = String.Format("ddl{0}", res.FieldSetupID)
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

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = ddl.ID
                        End If
                    Case "LINK"
                        Dim lnk As New HyperLink
                        lnk.ID = String.Format("lnk{0}", res.FieldSetupID)
                        lnk.EnableViewState = True
                        lnk.Text = res.Name
                        lnk.Target = "_blank"
                        lnk.NavigateUrl = res.Value
                        tCell2.Controls.Add(lnk)

                        Dim lnktxt As New TextBox
                        lnktxt.Text = res.Value
                        lnktxt.EnableViewState = True
                        lnktxt.ID = String.Format("lnktxt{0}", res.FieldSetupID)
                        lnktxt.Width = 500
                        If (res.IntField = "RequestLink") Then
                            lnktxt.Style.Add("display", "none")
                        End If
                        tCell2.Controls.Add(lnktxt)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = lnktxt.ID
                        End If
                    Case "RADIOBUTTON"
                        Dim rb As New RadioButtonList
                        rb.ID = String.Format("rb{0}", res.FieldSetupID)
                        rb.EnableViewState = True
                        rb.RepeatDirection = RepeatDirection.Horizontal
                        rb.CssClass = "RemoveBorder"

                        For Each o In res.OptionsType
                            rb.Items.Add(o)
                        Next

                        rb.SelectedValue = res.Value

                        tCell2.Controls.Add(rb)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = rb.ID
                        End If
                    Case "TEXTAREA"
                        Dim txtArea As New TextBox
                        txtArea.EnableViewState = True
                        txtArea.ID = String.Format("txtArea{0}", res.FieldSetupID)
                        txtArea.TextMode = TextBoxMode.MultiLine
                        txtArea.Width = Unit.Percentage(70)
                        txtArea.Rows = 20
                        txtArea.Text = res.Value
                        tCell2.Controls.Add(txtArea)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = txtArea.ID
                        End If
                    Case "TEXTBOX"
                        Dim txt As New TextBox
                        txt.Text = res.Value
                        txt.EnableViewState = True
                        txt.ID = String.Format("txt{0}", res.FieldSetupID)
                        txt.Width = 500
                        tCell2.Controls.Add(txt)

                        Dim cv As New CompareValidator
                        cv.ID = String.Format("cv{0}", res.FieldSetupID)
                        cv.Operator = ValidationCompareOperator.DataTypeCheck
                        cv.ControlToValidate = txt.ID

                        Select Case res.FieldValidation.ToUpper
                            Case "INT"
                                cv.Type = ValidationDataType.Integer
                                cv.ErrorMessage = "Value Must Be Numeric"
                            Case "DOUBLE"
                                cv.Type = ValidationDataType.Double
                                cv.ErrorMessage = "Value Must Be Double"
                            Case "STRING"
                                cv.Type = ValidationDataType.String
                                cv.ErrorMessage = "Value Must Be String"
                        End Select

                        tCell2.Controls.Add(cv)

                        If (res.IsRequired) Then
                            rfv.ControlToValidate = txt.ID
                        End If
                End Select

                If (res.IsRequired) Then
                    tCell2.Controls.Add(rfv)
                End If

                tRow.Cells.Add(tCell2)
                tbl.Rows.Add(tRow)
            Next

            pnlRequest.Controls.Add(tbl)
        End If

        MyBase.OnInit(e)
    End Sub

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
            mi.NavigateUrl = String.Format("/ScanForInfo/Default.aspx?QRA={0}", requestNumber)
            myMenu.Items(0).ChildItems.Add(mi)
            hypBatch.Visible = True
            hypBatch.NavigateUrl = String.Format("/ScanForInfo/Default.aspx?QRA={0}", requestNumber)

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
                Dim con As New Control

                Select Case res.FieldType.ToUpper()
                    Case "CHECKBOX"
                        con = Helpers.FindControlRecursive(tbl, String.Format("chk{0}", res.FieldSetupID))
                    Case "DATETIME"
                        con = Helpers.FindControlRecursive(tbl, String.Format("dt{0}", res.FieldSetupID))
                    Case "DROPDOWN"
                        con = Helpers.FindControlRecursive(tbl, String.Format("ddl{0}", res.FieldSetupID))
                    Case "LINK"
                        con = Helpers.FindControlRecursive(tbl, String.Format("lnktxt{0}", res.FieldSetupID))
                    Case "RADIOBUTTON"
                        con = Helpers.FindControlRecursive(tbl, String.Format("rb{0}", res.FieldSetupID))
                    Case "TEXTAREA"
                        con = Helpers.FindControlRecursive(tbl, String.Format("txtArea{0}", res.FieldSetupID))
                    Case "TEXTBOX"
                        con = Helpers.FindControlRecursive(tbl, String.Format("txt{0}", res.FieldSetupID))
                End Select

                If (res.FieldType.ToUpper() = "CHECKBOX") Then
                    res.Value = If(Request.Form(con.UniqueID) = "on", True, False)
                Else
                    res.Value = Request.Form(con.UniqueID)
                End If
            Next

            Dim saveSuccess As Boolean = RequestManager.SaveRequest(hdnRequestType.Value, rf, UserManager.GetCurrentUser.UserName)

            If (saveSuccess) Then
                BuildMenu()
                notMain.Notifications.AddWithMessage("Saved Successful!", NotificationType.Information)
            Else
                notMain.Notifications.AddWithMessage("Saved Failed!", NotificationType.Errors)
            End If
        End If
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
        Else
            pnlDisplayChanges.Visible = False
        End If
    End Sub

    Protected Sub grdDisplayChanges_PreRender() Handles grdDisplayChanges.PreRender
        Helpers.MakeAccessable(grdDisplayChanges)
    End Sub
End Class