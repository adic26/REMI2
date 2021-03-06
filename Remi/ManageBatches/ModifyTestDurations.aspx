﻿<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageBatches_ModifyTestDurations" Title="Untitled Page" CodeBehind="ModifyTestDurations.aspx.vb" %>

<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">

    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                    runat="server" />
                <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to go back to the batch information page">Batch Info</asp:HyperLink>
            </li>
            <li id="liModifyStage" runat="server" visible="false">
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeTestStage"
                    runat="server" />
                <asp:HyperLink ID="hypChangeTestStage" runat="server" Target="_blank" ToolTip="Click to change the test stage for this batch">Modify Stage</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSave"
                    runat="server" />
                <asp:LinkButton ID="lkbSave" runat="Server" Text="Save"
                    ToolTip="Click to save the status." />
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
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <h2>
        <asp:Label ID="lblQRANumber" runat="server"></asp:Label>
    </h2>
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlEdit" runat="server" Visible="false">

        <asp:GridView ID="grdOverview" runat="server" AutoGenerateColumns="true">
            <RowStyle CssClass="evenrow" />
        </asp:GridView>

        <br />
        <asp:DropDownList ID="ddlSelectTestStage" runat="server" Width="214px">
        </asp:DropDownList>
        <asp:Button ID="btnRevertToDefault" runat="server" Text="Revert to Default" />
        <br />
        <br />
        Duration (h):
        <asp:TextBox ID="txtDuration" runat="server" Width="56px"></asp:TextBox>
        <br />
        <br />
        <br />
        <asp:HiddenField ID="hdnQRANumber" runat="server" />
        <br />
    </asp:Panel>

</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>

