<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ReqDefault" CodeBehind="Default.aspx.vb" EnableEventValidation="false" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
     <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/bootstrap-select.css" rel="Stylesheet"  />
    <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/bootstrap.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/jquery.taginput.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/jQueryUI/jquery-ui-1.10.4.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/DataTableCSS/jquery.dataTables.css" rel="Stylesheet" />
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-1.11.1.js"></script>
    <script type="text/javascript" src="../Design/scripts/DataTables/jquery.dataTables.js"></script>
     <script type="text/javascript" src="../Design/scripts/Bootstrap/jquery.taginput.src.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap-select.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap.js"></script>
    <script type="text/javascript" src="../Design/scripts/jQueryUI/jquery-ui-1.10.4.min.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js" ></script>
    <script type="text/javascript" src="../Design/scripts/ToolBox.js"></script>
    <script type="text/javascript" src="../Design/scripts/RequestScript.js"></script>

</asp:Content>
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
        </ul>
    </asp:Panel>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <div class="row">
        <div class="col-lg-6">
            <div class="input-group input-group-sm">
                <div class="input-group-btn">
                    <!-- Button and dropdown menu -->
                    <select id="bs_ddlSearchField" class="selectpicker show-tick" title="Select Request..." multiple data-size="15" data-selected-text-format="count"></select>
                    <button id="bs_OKayButton" type="button" class="btn btn-primary" autocomplete="off">ADD</button>
                </div>
            </div>
        </div>
    </div>

     <ul id="FinalItemsList" class="list-group"></ul>
    <button id="bs_searchButton" type="button" class="btn btn-primary" autocomplete="off">Search</button>

     <table id="searchResults"></table>
    <button id="bs_export" type="button" class="btn btn-primary" autocomplete="off">Export</button>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>
