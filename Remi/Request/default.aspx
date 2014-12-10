<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ReqDefault" CodeBehind="Default.aspx.vb" EnableEventValidation="false" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
    <br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>

    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <br /><asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID"></asp:DropDownList>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypAdmin" Enabled="true" Text="Admin" Target="_blank"></asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:DropDownList runat="server" ID="ddlSearchField" DataTextField="Name" DataValueField="ReqFieldSetupID" AppendDataBoundItems="false" EnableViewState="true"></asp:DropDownList>
    <asp:TextBox runat="server" ID="txtSearchTerm" ></asp:TextBox>
    <asp:Button runat="server" ID="btnSave" Text="Add" OnClick="btnSave_Click" />
    <br />
    <asp:ListBox runat="server" ID="lstSearchTerms"></asp:ListBox>

    <br />
    <asp:Button runat="server" ID="btnSearch" Text="Search" OnClick="btnSearch_Click" />

    <asp:GridView runat="server" ID="grdRequestSearch" AutoGenerateColumns="true"></asp:GridView>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>
