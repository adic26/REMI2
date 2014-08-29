<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageBatches_ModifyComments" Title="Modify Batch Comments" CodeBehind="ModifyComments.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to go back to the batch information page">Batch Info</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSaveExceptions"
                    runat="server" />
                <asp:LinkButton ID="lkbSave" runat="Server" Text="Save" ToolTip="Click to save the status." /></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" ToolTip="Click to cancel any changes made to the current batch"
                        runat="server" />
                    <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
                </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <h2>
        <asp:Label ID="lblQRANumber" runat="server"></asp:Label>
    </h2>
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlEditExceptions" runat="server" Visible="false">
        Current Comments: &nbsp;<asp:Label ID="lblComments" runat="server" Font-Bold="true" Font-Size="Medium" Text="Label"></asp:Label>
        <br /><br />
        New Comments:&nbsp;<asp:TextBox ID="txtRFBands" runat="server" Width="157px"></asp:TextBox>
        <asp:HiddenField ID="hdnQRANumber" runat="server" />
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>