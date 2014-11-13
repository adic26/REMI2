<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Incoming_Default" CodeBehind="Default.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <!--[if lt IE 7.]>
<script defer type="text/javascript" src="../Design/scripts/pngfix.js"></script>
<![endif]-->
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>Incoming</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>Actions</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddAction" runat="server" />
            <asp:LinkButton ID="lnkAddAction" runat="Server" Text="Confirm and Save" /></li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
            <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <div id="Add Unit">
        <h2>BSN update</h2>
        <uc1:NotificationList ID="notMain" runat="server" />
        <table>
            <tr>
                <td class="HorizTableFirstcolumn">Request /w Unit:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtRequestUnit" Runat="server" Width="152px"></asp:TextBox>
                    <asp:CustomValidator ID="valRequestUnit" runat="server" Display="Static" ControlToValidate="txtRequestUnit" OnServerValidate="Validation" ValidateEmptyText="false"></asp:CustomValidator>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">BSN:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtBSN" runat="server" Width="156px">0</asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">IMEI:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox runat="server" ID="txtIMEI" Width="156px"></asp:TextBox>
                </td>
            </tr>
        </table>
        
        <h2>Update Request</h2>
        <table>
            <tr>
                <td class="HorizTableFirstcolumn">Request Number</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtQRANumber" runat="server" Width="152px"></asp:TextBox>
                    <asp:CustomValidator ID="valQRANumber" runat="server" Display="Static" ControlToValidate="txtQRANumber" OnServerValidate="Validation" ValidateEmptyText="false"></asp:CustomValidator>
                </td>
            </tr>
        </table>
        <br /><br />
    </div>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
