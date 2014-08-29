<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ClearCache"
    Title="Clear Cache" Codebehind="ClearCache.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">

</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Clear Cache</h1>
    <asp:Button Text="Clear Cache" ID="btnClearCache" runat="server" />
    <asp:Label ID="lblSuccess" runat="server" ></asp:Label>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server"></asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>