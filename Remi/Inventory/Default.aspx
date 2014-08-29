<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Inventory_FastPick" CodeBehind="Default.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>Pick Batch</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>View</h3>
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
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:notificationlist id="notMain" runat="server" />
    <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility: hidden;display: none;" />
    <img alt="Scan Barcode into text box" class="ScanDeviceImage" src="../Design/Icons/png/48x48/barcode.png" />
    &nbsp;<asp:TextBox ID="txtBarcodeReading" runat="server" CssClass="ScanDeviceTextEntryHint"
        value="Enter Request Number..." onfocus="if (this.className=='ScanDeviceTextEntryHint') { this.className = 'ScanDeviceTextEntry'; this.value = ''; }"
        onblur="if (this.value == '') { this.className = 'ScanDeviceTextEntryHint'; this.value = 'Enter Request Number...'; }"></asp:TextBox>
    <asp:Button ID="btnSubmit" runat="server" CssClass="ScanDeviceButton" Text="Submit" />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>