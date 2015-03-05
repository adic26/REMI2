<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Admin_Users" Codebehind="Users.aspx.vb" %>

<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
<script type="text/javascript">
    function gvrowtoggle(row, clientid) {
        try {

            if (document.getElementById(clientid).className !== 'hidden') //if the row is not currently hidden 
            {
                document.getElementById(clientid).className = 'hidden'; //hide the row
            }
            else {
                document.getElementById(clientid).className = ''; //set the css class of the row to default 
            }
        }
        catch (ex) { alert(ex) }
    }

    function EnableDisableCheckbox_Click(ddl, chk, userName, lbl) {
        try {

            if (document.getElementById(chk).checked !== true) //if the row is not currently hidden 
            {
                document.getElementById(ddl).disabled = true; //hide the row
                document.getElementById(lbl).innerHTML = '';
            }
            else 
            {
                document.getElementById(ddl).disabled = false; //set the css class of the row to default
                document.getElementById(lbl).innerHTML = userName;
            }
        }
        catch (ex) { alert(ex) }
    }
</script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Users</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" visible="true" runat="server">
        <h3>Admin Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:hyperlink ID="Hyperlink2" runat="Server" Text="Process Flow" navigateurl="~/Admin/Jobs.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image4" runat="server" />
                <asp:hyperlink ID="Hyperlink3" runat="Server" Text="Tracking Locs" navigateurl="~/Admin/trackinglocations.aspx"/></li>  
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image5" runat="server" />
                <asp:HyperLink ID="Hyperlink7" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:hyperlink ID="Hyperlink8" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>                         
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink4" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
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
        <h3>Users</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="imgViewAllUsers" runat="server" />
                <asp:LinkButton ID="lnkViewAllUsers" runat="Server" Text="View All Users" /></li>
                <li>
                    <asp:Image ID="imgAddNewUser" runat="server" ImageUrl="../Design/Icons/png/24x24/add_user.png" />
                    <asp:LinkButton ID="lnkAddNewUser" runat="Server" Text="Add New User" />
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddUserAction" runat="server" />
                <asp:LinkButton ID="lnkAddUserAction" runat="Server" Text="Confirm and Save" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
            </li>
        </ul>
    </asp:Panel>
    <h3>Filter</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgTestCenterView" runat="server" />
            <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True" DataTextField="LookupType" DataValueField="LookupID"
                AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataSourceID="odsTestCenters">
            </asp:DropDownList>
            <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                <SelectParameters>
                    <asp:Parameter Type="String" Name="Type" DefaultValue="TestCenter" />
                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                    <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                    <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                    <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                    <asp:Parameter Type="Boolean" Name="ShowAdminSelected" DefaultValue="false" />
                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                    <asp:Parameter Type="Boolean" Name="showArchived" DefaultValue="false" />
                </SelectParameters>
            </asp:ObjectDataSource>
        </li>
        <li>
            <asp:CheckBox runat="server" ID="chkArchived" Text="Archived" TextAlign="Left" AutoPostBack="true" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <h2>
        <asp:Label ID="lblHeaderText" runat="server"></asp:Label>
    </h2>
    <asp:Panel ID="pnlViewAllUsers" runat="server">
        <asp:GridView ID="gvwUsers" runat="server" AutoGenerateColumns="False" DataKeyNames="LDAPName" EmptyDataText="There are no users in the system." OnRowCommand="gvwUsers_RowCommand">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" SortExpression="ID" Visible="False" />
                <asp:BoundField DataField="LDAPName" HeaderText="Login" readonly="true"/>
                <asp:BoundField DataField="BadgeNumber" HeaderText="Badge" readonly="true" SortExpression="BadgeNumber" />
                <asp:TemplateField HeaderText="Details">
                    <ItemTemplate>
                        <asp:BulletedList runat="server" ID="bltDetails" DataSource='<%# Eval("DetailsNames") %>'></asp:BulletedList>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Roles">
                    <ItemTemplate>
                        <asp:BulletedList ID="bltRoles" runat="server" DataSource='<%# Eval("RolesList") %>' >
                        </asp:BulletedList>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Training" SortExpression="TrainingOption" ItemStyle-CssClass="removeStyle">
                    <ItemTemplate>
                        <asp:Image runat="server" ID="btnTraining" ImageUrl="/Design/Icons/png/16x16/link.png" />
                        <asp:Panel runat="server" ID="pnlTraining" CssClass="hidden">
                            <asp:BulletedList ID="blTraining" runat="server" DataSource='<%# Eval("TrainingNames") %>' >
                            </asp:BulletedList>
                        </asp:Panel>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Projects" SortExpression="ProductGroupName">
                    <ItemTemplate>
                        <asp:BulletedList ID="blProductGroups" runat="server" DataSource='<%# Eval("ProductGroupsNames") %>' >
                        </asp:BulletedList>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="IsActive" HeaderText="Active" readonly="true" SortExpression="IsActive" />
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server" CommandArgument='<%# Eval("ID") %>' Commandname="EditRow">Edit</asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkDelete" runat="server" Visible='<%# Eval("CanDelete") %>'
                            CommandName="Deleteitem" CommandArgument='<%# Eval("ID") %>' onclientclick="return confirm('Are you sure you want to delete this User?');" Text="Delete"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
    </asp:Panel>
    <asp:Panel ID="pnlAddNewUser" runat="server" Visible="False">
        <table >
            <tr>
                <td class="HorizTableFirstcolumn">
                    Name:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtName" runat="server" Width="174px"></asp:TextBox>
                    <asp:Label ID="lblUserName" runat="server" Text="Label" Visible="False"></asp:Label>
                    <asp:HiddenField ID="hdnUserName" runat="server" />
                    <asp:HiddenField ID="hdnUserID" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Active:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkIsActive" runat="server" />
                </td>                
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">ByPass Product Restriction:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkByPassProduct" runat="server" />
                </td>                
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Is RIMNET User:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkWA" runat="server" Checked="true" />
                </td>   
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Badge Number:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtBadgeNumber" runat="server" Width="161px"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Default page:</td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlDefaultPage" CausesValidation="true" runat="server" Width="195px" DataTextField="Name" DataValueField="Url"></asp:DropDownList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Test Center:</td>
                <td class="HorizTableSecondColumn">                                        
                    <asp:GridView runat="server" ID="grdTestCenter" EmptyDataText="No Test Centers" AutoGenerateColumns="false">
                        <Columns>
                            <asp:TemplateField HeaderText="Test Center" SortExpression="">
                                <ItemTemplate>
                                    <asp:Label runat="server" ID="lblName" Text='<%# DataBinder.Eval(Container.DataItem, "LookupType") %>'></asp:Label>
                                </ItemTemplate>                     
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Access" SortExpression="">
                                <ItemTemplate>
                                    <asp:HiddenField ID="hdnLookupID" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "LookupID") %>' />
                                    <asp:CheckBox runat="server" ID="chkAccess" Checked="false" />
                                </ItemTemplate>                     
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Default" SortExpression="">
                                <ItemTemplate>
                                    <asp:CheckBox runat="server" ID="chkDefault" Checked="false" />
                                </ItemTemplate>                     
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Department:</td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView runat="server" ID="grdDepartments" EmptyDataText="No Departments" AutoGenerateColumns="false">
                        <Columns>
                            <asp:TemplateField HeaderText="Department" SortExpression="">
                                <ItemTemplate>
                                    <asp:Label runat="server" ID="lblName" Text='<%# DataBinder.Eval(Container.DataItem, "LookupType") %>'></asp:Label>
                                </ItemTemplate>                     
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Access" SortExpression="">
                                <ItemTemplate>
                                    <asp:HiddenField ID="hdnLookupID" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "LookupID") %>' />
                                    <asp:CheckBox runat="server" ID="chkAccess" Checked="false" />
                                </ItemTemplate>                     
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Default" SortExpression="">
                                <ItemTemplate>
                                    <asp:CheckBox runat="server" ID="chkDefault" Checked="false" />
                                </ItemTemplate>                     
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Request Access:</td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView runat="server" ID="gvRequestTypes" AutoGenerateColumns="false" EnableViewState="true" DataKeyNames="UserDetailsID,TypeID,RequestTypeAccessID">
                        <Columns>
                            <asp:BoundField DataField="RequestType" HeaderText="Request" readonly="true" SortExpression="RequestType" />
                            <asp:BoundField DataField="Department" HeaderText="Department" readonly="true" SortExpression="Department" />
                            <asp:TemplateField HeaderText="Admin">
                                <ItemTemplate>
                                    <asp:CheckBox runat="server" ID="chkIsAdmin" Checked='<%# DataBinder.Eval(Container.DataItem, "IsAdmin")%>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Projects:</td>
                <td class="Datagrid">
                    <asp:DataList ID="dlstProductGroups" runat="server" DataSourceID="odsProductGroups" ItemStyle-HorizontalAlign="left" ItemStyle-Wrap="false" RepeatColumns="5" ShowFooter="False" ShowHeader="False"  CssClass="Datagrid">
                        <ItemTemplate>
                            <asp:HiddenField ID="hdnProductID" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "ID") %>' />
                            <asp:CheckBox ID='chkProductGroup'  runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "ProductGroupName") %>' CssClass="HorizTableSecondColumn"/>
                        </ItemTemplate>
                        <ItemStyle HorizontalAlign="Left" Wrap="False" />
                    </asp:DataList>
                    <asp:ObjectDataSource ID="odsProductGroups" runat="server" SelectMethod="GetProductList" TypeName="REMI.Bll.ProductGroupManager" OldValuesParameterFormatString="{0}">
                        <SelectParameters>
                            <asp:Parameter DefaultValue="True" Name="ByPassProduct" Type="Boolean" />
                            <asp:Parameter DefaultValue="-1" Name="userID" Type="Int32" />
                            <asp:Parameter DefaultValue="False" Name="showArchived" Type="Boolean" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                    <br />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Roles:
                </td>
                <td class="Datagrid">
                    <asp:DataList ID="dlstRoles" runat="server"  
                        DataSourceID="odsRoles" ItemStyle-HorizontalAlign="left" ItemStyle-Wrap="false" 
                        RepeatColumns="5" ShowFooter="False" ShowHeader="False" CssClass="Datagrid"> 
                        <ItemTemplate>
                            <asp:CheckBox ID="chkRole" runat="server" Text="<%# Container.Dataitem %>" />
                        </ItemTemplate>
                        <ItemStyle HorizontalAlign="Left" Wrap="False" />
                    </asp:DataList>
                    <asp:ObjectDataSource ID="odsRoles" runat="server" SelectMethod="GetRoles" TypeName="REMI.Bll.UserManager"></asp:ObjectDataSource>
                </td>
            </tr>            
            <tr>
                <td class="HorizTableFirstcolumn">
                    Training:</td>
                <td class="Datagrid">
                    <asp:ObjectDataSource ID="odsTraining" runat="server" SelectMethod="GetTraining" TypeName="REMI.Bll.UserManager" OldValuesParameterFormatString="{0}">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="hdnUserID" Name="userID" DefaultValue=" " PropertyName="Value" Type="Int32" />
                            <asp:Parameter DefaultValue="0" Name="ShowTrainedOnly" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                    <asp:gridview ID="gvwTraining" runat="server" AutoGenerateColumns="false" DataSourceID="odsTraining" RowStyle-CssClass="center" DataKeyNames="LevelLookupID, ID">
                        <RowStyle CssClass="center" />
                        <Columns>
                            <asp:BoundField DataField="ID" HeaderText="ID" SortExpression="ID" Visible="false" ReadOnly="true" />
                            <asp:TemplateField HeaderText="Training Name" SortExpression="">
                                <ItemTemplate>
                                    <asp:HiddenField ID="hdnLookupID" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "LookupID") %>' />
                                    <asp:HiddenField ID="hdnDateAdded" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "DateAdded") %>' />
                                    <asp:Panel runat="server" ID="pnlTraining" Enabled='<%# Not(DataBinder.Eval(Container.DataItem, "IsTrained"))%>'>
                                        <asp:CheckBox ID="chkTraining" CausesValidation="False" ToolTip='<%# DataBinder.Eval(Container.DataItem, "DateAdded") %>' runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "TrainingOption") %>' CssClass="HorizTableSecondColumn" Checked='<%# DataBinder.Eval(Container.DataItem, "IsTrained")%>'/>
                                    </asp:Panel>
                                </ItemTemplate>                     
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Level" SortExpression="">
                                <ItemTemplate>
                                    <asp:DropDownList ID="ddlTrainingLevel" runat="server"></asp:DropDownList>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="DateAdded" HeaderText="Date Added" SortExpression="DateAdded" />
                            <asp:TemplateField HeaderText="Added By" SortExpression="">
                                <ItemTemplate>
                                    <asp:Label runat="server" ID="lblAddedBy" Text='<%# DataBinder.Eval(Container.DataItem, "UserAssigned") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Confirmed" SortExpression="">
                                <ItemTemplate>
                                    <asp:Label runat="server" ID="lblTrainingConfirm" Text='<%# DataBinder.Eval(Container.DataItem, "ConfirmDate") %>' Enabled='<%# DataBinder.Eval(Container.DataItem, "IsConfirmed")%>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:gridview>
                    <br />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Permissions:</td>
                <td>
                    <asp:GridView ID="gvwPermissions" runat="server" AutoGenerateColumns="False" 
                        DataSourceID="odsPermissions" RowStyle-CssClass="center" 
                        DataKeyNames="TrackingLocationTypeID">
                        <RowStyle CssClass="center" />
                        <Columns>
                           
                            <asp:BoundField DataField="TrackingLocationType" 
                                HeaderText="Location Type" SortExpression="TrackingLocationType" />
                            <asp:TemplateField  HeaderText="Basic Access" SortExpression="HasBasicAccess">
                                <ItemTemplate>
                                    <asp:CheckBox ID="chkHasBasicAccess" runat="server" 
                                        Checked='<%# Eval("HasBasicAccess") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Modified Test Access" 
                                SortExpression="HasModifiedAccess">
                                 <ItemTemplate>
                                    <asp:CheckBox ID="chkHasModifiedAccess" runat="server" 
                                        Checked='<%# Eval("HasModifiedAccess") %>' />
                                </ItemTemplate>
                                
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Calibration Access" 
                                SortExpression="HasCalibrationAccess">
                                  <ItemTemplate>
                                    <asp:CheckBox ID="chkHasCalibrationAccess" runat="server" 
                                        Checked='<%# Eval("HasCalibrationAccess") %>' />
                                </ItemTemplate>
                               
                            </asp:TemplateField>
                            <asp:BoundField DataField="CurrentPermissions" HeaderText="CurrentPermissions" 
                                SortExpression="CurrentPermissions" Visible="False" />
                            <asp:BoundField DataField="TrackingLocationTypeID" 
                                HeaderText="TrackingLocationTypeID" SortExpression="TrackingLocationTypeID" 
                                Visible="False" />
                        </Columns>
                    </asp:GridView>
                    <asp:ObjectDataSource ID="odsPermissions" runat="server" 
                        OldValuesParameterFormatString="original_{0}" 
                        SelectMethod="GetUserPermissionList" 
                        TypeName="REMI.Bll.TrackingLocationManager">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="hdnUserName" Name="username" DefaultValue=" " 
                                PropertyName="Value" Type="String" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
        </table>
    </asp:Panel>
    <br />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>