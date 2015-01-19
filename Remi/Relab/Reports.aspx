<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

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
    <script type="text/javascript" src="../Design/scripts/ReportScript.js"></script>
    <!--include BlockUI -->
    <script type="text/javascript" src="../Design/scripts/jQueryUI/jquery.blockUI.js"></script>
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
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    Use "*" at beginning for LIKE and "-" at beginning for NOT LIKE
    <div class="row">
        <div class="col-lg-6">
            <div class="input-group input-group-sm">
                <div class="input-group-btn">
                    <!-- Button and dropdown menu -->
                    <select id="bs_ddlSearchField" class="selectpicker show-tick" title="Select Request..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_StagesField" class="selectpicker show-tick" title="Select Jobs..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_RealStages" class="selectpicker show-tick" title="Select Stages..." multiple data-size="auto" data-selected-text-format="count"></select>
                    <select id="bs_TestField" class="selectpicker show-tick" title="Select Test..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_Additional" class="selectpicker show-tick" title="Select Additional..." multiple data-size="15" data-selected-text-format="count">
                        <option value="--aMeasurement">Measurement Name</option>
                        <option value="--aBSN">BSN</option>
                        <option value="--aIMEI">IMEI</option>
                        <option value="--aUnit">Unit</option>
                        <option value="--aResultArchived">Results Archived</option>
                        <option value="--aResultInfoArchived">Info Archived</option>
                        <option value="--aInfoName">Information Name</option>
                        <option value="--aInfoValue">Information Value</option>
                        <option value="--aTestRunStartDate">Test Run Start Date</option>
                        <option value="--aTestRunEndDate">Test Run End Date</option>
                        <option value="--aParam">Parameter</option>
                    </select>
                    <button id="bs_OKayButton" type="button" class="btn btn-primary" autocomplete="off">ADD</button>
                </div>
            </div>
        </div>
    </div>
        
    <div class="LoadingModal" id="LoadingModal" style="display:none;"></div>
    <div class="LoadingGif" id="LoadingGif" style="display:none;"></div>
            
    <ul id="FinalItemsList" class="list-group"></ul>
    <button id="bs_searchButton" type="button" class="btn btn-primary" autocomplete="off">Search</button>
      
    <div class="table">
        <table id="searchResults"></table>
        <button id="bs_export" type="button" class="btn btn-primary" autocomplete="off">Export</button>
    </div>   

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>