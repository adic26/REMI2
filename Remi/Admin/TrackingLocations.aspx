<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Admin_TrackingLocation" CodeBehind="TrackingLocations.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $('table#ctl00_Content_gvMain').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [8,9,10,11,12],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>
        Tracking Locations</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>
            Admin Menu</h3>
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
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:HyperLink ID="Hyperlink8" runat="Server" Text="Tracking Tests" NavigateUrl="~/Admin/TrackingLocationTests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
        <h3>
            Tracking Location</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgViewTrackingLocations"
                    runat="server" />
                <asp:LinkButton ID="lnkViewTrackingLocations" runat="Server" Text="Refresh" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/add.png" ID="imgAddTrackingLocation"
                    runat="server" />
                <asp:LinkButton ID="lnkAddTrackingLocation" runat="Server" Text="Add New TL" /></li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" runat="server" Visible="False">
        <h3>
            Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddTrackingLocationAction"
                    runat="server" />
                <asp:LinkButton ID="lnkAddTrackingLocationAction" runat="Server" Text="Confirm and Save" /></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                    <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
                </li>
        </ul>
    </asp:Panel>
    <h3>
        Filter</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTestCenterView"
                runat="server" />
            <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True"
                DataTextField="LookupType" DataValueField="LookupID" AutoPostBack="True" Width="120px"
                ForeColor="#0033CC" DataSourceID="odsTestCenters">
            </asp:DropDownList>
            <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups"
                TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                <SelectParameters>
                    <asp:Parameter Type="String" Name="Type" DefaultValue="TestCenter" />
                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                    <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                    <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                    <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                </SelectParameters>
            </asp:ObjectDataSource>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:NotificationList ID="notMain" runat="server" />
    <asp:Panel ID="pnlViewAllTrackingLocations" runat="server">
        <asp:GridView ID="gvMain" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" CssClass="FilterableTable"
            OnRowCommand="gvMain_RowCommand" DataSourceID="odsTrackingLocations" EmptyDataText="There are no tracking locations in the system.">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                    SortExpression="ID" Visible="False" />
                <asp:TemplateField HeaderText="Name" SortExpression="Name">
                    <ItemTemplate>
                        <asp:HyperLink ID="hypName" runat="server" Text='<%# Eval("DisplayName") %>' NavigateUrl='<%# Eval("TrackingLocationLink") %>'></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="BarcodePrefix" HeaderText="Barcode Prefix" SortExpression="BarcodePrefix"
                    ReadOnly="True" />
                <asp:BoundField DataField="GeoLocationName" ReadOnly="true" HeaderText="Location"
                    SortExpression="GeoLocationName" />
                <asp:BoundField DataField="HostName" HeaderText="HostName" ReadOnly="True" SortExpression="HostName" />
                <asp:BoundField DataField="UnitCapacity" HeaderText="Unit Capacity" SortExpression="UnitCapacity" ReadOnly="True" />
                <asp:BoundField DataField="TrackingLocationTypeName" HeaderText="Function Type" ReadOnly="True" />
                <asp:BoundField DataField="TrackingLocationFunction" HeaderText="Function" ReadOnly="True" />
                <asp:BoundField DataField="Status" HeaderText="Status" ReadOnly="True" SortExpression="Status" />
                <asp:TemplateField HeaderText="WI">
                    <ItemTemplate>
                        <asp:HyperLink ID="hypWILocation" runat="server" NavigateUrl='<%# Eval("WILocation") %>'
                            Target="_blank" Text="Click"></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Program">
                    <ItemTemplate>
                        <asp:HyperLink ID="hypProgram" runat="server" NavigateUrl='<%# Eval("ProgrammingLink") %>'
                            Target="_blank" Text="Click"></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server" CommandName="Edit" CommandArgument='<%# Eval("ID") %>'>Edit</asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkDelete" runat="server" CausesValidation="False" CommandName="DeleteItem"
                            Visible='<%# Eval("CanDelete") %>' CommandArgument='<%# Eval("ID") %>' OnClientClick="return confirm('Are you sure you want to delete this Tracking Location?');"
                            Text="Delete"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkAvailable" runat="server" CausesValidation="False" CommandName="CheckAvailability"
                            CommandArgument='<%# Eval("HostName") %>' Text="Check Availability"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        <asp:ObjectDataSource ID="odsTrackingLocations" runat="server" DeleteMethod="Delete"
            SelectMethod="GetList" TypeName="REMI.Bll.TrackingLocationManager" OldValuesParameterFormatString="{0}">
            <DeleteParameters>
                <asp:Parameter Name="ID" Type="Int32" />
            </DeleteParameters>
            <SelectParameters>
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$ddlTestCenters" DefaultValue="0"
                    Name="TestCenterLocationID" PropertyName="SelectedValue" Type="Int32" />
                <asp:Parameter Type="Int32" Name="onlyActive" DefaultValue="0" />
            </SelectParameters>
        </asp:ObjectDataSource>
        <asp:HiddenField ID="hdnSelectedTrackingLocationID" runat="server" />
    </asp:Panel>
    <asp:Panel ID="pnlAddEditTrackingLocation" runat="server" Visible="False">
        <h2><asp:Label ID="lblAddEditTitle" runat="server" Text="Add a new Tracking Location"></asp:Label></h2>
        <table style="width: 52%;">
            <tr>
                <td class="HorizTableFirstcolumn">
                    Name:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtName" runat="server" Width="208px"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Host Name(s):
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView ID="grdHosts" runat="server" AutoGenerateColumns="false" DataKeyNames="ID"
                        AllowPaging="false" BackColor="white" BorderColor="#CC9966" BorderStyle="None"
                        BorderWidth="1px" CellPadding="4" OnRowDeleting="grdHosts_RowDeleting" Visible="true">
                        <Columns>
                            <asp:TemplateField HeaderText="HostName">
                                <ItemTemplate>
                                    <asp:TextBox ID="txtHostName2" runat="server" Text='<%#Eval ("HostName")%>' ReadOnly="true"></asp:TextBox>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:CommandField HeaderText="Delete" ShowDeleteButton="true" ShowHeader="true" />
                        </Columns>
                    </asp:GridView>
                    <table>
                        <tr>
                            <td>
                                <asp:TextBox ID="HostNameNew" runat="server"></asp:TextBox>
                                <asp:Button ID="HostSubmit" runat="server" Text="Submit" OnClick="HostSubmit_Click" />
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Test Center:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlGeoLoc" runat="server" DataSourceID="odsGeoLocList" Width="195px"
                        DataTextField="LookupType" DataValueField="LookupID">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsGeoLocList" runat="server" SelectMethod="GetLookups"
                        TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                        <SelectParameters>
                            <asp:Parameter Type="String" Name="Type" DefaultValue="TestCenter" />
                            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="1" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Status:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList runat="server" ID="ddlStatus">
                        <asp:ListItem Text="Functional" Value="1" />
                        <asp:ListItem Text="Not Functional" Value="2" />
                        <asp:ListItem Text="Disabled" Value="3" />
                        <asp:ListItem Text="Under Repair" Value="4" />
                    </asp:DropDownList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Type:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlFixtureType" runat="server" Width="196px" DataValueField="ID"
                        DataTextField="Name" DataSourceID="odsTLTypes">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsTLTypes" runat="server" OldValuesParameterFormatString="original_{0}"
                        SelectMethod="GetTrackingLocationTypes" TypeName="REMI.Bll.TrackingLocationManager">
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Decommission:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkRetire" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Multi Device Zone:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkIsMultiDeviceZone" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Plugin Name:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView ID="grdPlugin" runat="server" AutoGenerateColumns="false" DataKeyNames="ID"
                        AllowPaging="false" BackColor="white" BorderColor="#CC9966" BorderStyle="None"
                        BorderWidth="1px" CellPadding="4" Visible="true">
                        <Columns>
                            <asp:TemplateField HeaderText="PluginName">
                                <ItemTemplate>
                                    <asp:TextBox ID="txtPluginName2" runat="server" Text='<%#Eval ("PluginName")%>' ReadOnly="true"></asp:TextBox>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField ShowHeader="False">
                                <ItemTemplate>
                                    <asp:LinkButton ID="lnkDelete" runat="server" CommandArgument='<%# Eval("ID") %>'
                                        OnClientClick="return confirm('Are you sure you want to delete this profile?');"
                                        CommandName="DeleteItem" Visible='<%# Eval("CanDelete") %>'>Delete</asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                    <table>
                        <tr>
                            <td>
                                <asp:TextBox ID="txtPluginName" runat="server"></asp:TextBox>
                                <asp:Button ID="btnPluginAdd" runat="server" Text="Submit" OnClick="btnPluginAdd_Click" />
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </asp:Panel>
    <br />
    <br />
    <br />
    <br />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
