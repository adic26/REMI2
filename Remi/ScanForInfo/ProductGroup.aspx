<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ScanForInfo_ProductGroup" CodeBehind="ProductGroup.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_acpBatches_content_bscMain_grdBatches').columnFilters(
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
                excludeColumns: [14, 15, 16, 17],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>
        <asp:Label runat="server" ID="lblProductGroupName" Text="Product Information"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>Menu</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgSummaryView" runat="server" />
            <asp:LinkButton ID="lnkRefresh" runat="Server" Text="Refresh" ToolTip="Click to refresh the page" />
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgShowArchived"
                runat="server" />
            <asp:CheckBox runat="server" Text=" Show Archived" ID="chkShowArchived" ToolTip="Show Archived"
                TextAlign="Right" AutoPostBack="true" CausesValidation="true" />
        </li>
        <li id="liEditSettings" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/tools.png" ID="imgeditSettings" runat="server" />
            <asp:HyperLink ID="hypEditSettings" runat="Server" Text="Edit Product" ToolTip="Click to edit the product settings" /><br />
        </li>
        <li id="liEditConfigSettings" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/tools.png" ID="imgEditTestConfiguration"
                runat="server" />
            <asp:HyperLink ID="HypEditTestConfiguration" runat="Server" Text="Edit Test Config"
                ToolTip="Click to edit the product Test Configuration" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:Panel ID="pnlSummary" runat="server">
        <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility: hidden;display: none;" />
        &nbsp;&nbsp;<asp:DropDownList ID="ddlProductGroup" runat="server" Width="181px" DataTextField="ProductGroupName" DataValueField="ID" ></asp:DropDownList>
        <asp:ObjectDataSource ID="odsProducts" runat="server" SelectMethod="GetProductList" TypeName="REMI.Bll.ProductGroupManager" OldValuesParameterFormatString="original_{0}">
            <SelectParameters>
                <asp:ControlParameter  ControlID="ctl00$Content$chkByPass" DefaultValue="False" Name="ByPassProduct" PropertyName="Checked" Type="Boolean" />
                <asp:ControlParameter ControlID="ctl00$Content$hdnUserID" Name="UserID" Type="Int32" PropertyName="Value" />
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkShowArchived" DefaultValue="False" PropertyName="Checked" Name="showArchived" Type="Boolean" />
            </SelectParameters>
        </asp:ObjectDataSource>
        &nbsp;<asp:Button ID="btnSubmit" runat="server" Text="View" Width="55px" Height="25px" CssClass="button" />
        <asp:HiddenField ID="hdnProductID" runat="server" Value="0" />
        <asp:CheckBox runat="server" ID="chkByPass" CssClass="hidden" Visible="false" />
        <asp:HiddenField ID="hdnUserID" runat="server" Value="" />
        
        <asp:GridView ID="grdTargetDates" runat="server" AutoGenerateColumns="false" DataKeyNames="ID, KeyName" AutoGenerateEditButton="true" EmptyDataText="" EnableViewState="true"  OnRowEditing="grdTargetDates_OnRowEditing" OnRowCancelingEdit="grdTargetDates_OnRowCancelingEdit" OnRowUpdating="grdTargetDates_RowUpdating">
            <Columns>
                <asp:BoundField DataField="KeyName" HeaderText="M#" ReadOnly="true" SortExpression="KeyName" />
                <asp:TemplateField HeaderText="Lab Availability" SortExpression="ValueText">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblValueText" Text='<%# Eval("ValueText") %>' Visible="true" />
                        <asp:TextBox runat="server" ID="txtValueText" Text='<%# Eval("ValueText") %>' Visible="false" />
                        <asp:CalendarExtender ID="txtValueText_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtValueText"></asp:CalendarExtender>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>

        <asp:Accordion ID="accMain" runat="server" CssClass="Accordion" HeaderCssClass="AccordionHeader"
            ContentCssClass="AccordionContent" FadeTransitions="true" TransitionDuration="250"
            FramesPerSecond="40" RequireOpenedPane="false" AutoSize="None" Width="1223px">
            <Panes>
                <asp:AccordionPane ID="acpContacts" runat="server">
                    <Header>
                        <h2><asp:Label runat="server" Text="Contacts" ID="lblContacts" /></h2>
                    </Header>
                    <Content>
                        <asp:GridView runat="server" ID="gvwContacts" AutoGenerateColumns="true" EmptyDataText="No Contacts Setup">
                        </asp:GridView>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpReadiness" runat="server">
                    <Header>
                        <h2><asp:Label runat="server" Text="Product Ready" ID="lblReady" /></h2>
                    </Header>
                    <Content>
                        <asp:DropDownList runat="server" ID="ddlMRevision" AutoPostBack="true" DataTextField="KeyName" DataValueField="KeyName"></asp:DropDownList>
                        <asp:GridView ID="grdReady" runat="server" AutoGenerateColumns="false" DataKeyNames="TestID, ReadyID, PSID" AutoGenerateEditButton="true" EmptyDataText="" EnableViewState="true" OnRowEditing="grdReady_OnRowEditing" OnRowCancelingEdit="grdReady_OnRowCancelingEdit" OnRowUpdating="grdReady_RowUpdating">
                            <Columns>
                                <asp:BoundField DataField="TestName" HeaderText="TestName" ReadOnly="true" SortExpression="TestName" />
                                <asp:BoundField DataField="Owner" HeaderText="Owner" ReadOnly="true" SortExpression="Owner" />
                                <asp:BoundField DataField="Trainee" HeaderText="Trainee" ReadOnly="true" SortExpression="Trainee" />
                                <asp:TemplateField HeaderText="Is Ready" SortExpression="IsReady">
                                    <ItemTemplate>
                                        <asp:Label runat="server" ID="lblIsReady" Text='<%# Eval("IsReady") %>' Visible="true" />
                                        <asp:RadioButtonList runat="server" Visible="false" ID="rblIsReady" >
                                        <asp:ListItem Text="Yes" Value="1" />
                                        <asp:ListItem Text="No" Value="2" />
                                        <asp:ListItem Text="N/A" Value="3" />
                                        </asp:RadioButtonList>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Has Nest" SortExpression="IsNestReady">
                                    <ItemTemplate>
                                        <asp:Label runat="server" ID="lblIsNestReady" Text='<%# Eval("IsNestReady") %>' Visible="true" />
                                        <asp:RadioButtonList runat="server" Visible="false" ID="rblIsNestReady" >
                                        <asp:ListItem Text="Yes" Value="1" />
                                        <asp:ListItem Text="No" Value="2" />
                                        <asp:ListItem Text="N/A" Value="3" />
                                        </asp:RadioButtonList>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="JIRA" SortExpression="JIRA">
                                    <ItemTemplate>
                                        <asp:HyperLink runat="server" ID="hplJIRA" Target="_blank" Visible="true" NavigateUrl='<%# "https://jira.rim.net/i#browse/RELISSUE-" & Eval("JIRA") %>' Text='<%# Eval("JIRA") %>' />
                                        <asp:TextBox runat="server" ID="txtJIRA" Text='<%# Eval("JIRA") %>' Visible="false" Columns="20" Rows="5" TextMode="SingleLine" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Comment" SortExpression="Comment">
                                    <ItemTemplate>
                                        <asp:Label runat="server" ID="lblComment" Text='<%# Eval("Comment") %>' Visible="true" />
                                        <asp:TextBox runat="server" ID="txtComment" Text='<%# Eval("Comment") %>' Visible="false" Columns="20" Rows="5" TextMode="MultiLine" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </Content>
                </asp:AccordionPane>
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
                            <asp:Label runat="server" ID="lblBatches" Text="Batches"></asp:Label></h2>
                    </Header>
                    <Content>
                        <asp:DropDownList ID="ddlFilterBatches" runat="server" AutoPostBack="true">
                            <asp:ListItem Text="Select" Value="-1"></asp:ListItem>
                            <asp:ListItem Text="In Progress / Received" Value="0"></asp:ListItem>
                            <asp:ListItem Text="All" Value="1"></asp:ListItem>
                        </asp:DropDownList>
                        <uc3:BatchSelectControl ID="bscMain" runat="server" EnableViewState="true" DisplayMode="ProductInfoDisplay" />
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpTrackingLogs" runat="server">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="lblTrackingLogs" Text="Tracking Logs"></asp:Label></h2>
                    </Header>
                    <Content>
                        <asp:DropDownList ID="ddlTime" runat="server" AutoPostBack="True" Width="162px">
                            <asp:ListItem value="-1">Select</asp:ListItem>
                            <asp:ListItem Value="1">Last Hour</asp:ListItem>
                            <asp:ListItem Value="12">Last 12 Hours</asp:ListItem>
                            <asp:ListItem Value="24">Last 24 Hours</asp:ListItem>
                            <asp:ListItem Value="168">Last Week</asp:ListItem>
                            <asp:ListItem Value="720">Last 30 Days</asp:ListItem>
                            <asp:ListItem Value="2191">Last 3 Months</asp:ListItem>
                            <asp:ListItem Value="4382">Last 6 Months</asp:ListItem>
                            <asp:ListItem Value="8766">Last Year</asp:ListItem>
                            <asp:ListItem Value="999999">All</asp:ListItem>
                        </asp:DropDownList>
                        <br />
                        <br />
                        <asp:GridView ID="grdTrackingLog" runat="server" AutoGenerateColumns="False" 
                            EmptyDataText="No tracking logs available for this time period." EnableViewState="true">
                            <RowStyle CssClass="evenrow" />
                            <Columns>
                                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                                    SortExpression="ID" Visible="False" />
                                <asp:BoundField DataField="TestUnitID" HeaderText="TestUnitID" SortExpression="TestUnitID"
                                    Visible="False" />
                                <asp:BoundField DataField="TestUnitQRANumber" HeaderText="QRA" SortExpression="TestUnitQRANumber" />
                                <asp:TemplateField HeaderText="Unit" SortExpression="BatchUnitNumber">
                                    <ItemTemplate>
                                        <asp:Label ID="lblUnitNumber" runat="server" Text='<%# Eval("TestUnitBatchUnitNumber") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
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
                            <AlternatingRowStyle CssClass="oddrow" />
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsTrackingLog" runat="server" SelectMethod="Get24HourLogsForProduct"
                            TypeName="REMI.Bll.TrackingLogManager" OldValuesParameterFormatString="original_{0}">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnProductID" Name="ProductID" PropertyName="Value"
                                    Type="String" />
                                <asp:ControlParameter ControlID="ddlTime" Name="TimeInHours" PropertyName="SelectedValue"
                                    Type="String" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                    </Content>
                </asp:AccordionPane>
            </Panes>
        </asp:Accordion>
    </asp:Panel>
    <br />
    <br />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
