<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" ValidateRequest="false" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Developer_Default" Codebehind="Default.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Configuration</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>Developer Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../../Design/Icons/png/24x24/link.png" ID="Image4" runat="server" />
                <asp:HyperLink ID="hplLogs" runat="Server" Text="Error Logs" NavigateUrl="~/Admin/Developer/Logs.aspx" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" EnableViewState="False" />

    <asp:DropDownList runat="server" ID="ddlMode" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
    <asp:DropDownList runat="server" ID="ddlType" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
    <asp:DropDownList runat="server" ID="ddlVersions"></asp:DropDownList>
    <asp:DropDownList runat="server" ID="ddlName"></asp:DropDownList>
    <asp:Button runat="server" ID="btnQuery" Text="Query" CssClass="buttonSmall" OnClick="btnQuery_Click" />
    <br /><br />
    <asp:TextBox runat="server" ID="txtXML" Text="" TextMode="MultiLine" Rows="30" Columns="200" Visible="false"></asp:TextBox><br />
    <asp:Button runat="server" ID="btnSave" CssClass="buttonSmall" Text="Save" OnClick="btnSave_Click" Visible="false" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>