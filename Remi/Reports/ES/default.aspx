<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ES_Default" Codebehind="default.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h2>Executive Summary</h2>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">

<asp:Label runat="server" ID="lblES"></asp:Label><br /><br />

<b>QRA Information:</b>
<asp:Table runat="server" ID="tblInfo" Width="500px">
</asp:Table>

<b>OverView:</b>
<asp:GridView ID="grdOverallSummary" runat="server" HeaderStyle-Wrap="false" AllowPaging="False"  EmptyDataText="There were no result found for this batch." AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" AutoGenerateColumns="True" CssClass="FilterableTable">
    <RowStyle CssClass="evenrow" />
    <HeaderStyle Wrap="False" />
    <AlternatingRowStyle CssClass="oddrow" />
</asp:GridView>
<br />

<asp:Panel runat="server" ID="pnlFailures" Visible="false"><b>Failure(s) Analysis:</b><br /></asp:Panel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>