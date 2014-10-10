<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageBatches_ModifyPriority" CodeBehind="ModifyPriority.aspx.vb" %>

<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>Modify Batch Priority</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                    runat="server" />
                <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to go back to the batch information page">Batch Info</asp:HyperLink>
            </li>
            <li id="liModifyStatus" runat="server" visible="false">
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeStatus" runat="server" />
                <asp:HyperLink ID="hypChangeStatus" runat="server" Target="_blank" ToolTip="Click to change the status for this batch">Modify Status</asp:HyperLink>
            </li>
            <li id="liModifyStage" runat="server" visible="false">
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeTestStage"
                    runat="server" />
                <asp:HyperLink ID="hypChangeTestStage" runat="server" Target="_blank" ToolTip="Click to change the test stage for this batch">Modify Stage</asp:HyperLink>
            </li>
            <li id="liModifyTestDurations" runat="server" visible="false">
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgModifyTestDurations"
                    runat="server" />
                <asp:HyperLink ID="hypModifyTestDurations" runat="server" Target="_blank" ToolTip="Click to change the test durations for this batch">Modify Durations</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSaveExceptions"
                    runat="server" />
                <asp:LinkButton ID="lkbSave" runat="Server" Text="Save" ToolTip="Click to save the status." />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" EnableViewState="false" />
                <asp:HyperLink ID="hypRefresh" runat="server">Refresh</asp:HyperLink>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" ToolTip="Click to cancel any changes made to the current batch" runat="server" />
                <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <h2>
        <asp:Label ID="lblQRANumber" runat="server"></asp:Label>
    </h2>
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlEditExceptions" runat="server" Visible="false">

        <br />
        Current Priority:
        <asp:Label ID="lblCurrentPriority" runat="server" Font-Bold="True"
            Font-Size="Medium" Text="Label"></asp:Label>
        <br />
        <br />
        New Priority:
        <asp:DropDownList Style="font-weight: bold;" ID="ddlSelection" runat="server" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        &nbsp;<br />
        <br />

        <asp:HiddenField ID="hdnQRANumber" runat="server" />
        <br />
    </asp:Panel>

</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>

