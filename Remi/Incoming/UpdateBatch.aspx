<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Incoming_UpdateBatch" Codebehind="UpdateBatch.aspx.vb" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="NotificationList" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <!--[if lt IE 7.]>
<script defer type="text/javascript" src="../Design/scripts/pngfix.js"></script>
<![endif]-->
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" Runat="Server">
<h1>Incoming</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <h3>View</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
            <asp:Hyperlink ID="hypSetBSN" runat="Server" Text="Set BSNs" navigateURL="~/Incoming/Default.aspx"/></li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2" runat="server" />
            <asp:Hyperlink ID="hypUpdateBatch" runat="Server" Text="UpdateBatch" navigateURL="~/Incoming/UpdateBatch.aspx"/>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <h2>Update Batch</h2>
    <uc1:NotificationList ID="NotificationList1" runat="server" />
    <asp:CustomValidator ID="valQRANumber" runat="server" Display="Static" ControlToValidate="txtQRANumber" OnServerValidate="QRAValidation" ValidateEmptyText="true"></asp:CustomValidator>
    <p>
        Request Number:
        <asp:TextBox ID="txtQRANumber" runat="server" CausesValidation="true"></asp:TextBox>
        <asp:Button ID="btnUpdate" runat="server" Text="Update Batch" />
    </p>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>