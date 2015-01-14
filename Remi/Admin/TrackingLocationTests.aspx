<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="true" AutoEventWireup="false" CodeBehind="TrackingLocationTests.aspx.vb" Inherits="Remi.TrackingLocationTests" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>

    <script type="text/javascript">
        function AddRemoveTypeToTest_Click(testName, trackingType, rowID) {
            $.ajax({
                type: "POST",
                url: "TrackingLocationTests.aspx/AddRemoveTypeToTest",
                data: '{testName: "' + testName + '", trackingType: "' + trackingType + '" }',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    if (response.d == true) {

                        if (document.getElementById(rowID).children(0).checked) {
                            document.getElementById(rowID).style.backgroundColor = 'green';
                        } else {
                            document.getElementById(rowID).style.backgroundColor = 'white';
                        }

                    } else {
                        alert("Add Remove Type to Test Failed");
                    }
                },
                failure: function (response) {
                    alert("Add Remove Type to Test Failed");
                }
            });
        }

        $(document).ready(function () {
            $('table#ctl00_Content_gvwTypeTests').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });

        var _isInitialLoad = true;

        function pageLoad(sender, args) {
            if (_isInitialLoad) {
                _isInitialLoad = false;
                __doPostBack('<%= ddlTestType.ClientID %>', '');
            }
        }
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Tracking Location Types Tests</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>Admin Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:HyperLink ID="Hyperlink2" runat="Server" Text="Process Flow" NavigateUrl="~/Admin/Jobs.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="Image5" runat="server" />
                <asp:HyperLink ID="Hyperlink4" runat="Server" Text="Users" NavigateUrl="~/Admin/users.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image4" runat="server" />
                <asp:HyperLink ID="Hyperlink3" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="HyperLink7" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:hyperlink ID="Hyperlink8" runat="Server" Text="Tracking Locs" navigateurl="~/Admin/trackinglocations.aspx"/>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
        <h3>Filter</h3>
        <ul>
            <li>
                <asp:CheckBox runat="server" ID="chkArchived" Text="Archived" TextAlign="Right" AutoPostBack="true" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
<br />
    <asp:UpdatePanel ID="upTTT" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" EnableViewState="true">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="ddlTestType" />
            <asp:AsyncPostBackTrigger ControlID="ddlTrackType" />
        </Triggers>
        <ContentTemplate>
            <asp:UpdateProgress runat="server" ID="udpTTT" DynamicLayout="true" DisplayAfter="10" AssociatedUpdatePanelID="upTTT">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>
            Test Type: <asp:DropDownList runat="server" ID="ddlTestType" AutoPostBack="true"></asp:DropDownList><br />
            Tracking Type: <asp:DropDownList runat="server" ID="ddlTrackType" AutoPostBack="true" AppendDataBoundItems="true"></asp:DropDownList>
            <asp:GridView ID="gvwTypeTests" AutoGenerateColumns="true" runat="server" CssClass="FilterableTable" EnableViewState="False" EmptyDataText="There are no tracking types for tests.">
                <RowStyle CssClass="evenrow" />
                <AlternatingRowStyle CssClass="oddrow" />
            </asp:GridView>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>