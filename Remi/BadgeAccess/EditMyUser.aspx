<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.BadgeAccess_EditMyUser" Codebehind="EditMyUser.aspx.vb" EnableViewState="true" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">

<script type="text/javascript">
    function EnableDisableCheckbox_Click(ddl, chk) {
        try {

            if (document.getElementById(chk).checked == true) //if the row is not currently hidden 
            {
                document.getElementById(ddl).disabled = false; //hide the row
            }
            else 
            {
                document.getElementById(ddl).disabled = true; //set the css class of the row to default
            }
        }
        catch (ex) { alert(ex) }
    }
</script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <h3>Menu</h3>
    <ul>
        <li> <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" />
            <asp:HyperLink ID="hypRefresh" runat="server" NavigateUrl="./EditmyUser.aspx">Refresh</asp:HyperLink>
        </li>
    </ul>
    <h3>Filter</h3>
    <ul>
        <li>
            <asp:Button ID="btnSave" runat="server" CssClass="buttonSmall" Text="Save" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" Runat="Server">
    <h1>Manage User</h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
    <uc1:notifications ID="notMain" runat="server" />
    <asp:HiddenField ID="hdnUserID" runat="server" />
    <p>This page allows you to set your default test centre and default page. Please select your current location. This will filter the various location based pages for you and you will only see information that is applicable.</p>
    <div style="float:left;">
        <table>
            <tr>
                 <td class="HorizTableFirstcolumn">Test Centre:</td>
                 <td style="text-align:left;">
                     <asp:DropDownList runat="server" ID="ddlTestCenter" DataSourceID="odsTestCentres" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>

                     <asp:GridView runat="server" ID="grdTestCenter" EmptyDataText="No Test Centers">
                     </asp:GridView>

                    <asp:ObjectDataSource ID="odsTestCentres" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
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
                 </td>
             </tr>
            <tr>
                 <td class="HorizTableFirstcolumn">Department:</td>
                 <td style="text-align:left;">
                     <asp:DropDownList runat="server" ID="ddlDepartment" DataSourceID="odsDepartments" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
                     
                     <asp:GridView runat="server" ID="grdDepartments" EmptyDataText="No Departments">
                     </asp:GridView>

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
                 </td>
            </tr>
             <tr>
                 <td class="HorizTableFirstcolumn">Default Page:</td>
                 <td style="text-align:left;">
                    <asp:DropDownList ID="ddlDefaultPage" CausesValidation="true" runat="server" Width="195px" DataTextField="Name" DataValueField="Url"></asp:DropDownList>
                 </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Training</td>
                <td style="text-align:left;">
                    <a target="_blank" href="https://hwqaweb.rim.net/pls/trs/data_entry.main?formMode=EDIT&rqId=1535598">Procedure</a>
                    <asp:ObjectDataSource ID="odsTraining" runat="server" SelectMethod="GetTraining" TypeName="REMI.Bll.UserManager" OldValuesParameterFormatString="{0}">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="hdnUserID" Name="userID" DefaultValue=" " PropertyName="Value" Type="Int32" />
                            <asp:Parameter DefaultValue="1" Name="ShowTrainedOnly" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                    <asp:gridview ID="gvwTraining" runat="server" AutoGenerateColumns="false" DataSourceID="odsTraining" RowStyle-CssClass="center" DataKeyNames="ID">
                        <RowStyle CssClass="center" />
                        <Columns>
                            <asp:BoundField DataField="ID" HeaderText="ID" SortExpression="ID" Visible="false" ReadOnly="true" />
                            <asp:BoundField DataField="IsConfirmed" HeaderText="" SortExpression="IsConfirmed" Visible="true" HeaderStyle-CssClass="hidden" ControlStyle-CssClass="hidden" ItemStyle-CssClass="hidden" ReadOnly="true" />
                            <asp:TemplateField HeaderText="Training Name" SortExpression="">
                                <ItemTemplate>
                                    <asp:HiddenField ID="hdnLevel" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "LevelLookupID") %>' />
                                    <asp:Label runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "TrainingOption") %>' ID="lblTrainingName"></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="Level" HeaderText="Level" SortExpression="Level" />
                            <asp:BoundField DataField="UserAssigned" HeaderText="Added By" SortExpression="UserAssigned" />
                            <asp:BoundField DataField="DateAdded" HeaderText="Date Added" SortExpression="DateAdded" />
                            <asp:TemplateField HeaderText="Confirmed" SortExpression="">
                                <HeaderTemplate>
                                    <asp:Label ID="lblConfirm" runat="server" Text="Confirmed" CssClass="hidden" />
                                    <asp:Button ID="btnConfirmAll" runat="server" Text="Confirm All" OnClientClick="return confirm('Are you sure you want to confirm all training?');" OnClick="btnConfirmAllChecked_Click" />
                                </HeaderTemplate> 
                                <ItemTemplate>
                                    <asp:Panel runat="server" ID="pnlTraining" Enabled='<%# DataBinder.Eval(Container.DataItem, "IsTrained")%>'>
                                        <asp:CheckBox ID="chkTrainingConfirm" CausesValidation="False" ToolTip='<%# DataBinder.Eval(Container.DataItem, "ConfirmDate") %>' runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "ConfirmDate") %>' CssClass="HorizTableSecondColumn" Checked='<%# DataBinder.Eval(Container.DataItem, "IsConfirmed")%>'/>
                                        <asp:Label ID="lblTrainingConfirm" Text='<%# DataBinder.Eval(Container.DataItem, "ConfirmDate") %>' runat="server" CssClass="HorizTableSecondColumn" Enabled='<%# DataBinder.Eval(Container.DataItem, "IsConfirmed") %>' />
                                    </asp:Panel>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:gridview>
                </td>
            </tr>
        </table><br />     
    </div>
    <div>
        Update Training: <asp:DropDownList runat="server" ID="ddlTraining" AutoPostBack="true" DataTextField="TrainingOption" AppendDataBoundItems="true" DataValueField="LookupID"></asp:DropDownList>

        <asp:gridview ID="gvwTrainingLevels" runat="server" AutoGenerateColumns="false" RowStyle-CssClass="center" DataKeyNames="ID, UserID">
            <RowStyle CssClass="center" />
            <Columns>
                <asp:TemplateField HeaderText="Modify" SortExpression="">
                    <ItemTemplate>
                        <asp:CheckBox ID="chkModify" CausesValidation="False" runat="server" CssClass="HorizTableSecondColumn" />
                    </ItemTemplate>                     
                </asp:TemplateField>
                <asp:BoundField DataField="User" HeaderText="User" SortExpression="User" />
                <asp:TemplateField HeaderText="Level" SortExpression="Level">
                    <ItemTemplate>
                        <asp:HiddenField ID="hdnLevel" runat="server" Value='<%# DataBinder.Eval(Container.DataItem, "LevelID") %>' />
                        <asp:DropDownList runat="server" ID="ddlLevel" Enabled="false" DataTextField="LookupType" DataValueField="LookupID" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:gridview>
    </div>    
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>