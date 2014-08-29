<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageProducts_EnvReport" title="Reports" Codebehind="EnvReport.aspx.vb" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="NotificationList" tagprefix="uc1" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" Runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
<script type="text/javascript">
    function gvrowtoggle(row) {
        try {
            row_num = row;
            ctl_row = row - 1;
            rows = document.getElementById('<%= grdMain.ClientID %>').rows;
            rowElement = rows[ctl_row];
            img = rowElement.cells[0].firstChild;

            if (rows[row_num].className !== 'hidden')
            {
                rows[row_num].className = 'hidden';
                img.src = '/Design/Icons/png/16x16/link.png';
            }
            else {
                rows[row_num].className = '';
                img.src = '/Design/Icons/png/16x16/link.png';
            }
        }
        catch (ex) { alert(ex) }
    }

</script>
<h1>Report(s)</h1>
<uc1:NotificationList ID="notifications" runat="server" /><br /><br />
    Start: <asp:TextBox ID="txtStart" runat="server" DefaultValue="12am"></asp:TextBox>
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server"></asp:ToolkitScriptManager>
    <asp:CalendarExtender ID="txtStart_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtStart"></asp:CalendarExtender>
    <br />
    End:
    <asp:TextBox ID="txtEnd" runat="server" DefaultValue="12pm"></asp:TextBox>
    <asp:CalendarExtender ID="txtEnd_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtEnd"></asp:CalendarExtender>
    <br />
    Report Based On #: <asp:DropDownList ID="ddlReportBasedOn" runat="server">
        <asp:ListItem Value="1" Text="Batches" Selected="True"/>
        <asp:ListItem Value="2" Text="Units" Selected="False"/>
    </asp:DropDownList>
    <br />
    Test Centers: <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID">
    </asp:DropDownList>
    <br />
    <asp:Button ID="btnRunReport" runat="server" Text="Run Report" CssClass="button" />
    <asp:GridView ID="grdMain" runat="server" EmptyDataText="No data for the given time frame." EnableViewState="false" >
        <RowStyle CssClass="evenrow" />
        <AlternatingRowStyle CssClass="oddrow" />
    </asp:GridView>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

