<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageTestStations_TrackingLocation" Codebehind="TrackingLocation.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_acpBatches_content_bscBatches_grdBatches').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [14, 15, 16, 17],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });

            $('table#ctl00_Content_acpTrackingLogs_content_grdTrackingLog').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server">
    </asp:ToolkitScriptManager>
    <h1>
      <asp:Label ID="lblTrackingLocation" runat="server" Text="Tracking Location Information"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>
        View</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgSummaryView" runat="server" />
            <asp:LinkButton ID="lnkRefresh" runat="server">Refresh</asp:LinkButton>
        </li>
        <li id="liEditConfig" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/tools.png" ID="imgEditStationConfiguration" runat="server" />
            <asp:hyperlink ID="HypEditStationConfiguration" runat="Server" Text="Edit Station Config" ToolTip="Click to edit the station Configuration" />
        </li>
    </ul>
        <h3>
        Filter</h3>
    <ul>
           <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTestCenterView" runat="server" />
            <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True" DataTextField="LookupType" DataValueField="LookupID"
                AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataSourceID="odsTestCenters">
            </asp:DropDownList>
            <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                <SelectParameters>
                    <asp:Parameter Type="Int32" Name="Type" DefaultValue="4" />
                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                </SelectParameters>
            </asp:ObjectDataSource>
        </li></ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:Panel ID="pnlSummary" runat="server">
        <asp:DropDownList ID="ddlTrackingLocation" runat="server" Width="280px" DataSourceID="odsTrackingLocations" DataTextField="DisplayName" DataValueField="ID">
        </asp:DropDownList>
        <asp:Button ID="btnSubmit" runat="server" Text="View Info" Width="55px" height="25px" CssClass="button" />
 
        <asp:HiddenField ID="hdnBarcodePrefix" runat="server" Value="0" />
        <asp:ObjectDataSource ID="odsTrackingLocations" runat="server" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLocationsWithoutHost" TypeName="REMI.Bll.TrackingLocationManager">
            <SelectParameters>
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$ddlTestCenters" DefaultValue="0" Name="TestCenterLocationID" PropertyName="SelectedValue" Type="Int32" />
                <asp:Parameter Type="Int32" Name="onlyActive" DefaultValue="1" />
            </SelectParameters>
        </asp:ObjectDataSource>
   <br /> <br />
        <asp:GridView ID="grdDetail" runat="server" AutoGenerateColumns="False"  EnableViewState="false"  EmptyDataText="No information currently available.">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" SortExpression="ID" Visible="False" />
                <asp:BoundField DataField="Name" HeaderText="Name" SortExpression="Name" />
                <asp:BoundField DataField="BarcodePrefix" HeaderText="Barcode Suffix" SortExpression="BarcodePrefix" />
                <asp:BoundField DataField="GeoLocationName" HeaderText="Location" SortExpression="GeoLocationName" />
                <asp:BoundField DataField="UnitCapacity" HeaderText="Capacity" SortExpression="UnitCapacity" />
                <asp:BoundField DataField="CurrentTestName" HeaderText="Current Test" SortExpression="CurrentTestName" />
                <asp:BoundField DataField="CurrentUnitCount" HeaderText="Current Count" SortExpression="CurrentUnitCount" />
                <asp:BoundField DataField="TrackingLocationType" HeaderText="Fixture Type" SortExpression="TrackingLocationType" />
                <asp:TemplateField HeaderText="Scanner Program" SortExpression="GetBarcodeProgrammingLink">
                    <ItemTemplate>
                        <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("ProgrammingLink") %>'
                            Target="_blank" Text="Click"></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Manual" SortExpression="OperatingManualLocation">
                    <ItemTemplate>
                        <asp:HyperLink ID="HyperLink2" runat="server" NavigateUrl='<%# Eval("TrackingLocationType").WILocation %>'
                            Text="Click"></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        <asp:Accordion ID="accMain" runat="server" CssClass="Accordion" HeaderCssClass="AccordionHeader"
            ContentCssClass="AccordionContent" FadeTransitions="true" TransitionDuration="250" SelectedIndex="1" 
            FramesPerSecond="40" RequireOpenedPane="false" AutoSize="None" Width="1223px">
            <Panes>
                <asp:AccordionPane ID="acpNotifications" runat="server">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="lblNotificationHeader" Text="Notifications"></asp:Label></h2>
                    </Header>
                    <Content>
                        <uc1:NotificationList ID="notMain" runat="server" />
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpBatches" runat="server">
                    <Header>
                        <h2>
                            Batches</h2>
                    </Header>
                    <Content>
                        <uc3:BatchSelectControl runat="server" ID="bscBatches" EmptyDataText="There were no batches found for this selection." DisplayMode="TrackingLocationDisplay" AllowPaging="true" AllowSorting="true" PageSize="50" DataSourceID="odsBatches" />
                        
                        <asp:ObjectDataSource ID="odsBatches" runat="server" DataObjectTypeName="REMI.BusinessEntities.Batch"
                            OldValuesParameterFormatString="{0}" EnablePaging="true" SortParameterName="sortExpression"
                            SelectMethod="GetListAtLocation" TypeName="REMI.Bll.BatchManager" SelectCountMethod="CountListAtLocation">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnBarcodePrefix" Name="BarcodePrefix" PropertyName="Value" Type="int32" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpTrackingLogs" runat="server">
                    <Header>
                        <h2>
                            Tracking Logs
                        </h2>
                    </Header>
                    <Content>
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
                        <br />
                        <br />
                        <asp:GridView ID="grdTrackingLog" runat="server" AutoGenerateColumns="False" DataSourceID="odsTrackingLog"
                            CssClass="VerticalTable" EmptyDataText="No tracking logs available for this time period." EnableViewState="false" >
                            <RowStyle CssClass="evenrow" />
                            <Columns>
                                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                                    SortExpression="ID" Visible="False" />
                                <asp:BoundField DataField="TestUnitID" HeaderText="TestUnitID" SortExpression="TestUnitID"
                                    Visible="False" />
                                <asp:TemplateField HeaderText="Request" SortExpression="TestUnitQRANumber">
                                    <ItemTemplate>
                                        <asp:HyperLink ID="HyperLink3" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>'
                                            Text='<%# Eval("TestUnitQRANumber") %>'></asp:HyperLink>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Unit" SortExpression="BatchUnitNumber">
                                    <ItemTemplate>
                                        <asp:Label ID="lblUnitNumber" runat="server" Text='<%# Eval("TestUnitBatchUnitNumber") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Location" SortExpression="TrackingLocation">
                                    <ItemTemplate>
                                        <asp:Label ID="Label1" runat="server" Text='<%# Eval("TrackingLocationName") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged In" SortExpression="InTime">
                                    <ItemTemplate>
                                        <asp:Label ID="Label2" runat="server" Text='<%# Remi.Helpers.DateTimeFormat(Eval("InTime")) %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged In By" SortExpression="InUser">
                                    <ItemTemplate>
                                        <asp:Label ID="Label3" runat="server" Text='<%# Remi.Helpers.UserNameFormat(Eval("InUser")) %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged Out" SortExpression="OutTime">
                                    <ItemTemplate>
                                        <asp:Label ID="Label4" runat="server" Text='<%# Remi.Helpers.DateTimeformat(Eval("OutTime")) %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Logged Out By" SortExpression="OutUser">
                                    <ItemTemplate>
                                        <asp:Label ID="Label5" runat="server" Text='<%# Remi.Helpers.UserNameFormat(Eval("OutUser")) %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <AlternatingRowStyle CssClass="oddrow" />
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsTrackingLog" runat="server" SelectMethod="Get24HourLogsForLocation"
                            TypeName="REMI.Bll.TrackingLogManager" OldValuesParameterFormatString="original_{0}">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnBarcodePrefix" Name="ID" PropertyName="Value" Type="int32" />
                                <asp:ControlParameter ControlID="ddlTime" Name="TimeInHours" PropertyName="SelectedValue" Type="String" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                        <br />
                    </Content>
                </asp:AccordionPane>
            </Panes>
        </asp:Accordion>
    </asp:Panel>
    <br /> <br />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
