<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"
    MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.BadgeAccess_Default"
    CodeBehind="default.aspx.vb" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <p>
        You must authenticate before using REMI. If you cannot access the system and you feel that you should please contact support.
    </p>
    <div style="float:left;width:400px;">
        <h2>Please Scan Your Security Badge</h2>
        <p>If this is your first time logging in then use the UserName and Password area to authenticate and create your account. <br/><b>Badge Number is on the back of your security badge between "4*" and "-E".</b></p>
        <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility: hidden;display: none;" />
        <img alt="Scan Badge into text box" class="ScanDeviceImage" src="../Design/Icons/png/48x48/barcode.png" />
        <asp:TextBox ID="txtBadgeNumber" TextMode="Password" CssClass="ScanDeviceTextEntry" runat="server"></asp:TextBox>
        &nbsp;<asp:Button ID="btnSubmit" CssClass="ScanDeviceButton" runat="server" Text="Submit" />
    </div>
    <div style="float:left;width:400px;">
        <h2>Please Enter Your Windows Credentials</h2>
        <p><b>OR</b> Use Your Windows Credentials</p>
        <table>
            <tr>
                <td class="HorizTableFirstcolumn">
                    UserName *:
                </td>
                <td style="text-align: left">
                    <asp:TextBox ID="txtUserName" runat="server" CausesValidation="true"></asp:TextBox>
                    <asp:CustomValidator ID="valUserName" runat="server" Display="Static" ControlToValidate="txtUserName" OnServerValidate="UserNameValidation" ValidateEmptyText="true"></asp:CustomValidator>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Password *:
                </td>
                <td style="text-align: left">
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CausesValidation="true"></asp:TextBox>
                    <asp:CustomValidator ID="valPassword" runat="server" Display="Static" ControlToValidate="txtPassword"
                        OnServerValidate="PasswordValidation" ValidateEmptyText="true"></asp:CustomValidator>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Test Center:
                </td>
                <td style="text-align: left">
                    <asp:DropDownList ID="ddlGeoLoc" runat="server" DataSourceID="odsTestCentres" Width="195px"
                        DataTextField="LookupType" DataValueField="LookupID">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsTestCentres" runat="server" SelectMethod="GetLookups"
                        TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                        <SelectParameters>
                            <asp:Parameter Type="String" Name="Type" DefaultValue="TestCenter" />
                            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="1" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Department:
                </td>
                <td style="text-align: left">
                    <asp:DropDownList ID="ddlDepartments" runat="server" DataSourceID="odsDepartments" Width="195px" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
                    <asp:ObjectDataSource ID="odsDepartments"  runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                        <SelectParameters>
                            <asp:Parameter Type="String" Name="Type" DefaultValue="Department" />
                            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="1" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Badge #:
                </td>
                <td style="text-align: left">
                    <asp:TextBox runat="server" ID="txtBadge"></asp:TextBox>
                </td>                
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    &nbsp;
                </td>
                <td style="text-align: left">
                    <asp:Button ID="btnConfirm" runat="server" Text="Confirm Identity" />
                </td>
            </tr>
        </table>
    </div>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
