<%@ Page Language="vb" EnableViewState="true" AutoEventWireup="false" CodeBehind="Request.aspx.vb" Inherits="Remi.Request" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <asp:HyperLink runat="server" ID="hypAdmin" Visible="false" Text="Admin" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypBatch" Visible="false" Text="Batch" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypResults" Text="Results" Visible="false" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypNew" Enabled="true" Text="Create Request" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:CheckBox runat="server" ID="chkDisplayChanges" Text="Display Changes" Visible="false" TextAlign="Right" AutoPostBack="true" OnCheckedChanged="chkDisplayChanges_CheckedChanged" />
            </li>
            <li>
                <asp:Button runat="server" ID="btnSave" Text="Save Request" CssClass="buttonSmall" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField runat="server" ID="hdnRequestType" />
    <asp:HiddenField runat="server" ID="hdnRequestTypeID" />
    <asp:HiddenField runat="server" ID="hdnRequestNumber" />
    
    <uc1:NotificationList ID="notMain" runat="server" />

    
    <asp:Panel runat="server" ID="pnlDisplayChanges" Visible="false">
        <asp:GridView ID="grdDisplayChanges" runat="server" DataSourceID="odsDisplayChanges" AutoGenerateColumns="True" EnableViewState="False" EmptyDataText="No Changes">
        </asp:GridView>
        <asp:ObjectDataSource ID="odsDisplayChanges" runat="server" SelectMethod="GetRequestAuditLogs" TypeName="REMI.Bll.RequestManager">
            <SelectParameters>
                <asp:ControlParameter ControlID="hdnRequestNumber" Name="requestNumber" PropertyName="Value" Type="String" />
            </SelectParameters>
        </asp:ObjectDataSource>
    </asp:Panel>
    <br />
    <asp:Panel runat="server" ID="pnlRequest" EnableViewState="true">
        <asp:Table runat="server" ID="tbl" Width="70%" EnableViewState="true" CssClass="requestTable"></asp:Table>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>