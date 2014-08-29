<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Inventory_InventoryReport" title="Untitled Page" Codebehind="InventoryReport.aspx.vb" %>

<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
           <h3> View
            </h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" Visible="false" ID="Image1"
                    runat="server" />
                <asp:Hyperlink ID="hypPickBatch" Visible="false" runat="Server" Text="Pick Batch" navigateURL="~/Inventory/Default.aspx"/></li>
             <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image2"
                    runat="server" />
                <asp:Hyperlink ID="hypInventoryReport" runat="Server" Text="Inventory Report" navigateURL="~/Inventory/InventoryReport.aspx"/></li>
                    <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image3"
                    runat="server" />
                <asp:Hyperlink ID="hypGenerateCountOrder" runat="Server" Text="Count Orders" navigateURL="~/Inventory/CountOrders.aspx"/></li>
</ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" Runat="Server">
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server">
</asp:ToolkitScriptManager><h1>
        Inventory Report</h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <br />
    Start Date:<asp:TextBox ID="txtStartDate" runat="server"></asp:TextBox><asp:CalendarExtender 
        ID="txtStartDate_CalendarExtender" runat="server" Enabled="True" 
        TargetControlID="txtStartDate">
    </asp:CalendarExtender>
    <br />
    End Date:<asp:TextBox ID="txtEndDate" runat="server"></asp:TextBox><asp:CalendarExtender 
        ID="txtEndDate_CalendarExtender" runat="server" Enabled="True" 
        TargetControlID="txtEndDate">
    </asp:CalendarExtender>
    <br />
    Test Center:<asp:DropDownList ID="ddlTestCenter" runat="server" DataTextField="LookupType" DataValueField="LookupID" 
        DataSourceID="odsTestCenters" Width="207px" AppendDataBoundItems="True">
    </asp:DropDownList>
    <br />
    <asp:CheckBox ID="chkFilterByQRA" runat="server" Text="Filter By Request Number" />
&nbsp;Year<br />
            <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                <SelectParameters>
                    <asp:Parameter Type="Int32" Name="Type" DefaultValue="4" />
                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                </SelectParameters>
            </asp:ObjectDataSource>
        <asp:Button ID="btnGetReport" runat="server" Text="Execute Report" cssclass="button"/>
    <br />
    <br />
    <b>Total Batches Recieved: </b>
    <asp:Label ID="lblTotalBatchesRecieved" runat="server"></asp:Label>
    <br />
    <b>Total Units Recieved: </b>
    <asp:Label ID="lblTotalUnitsRecieved" runat="server"></asp:Label>
    <br />
    <b>Average Units per Batch:</b>
    <asp:Label ID="lblAverageUnitsRecieved" runat="server"></asp:Label>
    <br />
    <br />
    Units Tracked over this time period.
    <asp:GridView ID="grdProductLocationReport" runat="server">
    </asp:GridView>
    <br />
    Batches/Units Recieved/Added over this time period.
    <asp:GridView ID="grdProductDistribution" runat="server">
    </asp:GridView>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

