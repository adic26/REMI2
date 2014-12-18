<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/bootstrap-select.css" rel="Stylesheet"  />
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/bootstrap.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/Bootstrap CSS/jquery.taginput.css" rel="Stylesheet" />
    <link type="text/css" href="../Design/jQueryCSS/jQueryUI/jquery-ui-1.10.4.css" rel="Stylesheet" />
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-2.1.1.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/jquery.taginput.src.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap-select.js"></script>
    <script type="text/javascript" src="../Design/scripts/Bootstrap/bootstrap.js"></script>
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-ui-1.10.4.min.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js" ></script>
    <script type="text/javascript" src="../Design/scripts/ToolBox.js"></script>
    <script type="text/javascript" src="../Design/scripts/ReportScript.js"></script>


    <script type="text/javascript">
        $('.selectpicker').selectpicker({
          style: 'btn-info',
          size: 4
        });
    </script>
</asp:Content>



<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Reports</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>

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
   
            

    <div class="row">
        <div class="col-lg-6">
            <div class="input-group input-group-sm">
                <div class="input-group-btn">
                    <!-- Button and dropdown menu -->
                    <select id="bs_StagesField" class="selectpicker" title="Select Jobs..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_ddlSearchField" class="selectpicker" title="Select Request..." multiple data-size="15" data-selected-text-format="count"></select>
                    <select id="bs_TestField" class="selectpicker" title="Select Test..." multiple data-size="15" data-selected-text-format="count"></select>
                    <button id="bs_OKayButton" type="button" data-loading-text="Loading..." class="btn btn-primary" autocomplete="off">ADD</button>
                </div>
            </div>
        </div>
    </div>
    
        
    <ul id="FinalItemsList" class="list-group">
    </ul>
    
    


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

