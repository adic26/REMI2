<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ScanUnit"  Codebehind="Unit.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>
        <asp:Label runat="server" ID="lblQRANumber" Text="Unit Information"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js"></script>
    <script type="text/javascript">
    $(document).ready(function () {
        $('table#ctl00_Content_acpTrackingLogs_content_grdTrackingLog').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
    <h3>Menu</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgSummaryView" runat="server" />
            <asp:HyperLink ID="hypRefresh" runat="server" ToolTip="Click to refresh the page" NavigateUrl="~/ScanForInfo/Unit.aspx">Refresh Page</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgTRLink" runat="server" />
            <asp:HyperLink ID="hypTestRecords" runat="server" ToolTip="Click to view all of the test records for this unit" NavigateUrl="">Test Records</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgMFG" runat="server" />
            <asp:HyperLink ID="hypMFG" runat="server" ToolTip="Click to view the manufacturing information page for this unit" NavigateUrl="http://go/mfgweb" Target="_blank">MfgWeb History</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgBatchInfo" runat="server" />
            <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to view the information for this entire batch" NavigateUrl="~/ScanForInfo/Batch.aspx">Batch Info</asp:HyperLink>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField ID="hdnTestUnitID" runat="server" Value="0" />
    <asp:Panel ID="pnlSummary" runat="server">
        <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility: hidden;
            display: none;" />
        <img alt="Scan Barcode into text box" class="ScanDeviceImage" src="../Design/Icons/png/48x48/barcode.png" />
        &nbsp;<asp:TextBox ID="txtBarcodeReading" runat="server" CssClass="ScanDeviceTextEntryHint"
            value="Enter Request Number..." onfocus="if (this.className=='ScanDeviceTextEntryHint') { this.className = 'ScanDeviceTextEntry'; this.value = ''; }"
            onblur="if (this.value == '') { this.className = 'ScanDeviceTextEntryHint'; this.value = 'Enter Request Number...'; }"></asp:TextBox><asp:Button
                ID="btnSubmit" runat="server" CssClass="ScanDeviceButton" Text="Submit" />
        <br />
        <asp:HiddenField ID="hdnQRANumber" runat="server" Value="0" />
        <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server">
        </asp:ToolkitScriptManager>
        <asp:GridView ID="grdDetail" runat="server" AutoGenerateColumns="False" DataKeyNames="ID"
            Width="866px"  EmptyDataText="No Unit Information Available." EnableViewState="false" >
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                    SortExpression="ID" Visible="False" />
                <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit" SortExpression="BatchUnitNumber" />
                <asp:TemplateField HeaderText="BSN" SortExpression="BSN">
                    <ItemTemplate>
                        <asp:HyperLink ID="hypBSN" runat="server" ToolTip="Click to view the manufacturing information page for this unit"
                            NavigateUrl='<%# Eval("MfgWebLink") %>' Text='<%# Eval("BSN") %>' Target="_blank" ></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="IMEI" HeaderText="IMEI" ReadOnly="True" SortExpression="IMEI" Visible="True" />
                <asp:TemplateField HeaderText="Assigned To" SortExpression="AssignedTo">
                    <ItemTemplate>
                        <asp:Label ID="Label1" runat="server" Text='<%# REMI.BusinessEntities.Helpers.UserNameformat(Eval("AssignedTo"))%>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Current Test Stage" SortExpression="CurrentTestStage">
                    <ItemTemplate>
                        <asp:Label ID="Label4" runat="server" Text='<%# Eval("CurrentTestStage") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Current Test" SortExpression="CurrentTest">
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" Text='<%# Eval("CurrentTest") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Current Location">
                    <ItemTemplate>
                        <asp:Label ID="Label5" runat="server" Text='<%# Eval("LocationString") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        <asp:Accordion ID="accMain" runat="server" CssClass="Accordion" HeaderCssClass="AccordionHeader"
            ContentCssClass="AccordionContent" FadeTransitions="false" RequireOpenedPane="false"
            AutoSize="None">
            <Panes>
                <asp:AccordionPane ID="acpBatchInfo" runat="server">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="Label6" Text="Notifications"></asp:Label></h2>
                    </Header>
                    <Content>
                        <uc1:NotificationList ID="notMain" runat="server" />
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpTrackingLogs" runat="server">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="lblNotificationHeader" Text="Tracking Logs"></asp:Label></h2>
                    </Header>
                    <Content>
                        Select Timeframe:
                        <asp:DropDownList ID="ddlTime" runat="server" AutoPostBack="True" Width="162px">
                            <asp:ListItem Value="1">Last Hour</asp:ListItem>
                            <asp:ListItem Value="12">Last 12 Hours</asp:ListItem>
                            <asp:ListItem Value="24">Last 24 Hours</asp:ListItem>
                            <asp:ListItem Value="168">Last Week</asp:ListItem>
                            <asp:ListItem Value="720" Selected="True">Last 30 Days</asp:ListItem>
                            <asp:ListItem Value="2191">Last 3 Months</asp:ListItem>
                            <asp:ListItem Value="4382">Last 6 Months</asp:ListItem>
                           <asp:ListItem Value="8766">Last Year</asp:ListItem>
                            <asp:ListItem Value="999999">All</asp:ListItem>
                        </asp:DropDownList>
                        <asp:GridView ID="grdTrackingLog" runat="server" AutoGenerateColumns="False" DataSourceID="odsTrackingLog"
                             EmptyDataText="No tracking logs available." EnableViewState="false" >
                            <Columns>
                                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" SortExpression="ID" Visible="False" />
                                <asp:BoundField DataField="TestUnitID" HeaderText="TestUnitID" SortExpression="TestUnitID" Visible="False" />
                                <asp:TemplateField HeaderText="Location" SortExpression="TrackingLocation">
                                    <ItemTemplate>
                                        <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("TrackingLocationLink") %>'
                                            Text='<%# Eval("TrackingLocationName") %>'></asp:HyperLink>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged In" SortExpression="InTime">
                                    <ItemTemplate>
                                        <asp:Label ID="Label2" runat="server" Text='<%# Remi.BusinessEntities.Helpers.DateTimeformat(Eval("InTime"))%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged In By" SortExpression="InUser">
                                    <ItemTemplate>
                                        <asp:Label ID="Label3" runat="server" Text='<%# REMI.BusinessEntities.Helpers.UserNameformat(Eval("InUser"))%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged Out" SortExpression="OutTime">
                                    <ItemTemplate>
                                        <asp:Label ID="Label4" runat="server" Text='<%# REMI.BusinessEntities.Helpers.DateTimeformat(Eval("OutTime"))%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged Out By" SortExpression="OutUser">
                                    <ItemTemplate>
                                        <asp:Label ID="Label5" runat="server" Text='<%# REMI.BusinessEntities.Helpers.UserNameformat(Eval("OutUser"))%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsTrackingLog" runat="server" SelectMethod="Get24HourLogsForTestUnit"
                            TypeName="REMI.Bll.TrackingLogManager" OldValuesParameterFormatString="original_{0}">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnTestUnitID" DefaultValue="-1" Name="TestUnitID"
                                    PropertyName="Value" Type="String" />
                                <asp:ControlParameter ControlID="ddlTime" DefaultValue="-1" Name="TimeInHours" PropertyName="SelectedValue"
                                    Type="Int32" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                        <br />
                    </Content>
                </asp:AccordionPane>
            </Panes>
        </asp:Accordion>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
