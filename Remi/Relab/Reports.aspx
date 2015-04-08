<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../Controls/Search.ascx" TagName="Search" TagPrefix="uc2" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Advanced Search</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <br /><asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID" OnSelectedIndexChanged="ddlRequestType_SelectedIndexChanged"></asp:DropDownList>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc2:Search ID="srcRequest" runat="server" Visible="false" SearchScript="../Design/scripts/ReportScript.js" JQueryScript="../Design/scripts/jQuery/jquery-1.11.1.js" ExecuteTop="false" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>