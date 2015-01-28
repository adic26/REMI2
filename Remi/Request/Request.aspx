<%@ Page Language="vb" EnableViewState="true" AutoEventWireup="false" CodeBehind="Request.aspx.vb" Inherits="Remi.Request" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">    
    <asp:Panel runat="server" ID="pnlRequest" EnableViewState="true">
        <asp:Table runat="server" ID="tbl" Width="70%" EnableViewState="true">

        </asp:Table>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>