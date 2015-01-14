<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/bootstrap-select.css" rel="Stylesheet"  />
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/bootstrap.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/jquery.taginput.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/jQueryUI/jquery-ui-1.10.4.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/DataTable CSS/jquery.dataTables.css" rel="Stylesheet" />
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-2.1.1.js"></script>
    <script type="text/javascript" src="../Design/scripts/DataTables/jquery.dataTables.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/jquery.taginput.src.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap-select.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap.js"></script>
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-ui-1.10.4.min.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js" ></script>
    <script type="text/javascript" src="../Design/scripts/ToolBox.js"></script>
    <script type="text/javascript" src="../Design/scripts/ReportScript.js"></script>
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
   
            

    <div class="row">
        <div class="col-lg-6">
            <div class="input-group input-group-sm">
                <div class="input-group-btn">
                    <!-- Button and dropdown menu -->
                    <select id="bs_StagesField" class="selectpicker show-tick" title="Select Jobs..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_ddlSearchField" class="selectpicker show-tick" title="Select Request..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_TestField" class="selectpicker show-tick" title="Select Test..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_RealStages" class="selectpicker show-tick" title="Select Stages..." multiple data-size="auto" data-selected-text-format="count"></select>
                    <button id="bs_OKayButton" type="button" class="btn btn-primary" autocomplete="off">ADD</button>
                </div>
            </div>
        </div>
    </div>
    
        
    <ul id="FinalItemsList" class="list-group"></ul>
    <button id="bs_searchButton" type="button" class="btn btn-primary" autocomplete="off">Search</button>
     
    
    <table id="searchResults">
    </table>

    <button id="bs_export" type="button" class="btn btn-primary" autocomplete="off">Export</button>


    <asp:TextBox runat="server" ID="txtSearchTerm" style="display:none;" ></asp:TextBox>
    <asp:Button runat="server" ID="btnSave" Text="Add" OnClick="btnSave_Click" style="display:none;" />
    <br />
    <asp:DropDownList runat="server" ID="ddlTests" Width="150px" style="display:none;" DataTextField="TestName" DataValueField="ID" AppendDataBoundItems="true"></asp:DropDownList>

    <br /><asp:ListBox runat="server" ID="lstSearchTerms" style="display:none;">
    </asp:ListBox>

    <br />
    <asp:Button runat="server" ID="btnSearch" Text="Search" OnClick="btnSearch_Click" style="display:none;"></asp:Button>


    <asp:Button ID="postback" runat="server" Text="Search" style="display:none;" />


    <asp:GridView runat="server" ID="grdRequestSearch" AutoGenerateColumns="true" CssClass="myGrid"></asp:GridView>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>

