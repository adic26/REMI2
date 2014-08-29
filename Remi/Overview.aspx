<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" EnableViewState="true" ValidateRequest="false" Inherits="Remi.Overview" Title="Overview" Codebehind="Overview.aspx.vb" MaintainScrollPositionOnPostback="true" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="/Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        var _isInitialLoad = true;

        function pageLoad(sender, args) {
            if (_isInitialLoad) {
                _isInitialLoad = false;
                __doPostBack('<%= ddlTestCenters.ClientID %>', '');
            }
        }
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Overview</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
    
    <asp:UpdatePanel ID="updOverview" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" EnableViewState="true">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="ddlTestCenters" />
            <asp:AsyncPostBackTrigger ControlID="chkShowTRS" />
        </Triggers>
        <ContentTemplate>
            <asp:UpdateProgress runat="server" ID="UpdateProgress1" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updOverview">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>
            <h3>Filter</h3>
            <ul>
                <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTestCenterView" runat="server" />
                    <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="False" DataTextField="LookupType" DataValueField="LookupID"
                        AutoPostBack="true" Width="120px" ForeColor="#0033CC" EnableViewState="true">
                    </asp:DropDownList>
                </li>
                <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="imgShowTRS" runat="server" />
                    <asp:CheckBox runat="server" ID="chkShowTRS" Text="Show TRS" AutoPostBack="true" CausesValidation="true" TextAlign="Right" EnableViewState="true" />
                </li>
            </ul>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <br /><br />
    <asp:UpdatePanel runat="server" ID="upLoad" UpdateMode="Conditional" ChildrenAsTriggers="true" EnableViewState="true">
        <ContentTemplate>
            <script type="text/javascript">
                var prm = Sys.WebForms.PageRequestManager.getInstance();
                prm.add_pageLoaded(EndRequestOverall);

                function EndRequestOverall(sender, args) {
                    $('table#ctl00_Content_bscMainHR_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscMainIncoming_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscMainFA_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscMainReadyForStressing_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscMainInProgress_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscChamber_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });

                    $('table#ctl00_Content_bscMainTestingComplete_grdBatches').columnFilters(
                    {
                        caseSensitive: false,
                        underline: true,
                        wildCard: '*',
                        excludeColumns: [0, 17, 18],
                        alternateRowClassNames: ['evenrow', 'oddrow']
                    });
                }
            </script>

            <asp:Panel runat="server" ID="pnlShowTRS" Visible="false">
                <h3>TRS</h3>
                <asp:GridView runat="server" ID="gvwTRS" AutoGenerateColumns="true" EnableViewState="true" EmptyDataText="There are no TRS batches.">
                    <Columns>
                        <asp:TemplateField HeaderText="TRS" SortExpression="" ItemStyle-Width="4%">
                            <ItemTemplate>
                                <asp:HyperLink ID="hplTRS" runat="server" Text='<%# Eval("QRA") %>' Target="_blank" NavigateUrl='<%# "https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=" + Eval("RequestID").ToString() %>' EnableViewState="true"></asp:HyperLink>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </asp:Panel>
            
            <h3>Incoming</h3>
            <uc3:BatchSelectControl ID="bscMainIncoming" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'Incoming' batches ready." AutoGenerateEditButton="true" />
                      
            <h3>In Progress Parametric</h3>
            <uc3:BatchSelectControl ID="bscMainInProgress" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'In Progress' batches available." AutoGenerateEditButton="true" />
              
            <h3>In Progress Ready For Stressing</h3>
            <uc3:BatchSelectControl ID="bscMainReadyForStressing" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'In Progress Ready For Stressing' batches available." AutoGenerateEditButton="true" />
    
            <h3>In Progress Stressing</h3>
            <uc3:BatchSelectControl ID="bscChamber"  runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'In Progress Stressing' batches available." AutoGenerateEditButton="true" />

            <h3>Testing Complete/ Not Reporting Stages</h3>
            <uc3:BatchSelectControl ID="bscMainTestingComplete" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'Testing Complete' batches available." AutoGenerateEditButton="true" />
            
            <h3>Failure Analysis</h3>
            <uc3:BatchSelectControl ID="bscMainFA" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'FA' batches available." AutoGenerateEditButton="true" />
            
            <h3>Held/Reporting Stages</h3>
            <uc3:BatchSelectControl ID="bscMainHR" runat="server" DisplayMode="OverviewDisplay" EnableViewState="true" EmptyDataText="There are no 'Held/Report' batches available." AutoGenerateEditButton="true" />
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>