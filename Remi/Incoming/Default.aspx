<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Incoming_Default" Codebehind="Default.aspx.vb" %>
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
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                runat="server" />
            <asp:Hyperlink ID="hypSetBSN" runat="Server" Text="Set BSNs" navigateURL="~/Incoming/Default.aspx"/>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2" runat="server" />
            <asp:Hyperlink ID="hypUpdateBatch" runat="Server" Text="UpdateBatch" navigateURL="~/Incoming/UpdateBatch.aspx"/>
        </li>
    </ul>
    <h3>Actions</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddAction" runat="server" />
            <asp:LinkButton ID="lnkAddAction" runat="Server" Text="Confirm and Save" /></li><li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
            <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <div id="Add Unit">
        <h2> Set BSN</h2>
        <uc1:NotificationList ID="notMain" runat="server" />
        <table __designer:mapid="20">
            <tr __designer:mapid="21">
                <td class="HorizTableFirstcolumn" __designer:mapid="22">
                    Request Number:</td>
                <td __designer:mapid="23">
                    <asp:TextBox ID="txtQRANumber" runat="server" Width="152px"></asp:TextBox>
                </td>
            </tr>
            <tr __designer:mapid="26">
                <td class="HorizTableFirstcolumn" __designer:mapid="27">
                    BSN:                     </td>
                <td __designer:mapid="28">
                    <asp:TextBox ID="txtBSN" runat="server" Width="156px">0</asp:TextBox>
                </td>
            </tr>
        </table>
        <br />
    </div>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>