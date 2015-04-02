<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.BadgeAccess_Default" CodeBehind="default.aspx.vb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server">
    <script src="../Design/scripts/jQuery/jquery-1.8.3.js" type="text/javascript"></script>
    <script src="../Design/scripts/WaterMark/WaterMark.min.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $("[id*=txtUserName], [id*=txtPassword], [id*=txtNewUserName], [id*=txtNewBadge], [id*=txtNewPassword]").WaterMark();
        });

    </script>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    
    <div id="centering">
        <div class="login">
            <asp:MultiView runat="server" ID="mvLogin" ActiveViewIndex="0">
                <asp:View runat="server" ID="vLogin">
                    <asp:Table runat="server" ID="tblLogin" HorizontalAlign="Center">
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:Label runat="server" Text="Welcome back, please log in" ID="lblReturn" CssClass="loginReturnTxt"></asp:Label><br /><br />
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtUserName" Width="200px" CssClass="loginTextBox" ToolTip="User"></asp:TextBox>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtPassword" TextMode="Password" CausesValidation="true" Width="200px" CssClass="loginTextBox" ToolTip="Password"></asp:TextBox>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <b>OR</b>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtBadge" Width="200px" CssClass="loginTextBox" ToolTip="Badge"></asp:TextBox>
                                <br /><asp:CompareValidator runat="server" ID="cvBadge" ValidationGroup="Return" ControlToValidate="txtBadge" Display="Static" ErrorMessage="Must Be Numeric" Operator="DataTypeCheck" Type="Integer"></asp:CompareValidator>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                    <asp:Button runat="server" ID="btnReturn" Text="Log In" ValidationGroup="Return" CssClass="loginBtnReturn" OnClick="btnReturn_Click" />
                            </asp:TableCell>
                        </asp:TableRow>
                    </asp:Table>
                </asp:View>
                <asp:View runat="server" ID="vCreate">
                    <asp:Table runat="server" ID="tblCreate" HorizontalAlign="Center">
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:Label runat="server" ID="lblNewUser" Text="You Are A New User<br/>Please Create Your Account" CssClass="loginReturnTxt"></asp:Label><br />
                                <asp:RequiredFieldValidator runat="server" ID="rfvUserName" ValidationGroup="New" ControlToValidate="txtNewUserName" Display="Static" EnableViewState="true" ErrorMessage="User Must Be Specific"></asp:RequiredFieldValidator><br />
                                <asp:RequiredFieldValidator runat="server" ID="rfvPassword" ValidationGroup="New" ControlToValidate="txtNewPassword" Display="Static" EnableViewState="true" ErrorMessage="Password Must Be Specific"></asp:RequiredFieldValidator><br />
                                <asp:CompareValidator runat="server" ID="cpNewBadge" ValidationGroup="New" ControlToValidate="txtNewBadge" Display="Static" ErrorMessage="Must Be Numeric" Operator="DataTypeCheck" Type="Integer"></asp:CompareValidator>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtNewUserName" Width="200px" CssClass="loginTextBox" ToolTip="User"></asp:TextBox>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtNewPassword" TextMode="Password" CausesValidation="true" Width="200px" CssClass="loginTextBox" ToolTip="Password"></asp:TextBox>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:TextBox runat="server" ID="txtNewBadge" Width="200px" CssClass="loginTextBox" ToolTip="Badge"></asp:TextBox>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:DropDownList ID="ddlGeoLoc" runat="server" DataSourceID="odsTestCentres" Width="200px" CssClass="loginTextBox"
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
                                        <asp:Parameter Type="Boolean" Name="ShowAdminSelected" DefaultValue="false" />
                                        <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="1" />
                                        <asp:Parameter Type="Boolean" Name="showArchived" DefaultValue="false" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:DropDownList ID="ddlDepartments" runat="server" AutoPostBack="true" DataSourceID="odsDepartments" DataTextField="LookupType" DataValueField="LookupID" Width="200px" CssClass="loginTextBox"></asp:DropDownList>
                                <asp:ObjectDataSource ID="odsDepartments"  runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                                    <SelectParameters>
                                        <asp:Parameter Type="String" Name="Type" DefaultValue="Department" />
                                        <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                                        <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                                        <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                                        <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                                        <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                                        <asp:Parameter Type="Boolean" Name="ShowAdminSelected" DefaultValue="false" />
                                        <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="1" />
                                        <asp:Parameter Type="Boolean" Name="showArchived" DefaultValue="false" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:DropDownList ID="ddlDefaultPage" CausesValidation="true" DataSourceID="odsDefaultPage" runat="server" DataTextField="Name" DataValueField="Url" Width="200px" CssClass="loginTextBox"></asp:DropDownList>
                                <asp:ObjectDataSource ID="odsDefaultPage" runat="server" SelectMethod="GetMenuAccessByDepartment" TypeName="Remi.Bll.SecurityManager">
                                    <SelectParameters>
                                        <asp:Parameter Type="String" Name="pageName" DefaultValue="" />
                                        <asp:ControlParameter ControlID="ddlDepartments" Name="departmentID" PropertyName="SelectedValue" Type="String" />
                                        <asp:Parameter Type="Boolean" Name="RemoveFirst" DefaultValue="true" />
                                    </SelectParameters>
                                </asp:ObjectDataSource>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow>
                            <asp:TableCell CssClass="loginCell">
                                <asp:Button runat="server" ID="btnNewUser" Text="Log In" ValidationGroup="New" CssClass="loginBtnReturn" OnClick="btnNewUser_Click" />
                            </asp:TableCell>
                        </asp:TableRow>
                    </asp:Table>
                </asp:View>
            </asp:MultiView>
            <asp:Button runat="server" ID="btnLogin" Text="Returning User" CssClass="loginSwitchBtn" OnClick="btnLogin_Click" Visible="false" />
            <asp:Button runat="server" ID="btnCreate" Text="Create Account" CssClass="loginSwitchBtn" OnClick="btnCreate_Click" />
        </div>
    </div>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
