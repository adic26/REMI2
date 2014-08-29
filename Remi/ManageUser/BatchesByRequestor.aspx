<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageUser_BatchesByRequestor" Title="Untitled Page" Codebehind="BatchesByRequestor.aspx.vb" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc1" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server">
    </asp:ToolkitScriptManager>
    <h3>Menu</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" />
            <asp:HyperLink ID="hypRefresh" runat="server" NavigateUrl="./default.aspx">Refresh</asp:HyperLink></li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgManageUnits" runat="server" />
            <asp:HyperLink ID="hypManageUnits" runat="server" NavigateUrl="./default.aspx">View Your Units</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeLocation" runat="server" />
            <asp:HyperLink ID="hypChangeLocation" runat="server" NavigateUrl="../badgeaccess/EditmyUser.aspx">Edit My User</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgRequestedBatches" runat="server" />
            <asp:HyperLink ID="hypRequestedBatches" runat="server" NavigateUrl="./BatchesByRequestor.aspx">Requested Batches</asp:HyperLink>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>
        Batches Requested By <asp:Label ID="lblUserNameTitle" runat="server"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <br /><asp:AutoCompleteExtender runat="server" ID="aceTxtAssignedTo" TargetControlID="txtUserName"
        ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20" >
    </asp:AutoCompleteExtender>
    Enter A UserName: <asp:TextBox ID="txtUserName" runat="server"></asp:TextBox>&nbsp;
    <asp:Button ID="btnSearch" runat="server" Text="Search User" /><br /><br />
    <uc1:BatchSelectControl ID="bscMain" runat="server" DisplayMode="SearchInfoDisplay" EmptyDataText="No batches found." />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>