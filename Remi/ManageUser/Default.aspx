<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ManageUser_Default" title="Untitled Page" Codebehind="Default.aspx.vb" %>

<%@ Register src="../Controls/BatchSelectControl.ascx" tagname="BatchSelectControl" tagprefix="uc3" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
<h3>Menu</h3><ul><li> <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" />
            <asp:HyperLink ID="hypRefresh" runat="server" NavigateUrl="./default.aspx">Refresh</asp:HyperLink></li>
                                <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgManageUnits" runat="server" />
         <asp:HyperLink ID="hypManageUnits" runat="server" NavigateUrl="./default.aspx">View Your Units</asp:HyperLink>
        </li>
            <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeLocation" runat="server" />
         <asp:HyperLink ID="hypChangeLocation" runat="server" NavigateUrl="../Badgeaccess/EditmyUser.aspx">Edit My User</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgRequestedBatches" runat="server" />
         <asp:HyperLink ID="hypRequestedBatches" runat="server" NavigateUrl="./BatchesByRequestor.aspx">Requested Batches</asp:HyperLink>
        </li>
            
            </ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" Runat="Server">
    <h1>Units assigned to
        <asp:Label ID="lblUserNameTitle" runat="server"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <br /><br />
    <asp:Label runat="server" ID="lblUsers" Visible="false">Change User:</asp:Label>
    <asp:DropDownList runat="server" Visible="false" ID="ddlUsers" AutoPostBack="true" DataTextField="LDAPName" DataValueField="ID" ></asp:DropDownList>
    <br />
    <asp:CheckBox runat="server" ID="chkIncludeCompleted" AutoPostBack="true" CausesValidation="true" Text="Include Completed Requests" />
    <span>
    <asp:GridView ID="grdDetail" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" EnableViewState="false" Width="81%" EmptyDataText="No Unit Information Available." >
        <RowStyle CssClass="evenrow" />
        <Columns>
            <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" SortExpression="ID" Visible="False" />
            <asp:TemplateField HeaderText="RequestNumber" SortExpression="QRANumber">
                <ItemTemplate>
                 <asp:HyperLink ID="hypBUN" runat="server" ToolTip="Click to view the information for this Batch" Target="_blank" NavigateUrl='<%# Eval("BatchInfoLink") %>' Text='<%# Eval("QRANumber") %>'></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Unit #" SortExpression="BatchUnitNumber">
                <ItemTemplate>
                    <asp:HyperLink ID="hypBUN" runat="server" ToolTip="Click to view the information for this Unit" Target="_blank" NavigateUrl='<%# Eval("UnitInfoLink") %>' Text='<%# Eval("BatchUnitNumber") %>'></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="BSN" SortExpression="BSN">
                <ItemTemplate>
                    <asp:HyperLink ID="hypBSN" runat="server" Target="_blank" ToolTip="Click to view the manufactuaring information page for this Unit" NavigateUrl='<%# Eval("MfgWebLink") %>' Text='<%# Eval("BSN") %>'></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Current Test Stage" SortExpression="CurrentTestStage">
                <ItemTemplate>
                    <asp:Label ID="Label4" runat="server" Text='<%# Eval("CurrentTestStage") %>'></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Current Test" SortExpression="CurrentTest">
                <ItemTemplate>
                    <asp:Label ID="Label3" runat="server" Text='<%# Eval("CurrentTest") %>'></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Current Location">
                <ItemTemplate>
                    <asp:Label ID="Label5" runat="server" Text='<%# Eval("LocationString") %>'></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
        <AlternatingRowStyle CssClass="oddrow" />
    </asp:GridView>
    </span>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>