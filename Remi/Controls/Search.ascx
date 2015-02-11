<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="Search.ascx.vb" Inherits="Remi.Search1" %>
    <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/bootstrap-select.css" rel="Stylesheet"  />
    <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/bootstrap.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/BootstrapCSS/jquery.taginput.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/jQueryUI/jquery-ui-1.10.4.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/DataTableCSS/jquery.dataTables.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/DataTableCSS/dataTables.tableTools.css" rel="Stylesheet" />
    <link href="../Design/jQueryCSS/jQueryUI/jquery-ui.css" rel="stylesheet" />

    <script type="text/javascript" src="../Design/scripts/DataTables/jquery.dataTables.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/jquery.taginput.src.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap-select.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap.js"></script>
    <script type="text/javascript" src="../Design/scripts/jQueryUI/jquery-ui-1.10.4.min.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js" ></script>
    <script type="text/javascript" src="../Design/scripts/ToolBox.js"></script>
    <script type="text/javascript" src="../Design/scripts/DataTables/dataTables.tableTools.js"></script>
    <!--include BlockUI -->
    <script type="text/javascript" src="../Design/scripts/jQueryUI/jquery.blockUI.js"></script>

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
                    </select>
                    
                    <input id="bs_OKayButton" type="button" value="ADD" class="btn btn-primary" autocomplete="off" />
                </div>
            </div>
        </div>
    </div>

    <div id="FinalItemsList" class="list-group"></div>
    <input id="bs_searchButton" type="button" class="btn btn-primary" autocomplete="off" value="SEARCH" />
    <asp:HiddenField runat="server" ID="hdnUser" />
    <asp:HiddenField runat="server" ID="hdnUserID" />
    <asp:HiddenField runat="server" ID="hdnTop" />
    <div class="info"></div>
    <div class="table"> 
        <table id="searchResults"></table>
        <div class="IE_empty"></div>
    </div>
    <asp:HiddenField runat="server" ID="hdnRequestType" />