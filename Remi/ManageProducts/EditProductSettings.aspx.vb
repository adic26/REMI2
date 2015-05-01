Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Imports REMI.Contracts
Imports REMI.Core
''' <summary>
''' PLEASE NOTE
''' Becuase this page is for storing settings I also want to potentially store XML. By default ASP.NET validates out
''' any requests containing things that look like cross site scripting or injection attacks. For this reason I have disabled this
''' feature on this page. So if you add any inputs MAKE SURE you do your own validation on the inputs (or like i do, immediately 
''' convert them in to safe strings by HTML-encoding them)
''' </summary>
''' <remarks></remarks>
Partial Class ManageProducts_EditProductSettings
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim productName As String = Request.QueryString.Get("id")
            If Not String.IsNullOrEmpty(productName) Then
                Dim id As Int32
                Int32.TryParse(productName, id)
                ProcessProduct(id)
            End If
        End If
    End Sub

    Protected Sub UpdateGridviewHeaders() Handles grdSettings.PreRender
        Helpers.MakeAccessable(grdSettings)
    End Sub

    Protected Sub DatabindGridView()
        grdSettings.DataSource = ProductGroupManager.GetProductSettings(hdnLookupID.Value)
        grdSettings.DataBind()
    End Sub

    Protected Sub ProcessProduct(ByVal lookupid As Int32)
        Dim instance = New Remi.Dal.Entities().Instance()
        Dim productName As String = (From l In instance.Lookups Where l.LookupID = lookupid Select l.Values).FirstOrDefault()
        hdnLookupID.Value = lookupid
        lblProductName.Text = "Edit " + productName + " Settings"
        hypCancel.NavigateUrl = REMIWebLinks.GetProductInfoLink(hdnLookupID.Value)
        hypRefresh.NavigateUrl = REMIWebLinks.GetSetProductSettingsLink(hdnLookupID.Value)
        DatabindGridView()
        pnlLeftMenuActions.Visible = True

        Dim pl = (From l In instance.Lookups Where l.LookupType.Name = "MFIFunctionalMatrix" Or l.LookupType.Name = "SFIFunctionalMatrix" Or l.LookupType.Name = "AccFunctionalMatrix" Order By l.LookupType.Name, l.Values _
                  Select New With {.LookupID = l.LookupID, .Type = l.LookupType.Name, .Values = l.Values, _
                                   .HasAccess = If((From p In instance.ProductLookups Where p.Lookup.LookupID = l.LookupID And p.Product.LookupID = lookupid Select p.ID).FirstOrDefault() > 0, True, False) _
                                  })

        gdvFunctional.DataSource = pl
        gdvFunctional.DataBind()
    End Sub

    Protected Sub chkAccess_OnCheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim chk As CheckBox = DirectCast(sender, CheckBox)
        Dim selRowIndex As Int32 = DirectCast(chk.Parent.Parent, GridViewRow).RowIndex
        Dim LookupID As Int32 = gdvFunctional.DataKeys(selRowIndex).Values(0)

        ProductGroupManager.ChangeAccess(LookupID, hdnLookupID.Value, chk.Checked)
        Dim instance = New REMI.Dal.Entities().Instance()
        gdvFunctional.DataSource = (From l In instance.Lookups Where l.LookupType.Name = "MFIFunctionalMatrix" Or l.LookupType.Name = "SFIFunctionalMatrix" Or l.LookupType.Name = "AccFunctionalMatrix" Order By l.LookupType.Name, l.Values _
                  Select New With {.LookupID = l.LookupID, .Type = l.LookupType.Name, .Values = l.Values, _
                                   .HasAccess = If((From p In instance.ProductLookups Where p.Lookup.LookupID = l.LookupID And p.Product.LookupID = hdnLookupID.Value Select p.ID).FirstOrDefault() > 0, True, False) _
                                  })
        gdvFunctional.DataBind()
    End Sub

    Protected Sub SetGvwHeader() Handles gdvFunctional.PreRender
        Helpers.MakeAccessable(gdvFunctional)
    End Sub

    Protected Function ValidateProductGroup() As Boolean
        If Not String.IsNullOrEmpty(hdnLookupID.Value) Then
            Return True
        End If

        notMain.Add("There is no product group set. Cannot continue.", NotificationType.Errors)
        Return False
    End Function

    Protected Sub btnAddNewSetting_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAddNewSetting.Click
        notMain.Clear()
        'validate the bits
        If Not ValidateProductGroup() Then
            Exit Sub
        End If

        If txtNewSettingName.Text <> Nothing AndAlso String.IsNullOrEmpty(txtNewSettingName.Text.Trim) Then
            notMain.Add("The setting must have a name.", NotificationType.Errors)
            Exit Sub
        End If
        If txtNewSettingDefaultValue.Text <> Nothing AndAlso String.IsNullOrEmpty(txtNewSettingDefaultValue.Text.Trim) Then
            txtNewSettingDefaultValue.Text = String.Empty
        End If
        'add the setting

        If Not ProductGroupManager.SaveSetting(hdnLookupID.Value, System.Web.HttpUtility.HtmlEncode(txtNewSettingName.Text), System.Web.HttpUtility.HtmlEncode(txtNewSettingValue.Text), System.Web.HttpUtility.HtmlEncode(txtNewSettingDefaultValue.Text)) Then
            notMain.Add("Could not save this setting.", NotificationType.Errors)
        End If

        'refresh the gridview
        DatabindGridView()
    End Sub

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        notMain.Clear()
        If Not ValidateProductGroup() Then
            Exit Sub
        End If
        Dim txtValueText As TextBox
        Dim txtDefaultValueText As TextBox
        Dim chkUse As CheckBox

        For Each r As GridViewRow In grdSettings.Rows
            If r.RowType = DataControlRowType.DataRow Then
                txtValueText = (DirectCast(r.FindControl("txtValueText"), TextBox))
                txtDefaultValueText = (DirectCast(r.FindControl("txtDefaultValueText"), TextBox))
                chkUse = (DirectCast(r.FindControl("chkUse"), CheckBox))

                If txtValueText IsNot Nothing And txtValueText.Text.Trim().Length > 0 And chkUse.Checked Then
                    If Not ProductGroupManager.SaveSetting(hdnLookupID.Value, grdSettings.DataKeys(r.RowIndex).Value, txtValueText.Text, txtDefaultValueText.Text) Then
                        notMain.Add("Could not save " + grdSettings.DataKeys(r.RowIndex).Value + " with Value:" + txtValueText.Text + " and Default: " + txtDefaultValueText.Text + ".", NotificationType.Errors)
                    End If
                End If
            End If
        Next
        DatabindGridView()

        Response.Redirect(REMIWebLinks.GetProductInfoLink(hdnLookupID.Value), True)
    End Sub
End Class
