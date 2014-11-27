<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" Inherits="Remi.Security" Title="Security" EnableEventValidation="false" Codebehind="Security.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script type="text/javascript">
        function EnableDisablePermission_Click(permission, role)
        {
            $.ajax({
                type: "POST",
                url: "security.aspx/AddRemovePermission",
                data: '{permission: "' + permission + '", role: "' + role + '" }',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    if (response.d == true) {
                    } else {
                        alert("Add Remove Permission Failed");
                    }
                },
                failure: function (response) {
                    alert("Add Remove Permission Failed");
                }
            });
        }
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
    <h1>Security</h1>
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
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="Hyperlink7" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:hyperlink ID="Hyperlink8" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>
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
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="HyperLink5" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" EnableViewState="false" />
    <br/><h2>Permission To Role Assignment</h2>
    <asp:GridView ID="gvwSecurity" AutoGenerateColumns="true" ShowFooter="true" runat="server" CssClass="VerticalTable" EnableViewState="False" EmptyDataText="There are no roles or permissions.">
        <RowStyle CssClass="evenrow" />
        <AlternatingRowStyle CssClass="oddrow" />
        <FooterStyle HorizontalAlign="Left" />
    </asp:GridView>
    
    <br/><h2>Services</h2>
    <asp:GridView runat="server" ID="grdServices" AutoGenerateColumns="false" ShowFooter="true" DataKeyNames="ServiceID" CssClass="VerticalTable" EnableViewState="true" EmptyDataText="There Is No Services" AutoGenerateEditButton="true" OnRowEditing="grdServices_OnRowEditing" OnRowCancelingEdit="grdServices_OnRowCancelingEdit" OnRowUpdating="grdServices_RowUpdating">
        <Columns>
            <asp:BoundField DataField="ServiceID" HeaderText="ServiceID" ReadOnly="true" SortExpression="ServiceID" />
            <asp:TemplateField HeaderText="Service Name" SortExpression="ServiceName">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblServiceName" Text='<%# Eval("ServiceName")%>' Visible="true" />
                    <asp:TextBox runat="server" ID="txtServiceName" Text='<%# Eval("ServiceName")%>' Visible="false" EnableViewState="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:TextBox runat="server" ID="txtServiceName" ></asp:TextBox>
                </FooterTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Active" SortExpression="Active">
                <ItemTemplate>
                    <asp:CheckBox runat="server" ID="chkActive" Checked='<%# Eval("IsActive")%>' Enabled="false" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:Button ID="btnAddService" CssClass="buttonSmall" runat="server" Text="Add Service" OnClick="btnAddService_Click" CausesValidation="true" />
                </FooterTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
        
    <br/><h2>Service Access</h2>
    Departments: <asp:DropDownList runat="server" ID="ddlDepartments" DataTextField="LookupType" DataValueField="LookupID" AutoPostBack="true"></asp:DropDownList><br />
    <asp:GridView runat="server" ID="grdServiceAccess" AutoGenerateColumns="false" ShowFooter="true" DataKeyNames="ServiceID,ServiceAccessID" AutoGenerateDeleteButton="true" OnRowDeleting="grdServiceAccess_RowDeleting" EmptyDataText="There Is No service Level Access For This Department">
        <Columns>
            <asp:BoundField DataField="ServiceID" HeaderText="ServiceID" ReadOnly="true" SortExpression="ServiceID" />
            <asp:TemplateField HeaderText="Service Name" SortExpression="ServiceName">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblServiceName" Text='<%# Eval("ServiceName")%>' Visible="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:DropDownList runat="server" ID="ddlServiceOptions" DataTextField="ServiceName" DataValueField="ServiceID" DataSourceID="odsServiceAccess"></asp:DropDownList>
                </FooterTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="ServiceAccessID" HeaderText="ServiceAccessID" ReadOnly="true" SortExpression="ServiceAccessID" />
            <asp:TemplateField HeaderText="Department" SortExpression="Department">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblDepartment" Text='<%# Eval("Values")%>' Visible="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:Button ID="btnAddServiceAccess" CssClass="buttonSmall" runat="server" Text="Add Access" OnClick="btnAddServiceAccess_Click" CausesValidation="true" />
                </FooterTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <asp:ObjectDataSource runat="server" ID="odsServiceAccess" OldValuesParameterFormatString="original_{0}" SelectMethod="GetServices" TypeName="REMI.Bll.SecurityManager"></asp:ObjectDataSource>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>