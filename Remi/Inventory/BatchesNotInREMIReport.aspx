<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Inventory_BatchesNotInREMIReport" title="Generate Count Orders" Codebehind="BatchesNotInREMIReport.aspx.vb" %>

<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
           <h3> View
            </h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                    runat="server" />
                <asp:Hyperlink ID="hypPickBatch" runat="Server" Text="Pick Batch" navigateURL="~/Inventory/Default.aspx"/></li>
             <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2"
                    runat="server" />
                <asp:Hyperlink ID="hypInventoryReport" runat="Server" Text="Inventory Report" navigateURL="~/Inventory/InventoryReport.aspx"/></li>
                    <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image3"
                    runat="server" />
                <asp:Hyperlink ID="hypGenerateCountOrder" runat="Server" Text="Count Orders" navigateURL="~/Inventory/CountOrders.aspx"/></li>
</ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" Runat="Server">
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server">
</asp:ToolkitScriptManager><h1>
        Units not in REMSTAR</h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:label runat="server" id="lblDate"></asp:label> 
    <br />
    
    <asp:GridView ID="grdMain" runat="server" AutoGenerateColumns="False" 
        DataSourceID="odsMain">
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
                                    <asp:Label ID="lblData" runat="server" Text='<%# Remi.Helpers.datetimeformat(Eval("LastDate")) %>'></asp:Label>
                                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <asp:ObjectDataSource ID="odsMain" runat="server" 
        OldValuesParameterFormatString="original_{0}" 
        SelectMethod="GetTestUnitsNotInREMI" TypeName="REMI.Bll.TestUnitManager">
    </asp:ObjectDataSource>
    <br />
    <br />

    </asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

