<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="true" EnableEventValidation="false" MaintainScrollPositionOnPostback="true" AutoEventWireup="true" ValidateRequest="false" Inherits="Remi.Relab_Measurements" Codebehind="Measurements.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="~/Controls/Measurements.ascx" TagName="Measurements" TagPrefix="msm" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblHeader"></asp:Label></h1><br />
    
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_msmMeasuerments_grdResultMeasurements').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [0],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgCancelAction" ToolTip="Go Back to Overview" runat="server" />
                <asp:HyperLink ID="hypCancel" runat="server">Results</asp:HyperLink>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgVersions" ToolTip="Go To Versions" runat="server" />
                <asp:HyperLink ID="hypVersions" runat="server" Target="_blank">Versions</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlLeftMenuFilter">
        <h3>Filter</h3>
        <ul>
            <li>
                <asp:DropDownList runat="server" ID="ddlTestStage" Width="150px" DataTextField="TestStageName" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:DropDownList runat="server" ID="ddlTests" Width="150px" DataTextField="TestName" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:DropDownList runat="server" ID="ddlUnits" Width="150px" DataTextField="BatchUnitNumber" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:Button runat="server" ID="btnSubmit" Text="Query Measurements" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="Content" runat="Server">
<asp:Label runat="server" ID="lblNoResults" Visible="false"><h2>No Measurements For Selected Criteria</h2></asp:Label>
    <asp:Panel runat="server" ID="pnlMeasurements">
        <asp:HiddenField runat="server" ID="hdnUnit" />
        <asp:HiddenField runat="server" ID="hdnResultID" />
        <asp:HiddenField runat="server" ID="hdnBatchID" />
        
        <a class="test-popup-link" visible="false">popup</a>
        <div id="my-popup" class="mfp-hide white-popup">Inline popup</div>         
        <msm:Measurements runat="server" ID="msmMeasuerments" Visible="false" ShowExport="true" EnableViewState="true" ShowFailsOnly="false" IncludeArchived="false" DisplayMode="RelabDisplay" EmptyDataTextInformation="There is no information found for this result." EmptyDataTextMeasurement="There were no measurements found for this result." />
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>