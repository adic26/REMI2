<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Admin_Lookups" Title="Lookups" Codebehind="Lookups.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
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
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="hypTestStages" runat="Server" Text="Tests" NavigateUrl="~/Admin/tests.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image9" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddTestStageAction" runat="server" />
                <asp:LinkButton ID="lnkAddLookupAction" runat="Server" Text="Confirm and Save" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <h1>Lookups</h1>
    Select A Lookup Type: <asp:DropDownList ID="ddlLookupList" runat="server" AutoPostBack="True"></asp:DropDownList> 
    
    <asp:GridView runat="server" ID="gdvLookups" AutoGenerateColumns="false" ShowFooter="true" EnableViewState="true" OnRowEditing="gdvLookups_OnRowEditing" DataKeyNames="LookupType" AutoGenerateEditButton="true" OnRowCancelingEdit="gdvLookups_OnRowCancelingEdit" OnRowUpdating="gdvLookups_RowUpdating">
        <Columns>
            <asp:BoundField DataField="LookupID" HeaderText="LookupID" ReadOnly="true" SortExpression="LookupID" />
            <asp:TemplateField HeaderText="Description" SortExpression="Description">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblValue" Text='<%# Eval("LookupType")%>' Visible="true" ReadOnly="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:TextBox runat="server" ID="txtValue" Visible="true" />
                </FooterTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Description" SortExpression="Description">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblDescription" Text='<%# Eval("Description")%>' Visible="true" />
                    <asp:TextBox runat="server" ID="txtDescription" Text='<%# Eval("Description")%>' Visible="false" EnableViewState="true" />
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:TextBox runat="server" ID="txtDescription" Visible="true" />
                </FooterTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Parent" SortExpression="Parent">
                <ItemTemplate>
                    <asp:HiddenField runat="server" ID="hdnParentID" Value='<%# Eval("ParentID")%>' />
                    <asp:Label runat="server" ID="lblParent" Text='<%# Eval("Parent")%>' Visible="true" />
                    <asp:DropDownList runat="server" ID="ddlParentID" DataTextField="DisplayText" DataValueField="LookupID" Visible="false"></asp:DropDownList>
                </ItemTemplate>
                <FooterStyle HorizontalAlign="Right" />
                <FooterTemplate>
                    <asp:DropDownList runat="server" ID="ddlFooterParentID" DataTextField="DisplayText" DataSourceID="odsLookups" DataValueField="LookupID" Visible="true"></asp:DropDownList>
                </FooterTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Active" SortExpression="Active">
                <ItemTemplate>
                    <asp:CheckBox runat="server" ID="chkActive" Checked="true" Enabled="false" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    
    <asp:ObjectDataSource ID="odsLookups" runat="server" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLookups" TypeName="REMI.Bll.LookupsManager">
        <SelectParameters>
            <asp:ControlParameter ControlID="ctl00$Content$ddlLookupList" Name="Type" PropertyName="SelectedValue" Type="String" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <h1>Target Access</h1>

    <asp:GridView runat="server" ID="gdvTargetAccess" AutoGenerateColumns="false" DataKeyNames="ID" OnRowCommand="gdvTargetAccess_RowCommand">
        <Columns>
            <asp:BoundField DataField="ID" HeaderText="ID" ReadOnly="true" SortExpression="ID" />
            <asp:BoundField DataField="TargetName" HeaderText="Name" ReadOnly="true" SortExpression="TargetName" />
            <asp:TemplateField HeaderText="Deny Access" SortExpression="DenyAccess">
                <ItemTemplate>
                    <asp:CheckBox runat="server" ID="chkDenyAccess" Checked='<%# Eval("DenyAccess") %>' OnCheckedChanged="chkDenyAccess_OnCheckedChanged" AutoPostBack="true" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="WorkstationName" HeaderText="WorkstationName" ReadOnly="true" SortExpression="WorkstationName" /> 
            <asp:TemplateField ShowHeader="False">
                <ItemTemplate>
                    <asp:LinkButton ID="lnkDelete" runat="server"  
                        CommandArgument='<%# Eval("ID") %>' onclientclick="return confirm('Are you sure you want to delete this Target Access?');" CommandName="DeleteItem">Delete</asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>       
        </Columns>
    </asp:GridView>

    <h3>Add New Target Access:</h3>
    Target Name: <asp:TextBox runat="server" ID="txtTargetName"></asp:TextBox><br />
    Workstation Name: <asp:TextBox runat="server" ID="txtWorkStationname"></asp:TextBox><label style="color:Red;font-size:8pt;">Leave blank for all workstations</label><br />
    Deny Access: <asp:CheckBox runat="server" ID="chkDeny" /><br />
    <asp:Button runat="server" ID="btnAddTarget" Text="Add Target" OnClick="btnAddTarget_OnClick" />
    
    <h1>Application Versions</h1>

    <asp:GridView runat="server" ID="gdvApplications" AutoGenerateColumns="false" EnableViewState="true" DataKeyNames="ID" OnRowEditing="gdvApplications_OnRowEditing" AutoGenerateEditButton="true" OnRowCancelingEdit="gdvApplications_OnRowCancelingEdit" OnRowUpdating="gdvApplications_RowUpdating">
        <Columns>
            <asp:BoundField DataField="ID" HeaderText="ID" ReadOnly="true" SortExpression="ID" />
            <asp:TemplateField HeaderText="Application Name" SortExpression="ApplicationName">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblApplicationName" Text='<%# Eval("ApplicationName") %>' />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Version" SortExpression="VersionNumber">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblVersion" Text='<%# Eval("VersionNumber") %>' Visible="true" />
                    <asp:TextBox runat="server" ID="txtVersion" Text='<%# Eval("VersionNumber") %>' Visible="false" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Applicable To All" SortExpression="ApplicableToAll">
                <ItemTemplate>
                    <asp:CheckBox runat="server" Checked='<%# Eval("ApplicableToAll")%>' ID="chkATA" Enabled="false" />
                 </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
    <br /><br />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>