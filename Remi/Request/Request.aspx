<%@ Page Language="vb" EnableViewState="true" CodeBehind="Request.aspx.vb" Inherits="Remi.Request" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" %>
<%@ Register assembly="propertygrid" namespace="PG" tagprefix="pg" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">    
<%--    <pg:PropertyGrid runat="server" ID="pg1" Width="1200" ShowHelp="true"></pg:PropertyGrid>--%>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>