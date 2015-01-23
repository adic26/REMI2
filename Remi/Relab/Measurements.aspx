<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="false" MaintainScrollPositionOnPostback="true" AutoEventWireup="true" Inherits="Remi.Measurements" Codebehind="Measurements.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="~/Controls/Measuerments.ascx" TagName="Measuerments" TagPrefix="msm" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblHeader"></asp:Label></h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <script type="text/javascript" src='<%= ResolveUrl("~/Design/scripts/wz_tooltip.js")%>'></script>
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgCancelAction" ToolTip="Go Back to Overview" runat="server" />
                <asp:HyperLink ID="hypCancel" runat="server">Results</asp:HyperLink>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/xls_file.png" ID="imgExportAction" runat="server" />
                <asp:LinkButton ID="lnkExportAction" runat="Server" Text="Export Measurements" />
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
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
<asp:Label runat="server" ID="lblNoResults" Visible="false"><h2>No Measurements For Selected Criteria</h2></asp:Label>
    <asp:Panel runat="server" ID="pnlMeasurements">
        <asp:HiddenField runat="server" ID="hdnUnit" />
        
        <msm:Measuerments runat="server" ID="msmMeasuerments" ShowFailsOnly="false" IncludeArchived="false" DisplayMode="RelabDisplay" EmptyDataTextInformation="There is no information found for this result." EmptyDataTextMeasurement="There were no measurements found for this result." />
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>