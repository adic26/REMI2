<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Admin_Logs" Codebehind="Logs.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="pageTitleContent" runat="server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>Developer Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../../Design/Icons/png/24x24/link.png" ID="Image4" runat="server" />
                <asp:HyperLink ID="hplMain" runat="Server" Text="Main" NavigateUrl="~/Admin/Developer/Default.aspx" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    Start:
    <asp:TextBox ID="txtStart" runat="server" DefaultValue="12am"></asp:TextBox><asp:ToolkitScriptManager
        ID="ToolkitScriptManager1" runat="server">
    </asp:ToolkitScriptManager>
    <asp:CalendarExtender ID="txtStart_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtStart" >
    </asp:CalendarExtender>
    <br />
    End:&nbsp;&nbsp;
    <asp:TextBox ID="txtEnd" runat="server" DefaultValue="12pm"></asp:TextBox>
    <asp:CalendarExtender ID="txtEnd_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtEnd">
    </asp:CalendarExtender>
    <br />
    <asp:Button ID="btnRunReport" runat="server" Text="Run Report" CssClass="button" />
    
    <div style="width:500px;border:3px">
        <asp:GridView ID="gvwApplicationLogs" AllowSorting="false" CellSpacing="10" runat="server" style="table-layout:fixed;word-wrap: break-word;" Width="1300px" AutoGenerateColumns="False" EnableViewState="True" EmptyDataText="There are no errors for this time">
            <RowStyle CssClass="evenrow" Wrap="true" />
            <Columns>
                <asp:BoundField DataField="Date" HeaderText="Date" HeaderStyle-Width="150px" ItemStyle-HorizontalAlign="Left" ReadOnly="true" />
                <asp:BoundField DataField="LogLevel" HeaderText="Error Type" HeaderStyle-Width="50px" ReadOnly="true" />
                <asp:BoundField DataField="Logger" HeaderText="Logger" HeaderStyle-Width="180px" ReadOnly="true" />
                <asp:BoundField DataField="Message" HeaderText="Message" ReadOnly="true" HeaderStyle-Width="460px" ItemStyle-Width="920px" />
                <asp:BoundField DataField="Exception" HeaderText="Exception" ReadOnly="true" HeaderStyle-Width="460px" ItemStyle-Width="920px" />
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" Wrap="true" />
        </asp:GridView>
    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
