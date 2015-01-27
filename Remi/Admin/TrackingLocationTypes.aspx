<%@ Page Title="Tracking Location Types" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"  AutoEventWireup="false" Inherits="Remi.Admin_TrackingLocationTypes" Codebehind="TrackingLocationTypes.aspx.vb" MaintainScrollPositionOnPostback="true" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $('table#ctl00_Content_gvTestStationTypes').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [4],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
   <h1>Tracking Location Types</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews"  runat="server">
        <h3>
                Admin Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:hyperlink ID="Hyperlink2" runat="Server" Text="Process Flow" navigateurl="~/Admin/Jobs.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image4" runat="server" />
                <asp:hyperlink ID="Hyperlink3" runat="Server" Text="Tracking Locs" navigateurl="~/Admin/trackinglocations.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image1" runat="server" />
                <asp:hyperlink ID="Hyperlink1" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="Image5" runat="server" />
                <asp:hyperlink ID="Hyperlink4" runat="Server" Text="Users" navigateurl="~/Admin/users.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink7" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image8" runat="server" />
                <asp:HyperLink ID="hypTestStages" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
        <h3>Tracking Types</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgViewTrackingLocations" runat="server" />
                <asp:LinkButton ID="lnkViewTrackingLocations" runat="Server" Text="Refresh" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/ruler_add.png" ID="imgAddTT" runat="server" />
                <asp:LinkButton ID="lnkAddTT" runat="Server" Text="Add New Type" />
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="True" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddTrackingLocationAction" runat="server" />
                <asp:LinkButton ID="lnkAddTrackingLocationAction" runat="Server" Text="Confirm and Save" /></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                    <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlViewAll" runat="server">
        <asp:GridView ID="gvTestStationTypes" runat="server" AutoGenerateColumns="False" CssClass="FilterableTable" DataKeyNames="ID" onrowcommand="gvTestStationTypes_RowCommand" 
        DataSourceID="odsTrackingLocationTypes">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" 
                ReadOnly="True" SortExpression="ID" Visible="False" />
                <asp:BoundField DataField="Name" HeaderText="Name" SortExpression="Name" />
                <asp:BoundField DataField="TrackingLocationFunction" 
                    HeaderText="Function" SortExpression="TrackingLocationFunction" />
                <asp:BoundField DataField="UnitCapacity" HeaderText="Unit Capacity" 
                    SortExpression="UnitCapacity" />
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server" Commandname="EditRow" CommandArgument='<%# Eval("ID") %>' Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>'>Edit</asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkDelete" runat="server" CausesValidation="False" CommandName="Delete" Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>' Visible='<%# Eval("CanDelete") %>' 
                        onclientclick="return confirm('Are you sure you want to delete this Test Station Type?');" 
                        Text="Delete"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        <asp:ObjectDataSource ID="odsTrackingLocationTypes" runat="server" 
            DeleteMethod="DeleteTLType" SelectMethod="GetTrackingLocationTypes" 
            TypeName="REMI.Bll.TrackingLocationManager" 
            OldValuesParameterFormatString="{0}">
            <DeleteParameters>
                <asp:Parameter Name="ID" Type="Int32" />
            </DeleteParameters>
        </asp:ObjectDataSource>
        
    </asp:Panel>
    <asp:Panel ID="pnlAddEdit" runat="server" Visible="false">
        <asp:HiddenField ID="hdnEditID" Value="" runat="server" />
            <h2><asp:Label ID="lblAddEditTitle" runat="server" Text="Add a new Tracking Location Type"></asp:Label></h2>
            <table style="width:73%;">
            <tr>
                <td class="HorizTableFirstcolumn">
                    Name:</td>
                <td>
                    <asp:TextBox ID="txtName" runat="server" Width="143px"></asp:TextBox>                 
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Function:</td>
                <td>
                  <asp:DropDownList ID="ddlFunction" runat="server" Width="193px"></asp:DropDownList>&nbsp;</td>
            </tr>
             <tr>
                <td class="HorizTableFirstcolumn">
                    Unit Capacity:</td>
                <td>
                    <asp:TextBox ID="txtUnitCapacity" runat="server" Width="143px"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Work Instruction Address:</td>
                <td>
                    <asp:TextBox ID="txtWorkInstructionLocation" runat="server" Width="424px" 
                        Rows="3" TextMode="MultiLine"></asp:TextBox>
                </td>
            </tr>
            </table>


    <br />
    </asp:Panel>

    </asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
    <h2>Instructions</h2><p>Here you can add edit or delete the test station types in the system.</p>
</asp:Content>

