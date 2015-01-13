<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Reports</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <br /><asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID"></asp:DropDownList>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/xls_file.png" ID="imgExportAction" runat="server"  EnableViewState="false"/>
                <asp:LinkButton ID="lnkExportAction" runat="Server" Text="Export Result" EnableViewState="false"  />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:DropDownList runat="server" ID="ddlSearchField" DataTextField="Name" DataValueField="ReqFieldSetupID" AppendDataBoundItems="false" EnableViewState="true"></asp:DropDownList>
    <asp:TextBox runat="server" ID="txtSearchTerm" ></asp:TextBox>
    <asp:Button runat="server" ID="btnSave" Text="Add" OnClick="btnSave_Click" />
    <br />
    <asp:DropDownList runat="server" ID="ddlTests" Width="150px" DataTextField="TestName" DataValueField="ID" AppendDataBoundItems="true"></asp:DropDownList>
    <br /><asp:ListBox runat="server" ID="lstSearchTerms"></asp:ListBox>

    <br />
    <asp:Button runat="server" ID="btnSearch" Text="Search" OnClick="btnSearch_Click" />

    <asp:GridView runat="server" ID="grdRequestSearch" AutoGenerateColumns="true"></asp:GridView>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>