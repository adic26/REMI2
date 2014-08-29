<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"
    AutoEventWireup="false" Inherits="Remi.ManageProducts_EditProductSettings" ValidateRequest="false" Codebehind="EditProductSettings.aspx.vb" %>
    
<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" />
                <asp:HyperLink ID="hypRefresh" runat="server" ToolTip="Click to refresh the current page">Refresh</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>
            Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSave" runat="server" />
                <asp:LinkButton ID="lkbSave" runat="Server" Text="Save Settings" ToolTip="Click to save the current settings" /></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" ToolTip="Click to cancel any changes made to the current settings"
                        runat="server" />
                    <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
                </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>
        <asp:Label ID="lblProductName" runat="server"></asp:Label></h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField ID="hdnProductID" runat="server" />
    <asp:HiddenField ID="hdnProductName" runat="server" />
    <asp:HiddenField runat="server" ID="hdnIsActive" />
    <table style="width: 18%; height: 45px;">
        <tr>
            <td class="HorizTableFirstcolumn">
                Setting Name:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox ID="txtNewSettingName" runat="server" Height="16px" Width="166px"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Setting Value:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox ID="txtNewSettingValue" runat="server" Height="16px" Width="167px"></asp:TextBox>
            </td>
        </tr>
                <tr>
            <td class="HorizTableFirstcolumn">
                Default Value:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox ID="txtNewSettingDefaultValue" runat="server" Height="16px" Width="167px"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
            </td>
            <td class="HorizTableSecondColumn">
                <asp:Button runat="server" ID="btnAddNewSetting" Text="Save" CssClass="button" />
            </td>
        </tr>
    </table>
    <uc1:notifications ID="notMain" runat="server" />
    <asp:ToolkitScriptManager ID="ScriptManager1" runat="server"></asp:ToolkitScriptManager>
        
    QAP URL: <asp:TextBox ID="txtQAPLocation" runat="server" Width="507px" Rows="3"></asp:TextBox><br />

    <asp:AutoCompleteExtender runat="server" ID="aceTxtOwner" TargetControlID="txtTSDContact"
        ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20">
    </asp:AutoCompleteExtender>
    TSD Contact<asp:TextBox runat="server" ID="txtTSDContact"></asp:TextBox>

    <h2>Functional Tests:</h2>
    <asp:GridView runat="server" ID="gdvFunctional" AutoGenerateColumns="false" DataKeyNames="LookupID">
        <Columns>
            <asp:BoundField DataField="LookupID" HeaderText="LookupID" ReadOnly="true" SortExpression="LookupID" Visible="false" />
            <asp:BoundField DataField="Type" HeaderText="Type" ReadOnly="true" SortExpression="Type" />
            <asp:BoundField DataField="Values" HeaderText="Values" ReadOnly="true" SortExpression="Values" />
            <asp:TemplateField HeaderText="Access">
                <ItemTemplate>
                    <asp:CheckBox runat="server" ID="chkAccess" Checked='<%# Eval("HasAccess") %>' OnCheckedChanged="chkAccess_OnCheckedChanged" AutoPostBack="true" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <br />
    <asp:UpdatePanel ID="udpSettings" runat="server">
        <ContentTemplate>
            <asp:GridView ID="grdSettings" runat="server" AutoGenerateColumns="False" 
                DataKeyNames="KeyName" EmptyDataText="There are no settings for the product.">
                <RowStyle CssClass="evenrow" />
                <AlternatingRowStyle CssClass="oddrow" />
                <Columns>
                    <asp:TemplateField HeaderText="Use">
                        <ItemTemplate>
                            <asp:CheckBox runat="server" ID="chkUse" Checked='<%# Eval("ValueText") <> Nothing %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Name">
                        <ItemTemplate>
                            <asp:Label ID="lblKeyName" runat="server" Text='<%# Eval("KeyName") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Value">
                        <ItemTemplate>
                            <asp:TextBox runat="server" ID="txtValueText" Text='<%# Eval("ValueText") %>' Columns="40"  TextMode="MultiLine" Rows="2"/>
                        </ItemTemplate>
                    </asp:TemplateField>
                     <asp:TemplateField HeaderText="Default Value">
                        <ItemTemplate>
                            <asp:TextBox runat="server" ID="txtDefaultValueText" Text='<%# Eval("DefaultValue") %>' Columns="40"  TextMode="MultiLine" Rows="2"/>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
