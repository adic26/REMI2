<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ReqDefault" CodeBehind="Default.aspx.vb" EnableEventValidation="false" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Search.ascx" TagName="Search" TagPrefix="uc2" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
    <br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <br /><asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID" OnSelectedIndexChanged="ddlRequestType_SelectedIndexChanged"></asp:DropDownList>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypAdmin" Enabled="true" Text="Admin" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypNew" Enabled="true" Text="Create Request" Target="_blank"></asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc2:Search ID="srcRequest" runat="server" Visible="false" SearchScript="../Design/scripts/RequestScript.js" JQueryScript="../Design/scripts/jQuery/jquery-1.11.1.js" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>
