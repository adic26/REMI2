<%@ Page Language="vb" EnableViewState="true" AutoEventWireup="false" CodeBehind="Request.aspx.vb" Inherits="Remi.Request" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <asp:HyperLink runat="server" ID="hypAdmin" Visible="false" Text="Admin" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypNew" Enabled="true" Text="Create Request" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:Button runat="server" ID="btnSave" Text="Save Request" CssClass="buttonSmall" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField runat="server" ID="hdnRequestType" />
    <asp:HiddenField runat="server" ID="hdnRequestTypeID" />

    <asp:Panel runat="server" ID="pnlRequest" EnableViewState="true">
        <asp:Table runat="server" ID="tbl" Width="70%" EnableViewState="true" CssClass="requestTable">

        </asp:Table>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>