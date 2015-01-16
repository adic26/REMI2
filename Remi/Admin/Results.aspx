<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" ValidateRequest="false" Inherits="Remi.Admin_Results" Title="Results" Codebehind="Results.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>


<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Results</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>Admin Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image4" runat="server" />
                <asp:HyperLink ID="Hyperlink3" runat="Server" Text="Tracking Locs" NavigateUrl="~/Admin/trackinglocations.aspx" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:hyperlink ID="Hyperlink7" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="Image5" runat="server" />
                <asp:HyperLink ID="Hyperlink4" runat="Server" Text="Users" NavigateUrl="~/Admin/users.aspx" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:HyperLink ID="Hyperlink2" runat="Server" Text="Process Flow" NavigateUrl="~/Admin/Jobs.aspx" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="hypTestStages" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
<uc1:Notifications ID="NotifList" runat="server" />

<h3>Change Stage</h3>
<asp:Label ID="lblQRA" runat="server">Select Request: </asp:Label><asp:DropDownList ID="ddlBatches" runat="server" AutoPostBack="true" CausesValidation="true" AppendDataBoundItems="true"><asp:ListItem Value="0">Select</asp:ListItem></asp:DropDownList><br />
<asp:Label ID="lblUnits" runat="server" Visible="false">Select Unit: </asp:Label><asp:DropDownList ID="ddlUnits" runat="server" AutoPostBack="true" CausesValidation="true" AppendDataBoundItems="true" Visible="false"><asp:ListItem Value="-1">Select</asp:ListItem><asp:ListItem Value="0">All Units</asp:ListItem></asp:DropDownList><br />
<asp:Label ID="lblTest" runat="server" Visible="false">Select Test: </asp:Label><asp:DropDownList ID="ddlTests" runat="server" AutoPostBack="true" CausesValidation="true" Visible="false" AppendDataBoundItems="true"><asp:ListItem Value="0">Select</asp:ListItem></asp:DropDownList><br />
<asp:Label ID="lblTestStage" runat="server" Visible="false">Select Stage: </asp:Label><asp:DropDownList ID="ddlTestStages" runat="server" AutoPostBack="true" CausesValidation="true" Visible="false" AppendDataBoundItems="true"><asp:ListItem Value="0">Select</asp:ListItem></asp:DropDownList><br />
<asp:Label ID="lblNewTestStage" runat="server" Visible="false">Select New Stage: </asp:Label><asp:DropDownList ID="ddlNewTestStages" runat="server" AutoPostBack="false" CausesValidation="true" Visible="false" AppendDataBoundItems="false"></asp:DropDownList><br />
<asp:Button runat="server" Visible="false" ID="btnReassign" Text="Reassign Request Stage" OnClick="btnReassign_OnClick" />

<br /><br />

<h3>Upload Result XML File</h3>
<asp:Button runat="server" ID="btnUpload" OnClick="btnUpload_OnClick" Text="Upload XML File" /><br />
<asp:TextBox runat="server" ID="txtXMLResult" TextMode="MultiLine" Rows="40" Columns="60"></asp:TextBox>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>