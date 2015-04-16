<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Inventory_BatchesNotInREMIReport" Title="Generate Count Orders" CodeBehind="BatchesNotInREMIReport.aspx.vb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_grdMain').columnFilters(
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
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>View
    </h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
            <asp:HyperLink ID="hypPickBatch" runat="Server" Text="Pick Batch" NavigateUrl="~/Inventory/Default.aspx" />
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2" runat="server" />
            <asp:HyperLink ID="hypInventoryReport" runat="Server" Text="Inventory Report" NavigateUrl="~/Inventory/InventoryReport.aspx" />
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image3" runat="server" />
            <asp:HyperLink ID="hypGenerateCountOrder" runat="Server" Text="Count Orders" NavigateUrl="~/Inventory/CountOrders.aspx" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>Units not in REMSTAR</h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Label runat="server" ID="lblDate"></asp:Label>
    <br />

    <asp:GridView ID="grdMain" runat="server" AutoGenerateColumns="False" DataSourceID="odsMain" CssClass="FilterableTable">
        <Columns>
            <asp:BoundField DataField="QRANumber" HeaderText="Request Number"
                SortExpression="QRANumber" />
            <asp:BoundField DataField="UnitNumber" HeaderText="Unit Number"
                SortExpression="UnitNumber" />
            <asp:BoundField DataField="Location" HeaderText="Location"
                SortExpression="Location" />
            <asp:BoundField DataField="LastUser" HeaderText="Last User"
                SortExpression="LastUser" />
            <asp:TemplateField HeaderText="Last Date"
                SortExpression="LastDate">
                <ItemTemplate>
                    <asp:Label ID="lblData" runat="server" Text='<%# Remi.BusinessEntities.Helpers.DateTimeformat(Eval("LastDate"))%>'></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <asp:ObjectDataSource ID="odsMain" runat="server"
        OldValuesParameterFormatString="original_{0}"
        SelectMethod="GetTestUnitsNotInREMI" TypeName="REMI.Bll.TestUnitManager"></asp:ObjectDataSource>
    <br /><br />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>