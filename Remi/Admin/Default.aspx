<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"
    AutoEventWireup="false" Inherits="Remi.Admin_Default" Codebehind="Default.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
  <h1>
        Administration</h1>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
  
    <ul>
        <li>Process Flow</li><ul>
            <li><a href="Tests.aspx">Tests</a></li>
            <li><a href="TestStages.aspx">Test Stages</a></li>
            <li><a href="Jobs.aspx">Jobs</a></li></ul>
<%--        <li>Test Stations</li><ul>
                  <li><a href="TestStationSchedules.aspx">Test Station Schedules</a></li>--%>
        <li>Batches</li><ul>
            <%--<li><a href="TestUnits.aspx">Test Units</a></li>--%>
            <li><a href="Batches.aspx">Batches</a></li>
        <%-- <li>Test Assignments</li>--%></ul>
        <li>Tracking Locations</li><ul>
            <li><a href="TrackingLocations.aspx">Tracking Locations</a></li>
            <li><a href="TrackingLocationTypes.aspx">Tracking Location Types</a></li>
            <li><a href="GeoLocations.aspx">Geographical Locations</a></li></ul>
        <li>Users</li><ul>
                <li><a href= "Users.aspx">Users</a></li>
             
    </ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
    <h2>
        Instructions</h2>
    <p>
        Welcome to the administration panel. Select an item on the left that you would like
        to edit</p>
</asp:Content>
