<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Results" Codebehind="Results.aspx.vb" EnableEventValidation="false" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Results</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">

    <script type="text/javascript">
        var _isInitialLoad = true;

        function pageLoad(sender, args) {
            if (_isInitialLoad) {
                _isInitialLoad = false;
                __doPostBack('<%= ddlBatches.ClientID %>', '');
            }
        }
    </script>

    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <asp:UpdatePanel ID="updLinks" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
                <ContentTemplate>
                    <asp:UpdateProgress runat="server" ID="UpdateProgress3" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updLinks">
                        <ProgressTemplate>
                            <div class="LoadingModal"></div>
                            <div class="LoadingGif"></div>
                        </ProgressTemplate>
                    </asp:UpdateProgress>
                        <li>
                            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgBatchAction" ToolTip="Go Back to Batch" runat="server" />
                            <asp:HyperLink ID="hypBatch" runat="server">Batch Info</asp:HyperLink>
                        </li>
                        <li>
                            <asp:Image ImageUrl="../Design/Icons/png/24x24/chart_down.png" ID="imgGraph" runat="server" Visible="false" />
                            <asp:HyperLink ID="hypGraph" runat="server" Visible="false">Graph Result</asp:HyperLink>
                        </li>
                        <li>
                            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgReports" runat="server" Visible="true" />
                            <asp:HyperLink ID="hypReports" runat="server" Visible="true" NavigateUrl="/Relab/Reports.aspx">Reports</asp:HyperLink>
                        </li>
                </ContentTemplate>
            </asp:UpdatePanel>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/xls_file.png" ID="imgExportAction" runat="server"  EnableViewState="false"/>
                <asp:LinkButton ID="lnkExportAction" runat="Server" Text="Export Result" EnableViewState="false"  />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMsg" runat="server" /><br />

    <asp:UpdatePanel ID="updOverallSummary" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="ddlBatches" />
            <asp:AsyncPostBackTrigger ControlID="ddlYear" />
        </Triggers>
        <ContentTemplate>
            Select QRA: <asp:DropDownList ID="ddlBatches" runat="server" AutoPostBack="true" CausesValidation="true"></asp:DropDownList>
            <asp:DropDownList runat="server" ID="ddlYear" CausesValidation="true" AutoPostBack="true">
                <asp:ListItem Selected="True" Text="Select A Year (if applicable)" Value="0"></asp:ListItem>
            </asp:DropDownList>
            <br /><br />
    
            <h2>Test/Stage/Unit Summary</h2>
            <font size="1">Use "*" in filter box as wildcard</font><br />
            <asp:UpdateProgress ID="UpdateProgress1" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updTestStageUnit">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>

            <script type="text/javascript">
                var prm = Sys.WebForms.PageRequestManager.getInstance();
                prm.add_pageLoaded(EndRequestSummary);

                function EndRequestOverall(sender, args) {
                    if (prm._postBackSettings != null) {
                        if (prm._postBackSettings.sourceElement.id == 'ctl00_Content_ddlBatches' || prm._postBackSettings.sourceElement.id == 'ctl00_Content_ddlYear') {
                            $('table#ctl00_Content_grdResultSummary').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                excludeColumns: [4],
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });
                        }
                    }
                    else {
                        $('table#ctl00_Content_grdResultSummary').columnFilters(
                        {
                            caseSensitive: false,
                            underline: true,
                            wildCard: '*',
                            excludeColumns: [4],
                            alternateRowClassNames: ['evenrow', 'oddrow']
                        });
                    }
                }
            </script>

            <asp:GridView ID="grdResultSummary" runat="server" EmptyDataText="There were no result found for this batch." DataKeyNames="ID" CssClass="FilterableTable"
                HeaderStyle-Wrap="false" AllowPaging="False" AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" DataSourceID="odsResultSummary" AutoGenerateColumns="false">
                <RowStyle CssClass="evenrow" />
                <HeaderStyle Wrap="False" />
                <AlternatingRowStyle CssClass="oddrow" />
                <Columns>
                    <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"  Visible="false" />
                    <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" SortExpression="TestStageName" />
                    <asp:BoundField DataField="TestName" HeaderText="Test Name" SortExpression="TestName" />
                    <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit" SortExpression="BatchUnitNumber" />
                    <asp:BoundField DataField="PassFail" HeaderText="Pass/Fail" SortExpression="PassFail" />   
                    <asp:TemplateField HeaderText="View Measurements" SortExpression="">
                        <ItemTemplate>
                            <asp:HyperLink ID="hplDetail" runat="server" Text="View" Target="_self" Visible='<%# Eval("HasMeasurements") %>'></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>  
                </Columns>           
            </asp:GridView>
            <asp:ObjectDataSource ID="odsResultSummary" runat="server" EnablePaging="False" SelectMethod="ResultSummary" TypeName="REMI.Bll.RelabManager">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ddlBatches" DefaultValue="0" Name="batchID" PropertyName="SelectedValue" Type="Int32"/>
                </SelectParameters>
            </asp:ObjectDataSource>

            <asp:UpdatePanel ID="updFailureAnalysis" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
                <Triggers>
                    <asp:AsyncPostBackTrigger ControlID="ddlTests" />
                </Triggers>
                <ContentTemplate>
                    <asp:UpdateProgress runat="server" ID="UpdateProgress4" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updFailureAnalysis">
                        <ProgressTemplate>
                            <div class="LoadingModal"></div>
                            <div class="LoadingGif"></div>
                        </ProgressTemplate>
                    </asp:UpdateProgress>
                    <h2>Failure Analysis</h2>
                    <asp:DropDownList runat="server" ID="ddlTests" DataTextField="tname" DataValueField="TestID" AutoPostBack="true">
                    </asp:DropDownList>

                    <script type="text/javascript">
                        var prm = Sys.WebForms.PageRequestManager.getInstance();
                        prm.add_pageLoaded(EndRequestFailure);

                        function EndRequestFailure(sender, args) {
                            if (prm._postBackSettings != null) {
                                if (prm._postBackSettings.sourceElement.id == 'ctl00_Content_ddlTests') {
                                    $('table#ctl00_Content_grdFailureAnalysis').columnFilters(
                                    {
                                        caseSensitive: false,
                                        underline: true,
                                        wildCard: '*',
                                        excludeColumns: [0],
                                        alternateRowClassNames: ['evenrow', 'oddrow']
                                    });
                                }
                            }
                            else {
                                $('table#ctl00_Content_grdFailureAnalysis').columnFilters(
                                {
                                    caseSensitive: false,
                                    underline: true,
                                    wildCard: '*',
                                    excludeColumns: [0],
                                    alternateRowClassNames: ['evenrow', 'oddrow']
                                });
                            }
                        }
                    </script>

                    <asp:GridView ID="grdFailureAnalysis" runat="server" EmptyDataText="There is no failures for this test" 
                        HeaderStyle-Wrap="false" AllowPaging="False" AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" DataSourceID="odsFailureAnalysis" AutoGenerateColumns="true">
                        <RowStyle CssClass="evenrow" />
                        <HeaderStyle Wrap="False" />
                        <AlternatingRowStyle CssClass="oddrow" />
                        <Columns>
                            <asp:TemplateField HeaderText="View Graph" SortExpression="">
                                <ItemTemplate>
                                    <asp:HyperLink ID="hplDetail" runat="server" Text="View" Target="_blank" NavigateUrl='<%# "/Relab/ResultGraph.aspx?BatchID=" + ddlBatches.SelectedValue + "&MeasurementID=" + Eval("ResultMeasurementID").ToString() + "&TestID=" + ddlTests.SelectedValue + "&AllUnits=1&TestStageID=" + Eval("TestStageID").ToString() + "&XAxis=1" %>'></asp:HyperLink>
                                </ItemTemplate>
                            </asp:TemplateField> 
                        </Columns>
                    </asp:GridView>
                    <asp:ObjectDataSource ID="odsFailureAnalysis" runat="server" EnablePaging="False" SelectMethod="FailureAnalysis" TypeName="REMI.Bll.RelabManager">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="ddlTests" DefaultValue="0" Name="testID" PropertyName="SelectedValue" Type="Int32"/>
                            <asp:ControlParameter ControlID="ddlBatches" DefaultValue="0" Name="batchID" PropertyName="SelectedValue" Type="Int32"/>
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </ContentTemplate>
            </asp:UpdatePanel>
            
            <asp:UpdatePanel ID="updTestStageUnit" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
                <Triggers>
                    <asp:AsyncPostBackTrigger ControlID="chkTestStageSummary" EventName="CheckedChanged" />
                </Triggers>
                <ContentTemplate>
                    <h2>Overall Summary</h2>
                    Toggle Visible: <asp:CheckBox runat="server" Visible="true" ID="chkTestStageSummary" OnCheckedChanged="chkTestStageSummary_SelectedCheckChanged" AutoPostBack="true" />
                    <asp:UpdateProgress ID="UpdateProgress2" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updOverallSummary">
                        <ProgressTemplate>
                            <div class="LoadingModal"></div>
                            <div class="LoadingGif"></div>
                        </ProgressTemplate>
                    </asp:UpdateProgress>
                    <script type="text/javascript">
                        var prm = Sys.WebForms.PageRequestManager.getInstance();
                        prm.add_pageLoaded(EndRequestOverall);

                        function EndRequestSummary(sender, args) {
                            if (prm._postBackSettings != null) {
                                if (prm._postBackSettings.sourceElement.id == 'ctl00_Content_pnlTestStageSummary' || prm._postBackSettings.sourceElement.id == 'ctl00_Content_ddlBatches' || prm._postBackSettings.sourceElement.id == 'ctl00_Content_ddlYear') {
                                    $('table#ctl00_Content_grdOverallSummary').columnFilters(
                                    {
                                        caseSensitive: false,
                                        underline: true,
                                        wildCard: '*',
                                        excludeColumns: [0],
                                        alternateRowClassNames: ['evenrow', 'oddrow']
                                    });
                                }
                            }
                            else {
                                $('table#ctl00_Content_grdOverallSummary').columnFilters(
                                {
                                    caseSensitive: false,
                                    underline: true,
                                    wildCard: '*',
                                    excludeColumns: [0],
                                    alternateRowClassNames: ['evenrow', 'oddrow']
                                });
                            }
                        }
                    </script>
                    <asp:Panel Visible="false" ID="pnlTestStageSummary" runat="server">
                        <asp:GridView ID="grdOverallSummary" runat="server" DataSourceID="odsOverview" HeaderStyle-Wrap="false" AllowPaging="False" EmptyDataText="There were no result found for this batch." AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" AutoGenerateColumns="True" DataKeyNames="TestID" CssClass="FilterableTable">
                            <RowStyle CssClass="evenrow" />
                            <HeaderStyle Wrap="False" />
                            <AlternatingRowStyle CssClass="oddrow" />
                            <Columns>
                                <asp:TemplateField HeaderText="XML" SortExpression="" ItemStyle-Width="4%">
                                    <ItemTemplate>
                                        <asp:HyperLink ID="hplVersions" runat="server" ToolTip="XML" ImageUrl="\Design\Icons\png\24x24\xml_file.png" Target="_self"></asp:HyperLink>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsOverview" runat="server" EnablePaging="False" SelectMethod="OverallResultSummary" TypeName="REMI.Bll.RelabManager">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="ddlBatches" DefaultValue="0" Name="batchID" PropertyName="SelectedValue" Type="Int32"/>
                            </SelectParameters>
                        </asp:ObjectDataSource>

                        <font size="1">
                            <ul>
                                <li>(?) is for how many DNP's their are for the specific unit at that test.</li>
                                <li>N/A: Not Applicable</li>
                                <li>N/S: Not Started</li>
                                <li>XML: Is to link to the XML (version) files used in processing that test.</li>
                            </ul>
                        </font>
                    </asp:Panel>
                </ContentTemplate>
            </asp:UpdatePanel>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>