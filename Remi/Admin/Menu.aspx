﻿<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" EnableEventValidation="false" Inherits="Remi.Menu" Title="Menu" Codebehind="Menu.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Menu Setup</h1>
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
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
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
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="Hyperlink8" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="hypTestStages" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications runat="server" ID="notMain" EnableViewState="false" />
    <br />
    <h2>Menu Options</h2>
    <asp:GridView runat="server" ID="grdMenu" AutoGenerateEditButton="true" ShowFooter="true" DataKeyNames="MenuID" OnRowEditing="grdMenu_OnRowEditing" OnRowCancelingEdit="grdMenu_OnRowCancelingEdit" OnRowUpdating="grdMenu_RowUpdating" AutoGenerateColumns="false">
        <Columns>
            <asp:BoundField DataField="MenuID" HeaderText="MenuID" Visible="false" SortExpression="MenuID" />
            <asp:TemplateField HeaderText="Name" SortExpression="Name">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblName" Text='<%# Eval("Name")%>' Visible="true" />
                    <asp:TextBox runat="server" ID="txtName" Text='<%# Eval("Name")%>' Visible="false" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:TextBox runat="server" ID="txtMenuName" ></asp:TextBox>
                </FooterTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Url" SortExpression="Url">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblUrl" Text='<%# Eval("Url")%>' Visible="true" />
                    <asp:TextBox runat="server" ID="txtUrl" Text='<%# Eval("Url")%>' Visible="false" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:TextBox runat="server" ID="txtMenuUrl" ></asp:TextBox>
                    <asp:Button ID="btnAddMenu" CssClass="buttonSmall" runat="server" Text="Add Menu" OnClick="btnAddMenu_Click" CausesValidation="true" />
                </FooterTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <br /><br />

    <h2>Menu Access</h2>
    Departments: <asp:DropDownList runat="server" ID="ddlDepartments" DataTextField="LookupType" DataValueField="LookupID" AutoPostBack="true"></asp:DropDownList>
    <br />
    <asp:GridView runat="server" ID="grdMenuAccess" ShowFooter="true" AutoGenerateColumns="false" AutoGenerateDeleteButton="true" DataKeyNames="MenuID,MenuDepartmentID" OnRowDeleting="grdMenuAccess_RowDeleting">
        <Columns>
            <asp:BoundField DataField="MenuID" HeaderText="MenuID" SortExpression="MenuID" Visible="false" />
            <asp:BoundField DataField="MenuDepartmentID" HeaderText="MenuDepartmentID" Visible="false" SortExpression="MenuDepartmentID" />
            <asp:TemplateField HeaderText="Name" SortExpression="">
                <ItemTemplate>
                        <asp:Label runat="server" ID="lblName" Text='<%# Eval("Name")%>' Visible="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:DropDownList runat="server" ID="ddlMenuOptions" DataTextField="Name" DataValueField="MenuID" DataSourceID="odsMenus"></asp:DropDownList>
                </FooterTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="Department" HeaderText="Department" SortExpression="Department" ReadOnly="true" />
            <asp:TemplateField HeaderText="Url" SortExpression="">
                <ItemTemplate>
                        <asp:Label runat="server" ID="lblUrl" Text='<%# Eval("Url")%>' Visible="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:Button ID="btnAddAccess" CssClass="buttonSmall" runat="server" Text="Add Access" OnClick="btnAddAccess_Click" CausesValidation="true" />
                </FooterTemplate>
            </asp:TemplateField>      
        </Columns>
    </asp:GridView>

    <asp:ObjectDataSource ID="odsMenus" runat="server" OldValuesParameterFormatString="original_{0}" SelectMethod="GetMenu" TypeName="REMI.Bll.SecurityManager"></asp:ObjectDataSource>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>