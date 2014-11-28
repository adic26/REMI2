<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageTestStations_Default" Codebehind="Default.aspx.vb" %>
<%@ Register Assembly="DayPilot" Namespace="DayPilot.Web.Ui" TagPrefix="DayPilot" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">    
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    
    <script type="text/javascript">
        $(document).ready(function() { //when the page has loaded           
            $('table#ctl00_Content_grdUnits').columnFilters({ alternateRowClassNames: ['evenrow', 'oddrow'] });
        });
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" Runat="Server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <h3>Filter</h3>
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server">
    </asp:ToolkitScriptManager>

    <script type="text/javascript">
        var prm = Sys.WebForms.PageRequestManager.getInstance();
        prm.add_initializeRequest(InitializeRequest);
        prm.add_endRequest(EndRequest);
        var postBackElement;
        function InitializeRequest(sender, args) {
            if (prm.get_isInAsyncPostBack()) {
                args.set_cancel(true);
            }
            postBackElement = args.get_postBackElement();
            $get('ctl00_Content_chtStressing').style.display = "none";  
            $get('ctl00_Content_updp1').style.display = "block";
        }
        function EndRequest(sender, args) {
            $get('ctl00_Content_chtStressing').style.display = "block";            
            $get('ctl00_Content_updp1').style.display = "none";
        }
        function AbortPostBack() {
            if (prm.get_isInAsyncPostBack()) {
                prm.abortPostBack();
            }
        }
        
        var _isInitialLoad = true;

        function pageLoad(sender, args) {
            if (_isInitialLoad) {
                _isInitialLoad = false;
                __doPostBack('<%= ddlDepartments.ClientID%>', '');
            }
        }
    </script>
    
    <asp:UpdatePanel ID="updTimeline" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="ddlDepartments" />
            <asp:AsyncPostBackTrigger ControlID="ddlDisplayBy" />
            <asp:AsyncPostBackTrigger ControlID="ddlTimeFrame" />
            <asp:AsyncPostBackTrigger ControlID="chkShowGrid" />
        </Triggers>
        <ContentTemplate>
            <ul>
                <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTestCenterView" runat="server" />
                    <asp:DropDownList ID="ddlDepartments" runat="server" AppendDataBoundItems="True" DataTextField="LookupType" DataValueField="LookupID"
                        AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataSourceID="odsDepartments"></asp:DropDownList>
                    <asp:ObjectDataSource ID="odsDepartments" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                        <SelectParameters>
                    <asp:Parameter Type="String" Name="Type" DefaultValue="Department" />
                            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </li>
                <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgDisplayBy" runat="server" />
                    <asp:DropDownList runat="server" ID="ddlDisplayBy" AutoPostBack="true">
                        <asp:ListItem Text="Chamber/Mech" Value="1" Selected="True" />
                        <asp:ListItem Text="Lab Timeline" Value="2"/>
                    </asp:DropDownList>
                </li>
                <li>
                    <asp:Panel runat="server" ID="pnlTimeFrame" Visible="false">
                        <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTimeFrame" runat="server" />
                        <asp:DropDownList runat="server" ID="ddlTimeFrame" AutoPostBack="true">
                            <asp:ListItem Text="2 Hours" Value="2" Selected="True"/>
                            <asp:ListItem Text="4 Hours" Value="4" Selected="False"/>
                            <asp:ListItem Text="8 Hours" Value="8" Selected="False"/>
                            <asp:ListItem Text="1 Day" Value="24" Selected="False"/>
                            <asp:ListItem Text="1 Week" Value="168" Selected="False"/>
                            <asp:ListItem Text="1 Month" Value="730" Selected="False"/>
                         </asp:DropDownList>                
                    </asp:Panel>
                </li>
                <li>
                    <asp:CheckBox runat="server" ID="chkShowGrid" Text="Show Grid" AutoPostBack="true" CausesValidation="true" TextAlign="Right" />
                </li>
            </ul>
    
            <asp:Panel runat="server" Visible="true" ID="pnlChamberLegend">
                <h3>Chamber Grid Color</h3>
                <ul>
                    <li style="font-weight:bold;color:black;background-color:#FFFFFF">Functional</li>
                    <li style="font-weight:bold;color:black;background-color:#FF0000;">Not Functional</li>
                    <li style="font-weight:bold;color:black;background-color:#D3D3D3;">Disabled</li>
                    <li style="font-weight:bold;color:black;background-color:#FFA500;">Under Repair</li>
                </ul>
            </asp:Panel>
            <asp:Panel runat="server" ID="pnlLabTimeline" Visible="false">
                <h3>Lab Timeline Color</h3>
                <ul>
                    <li style="font-weight:bold;color:black;background-color:#ADD8E6">Parametric</li>
                    <li style="font-weight:bold;color:black;background-color:#F0E68C;">Stressing</li>
                    <li style="font-weight:bold;color:black;background-color:#FFFFE0;">Other</li>
                </ul>    
            </asp:Panel>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <asp:UpdatePanel ID="updChart" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false">
        <ContentTemplate>
            <asp:UpdateProgress runat="server" ID="updp1" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updChart">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>
            <asp:Panel runat="server" Visible="false" ID="pnlGrid">
                Note: To filter for a particular Request place a '*' character in front of the number. e.g. <strong>*</strong>***-##-####.<br />
                <asp:GridView ID="grdUnits" runat="server" EmptyDataText="There were no batches found for this selection." HeaderStyle-Wrap="false" RowStyle-Wrap="false" AutoGenerateColumns="False" CssClass="FilterableTable">
                <RowStyle CssClass="evenrow" />
                <HeaderStyle Wrap="False" />
                <AlternatingRowStyle CssClass="oddrow" />
                <Columns>
                    <asp:TemplateField HeaderText="Request" SortExpression="QRANumber">
                        <ItemTemplate>
                            <asp:HyperLink ID="hypQRANumber" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>'
                                Text='<%# Eval("QRANumber") %>' ToolTip='<%# "Click to view the information page for this batch" %>'></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="ProductGroupName" HeaderText="Product" />
                    <asp:BoundField DataField="AssignedTo" HeaderText="Assigned To" />
                    <asp:BoundField DataField="Location" HeaderText="Location" />
                    <asp:BoundField DataField="Job" HeaderText="Job" />
                    <asp:BoundField DataField="TestStage" HeaderText="Test Stage" Visible="True" />                                
                    <asp:TemplateField HeaderText="Scanned In">                            
                        <ItemTemplate>
                            <asp:Label ID="Label1" runat="server" Text='<%# Remi.Helpers.DateTimeFormat(Eval("InTime")) %>'></asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="TestLength" HeaderText="Exp. Test Time (h)" dataFormatString="{0:F2}"  />
                    <asp:BoundField DataField="totalTesttime" DataFormatString="{0:F2}" HeaderText="Curr Test Time (h)" />
                    <asp:BoundField DataField="RemainingTestTime" DataFormatString="{0:F2}" HeaderText="Remaining Time (h)" />
                    <asp:TemplateField HeaderText="Can Be Removed At">
                        <ItemTemplate>
                            <asp:Label ID="lblRemoveTime" runat="server" Text='<%# Remi.Helpers.DateTimeFormat(Eval("CanBeRemovedAt")) %>'></asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                </asp:GridView><br />
            </asp:Panel>
            <asp:Chart runat="server" ID="chtStressing" Width="1200px" ></asp:Chart>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>