<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageBatches_ModifyStatus" Codebehind="ModifyStatus.aspx.vb" %>

<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" Runat="Server">
    <h1>Modify Batch Status</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>
            Menu</h3>
        <ul>
              <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                    runat="server" />
                <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to go back to the batch information page">Batch Info</asp:HyperLink>
            </li>
            </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>
            Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSaveExceptions"
                    runat="server" />
                <asp:LinkButton ID="lkbSave" runat="Server" Text="Save"  
                    ToolTip="Click to save the status."/>
            </li>
            <li>                    
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" EnableViewState="false" />
                    <asp:HyperLink ID="hypRefresh" runat="server">Refresh</asp:HyperLink>
            </li>
            <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" tooltip="Click to cancel any changes made to the current exceptions"  runat="server" />
                    <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
            </li></ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
     <h2>
            <asp:Label ID="lblQRANumber" runat="server"></asp:Label>
        </h2>
      <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlEditExceptions" runat="server" Visible="false">
     
        <br />
        Current Status:
        <asp:Label ID="lblCurrentStatus" runat="server" Font-Bold="True" 
            Font-Size="Medium" Text="Label"></asp:Label>
        <br />
        <br />
        New Status:
        <asp:DropDownList Style="font-weight: bold;" ID="ddlSelection" runat="server" 
            Width="157px">
        </asp:DropDownList>
        &nbsp;<br />
        <br />
        
        <asp:HiddenField ID="hdnQRANumber" runat="server" />
        <br />
    </asp:Panel>

</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

