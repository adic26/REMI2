<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"
    MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Developer_Default" Codebehind="Default.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
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
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server"></asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>