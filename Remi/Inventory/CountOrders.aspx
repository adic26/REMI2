<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Inventory_CountOrders" title="Generate Count Orders" Codebehind="CountOrders.aspx.vb" %>

<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
           <h3> View
            </h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" Visible="false"
                    runat="server" />
                <asp:Hyperlink ID="hypPickBatch" runat="Server" Text="Pick Batch" Visible="false" navigateURL="~/Inventory/Default.aspx"/></li>
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
        Generate Count Order</h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <br />
        <asp:Button ID="btnGetReport" runat="server" Text="Execute Order" 
        cssclass="button"/>
    <br />
    <br />
    <br />
    </asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

