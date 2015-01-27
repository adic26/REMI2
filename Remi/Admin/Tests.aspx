<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" maintainscrollpositiononpostback="true" AutoEventWireup="false" Inherits="Remi.Admin_Tests" Codebehind="Tests.aspx.vb" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="NotificationList" tagprefix="uc1" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp2" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $('table#ctl00_Content_gvMain').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [5, 9, 10],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
    <style type="text/css">
        .style1
        {
            text-align: center;
        }
    </style>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Tests</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews"  runat="server">
        <h3>Admin Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:hyperlink ID="Hyperlink2" runat="Server" Text="Process Flow" navigateurl="~/Admin/Jobs.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image4" runat="server" />
                <asp:hyperlink ID="Hyperlink3" runat="Server" Text="Tracking Locs" navigateurl="~/Admin/trackinglocations.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image8" runat="server" />
                <asp:HyperLink ID="Hyperlink7" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image9" runat="server" />
                <asp:hyperlink ID="Hyperlink8" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="Image5" runat="server" />
                <asp:hyperlink ID="Hyperlink4" runat="Server" Text="Users" navigateurl="~/Admin/users.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image1" runat="server" />
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image6" runat="server" />
                <asp:HyperLink ID="Hyperlink6" runat="Server" Text="Results" NavigateUrl="~/Admin/Results.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="HyperLink9" runat="Server" Text="Menu" NavigateUrl="~/Admin/Menu.aspx" /></li>
        </ul>
        <h3>Tests</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgViewTests" runat="server" />
                <asp:LinkButton ID="lnkViewTests" runat="Server" Text="Refresh" /></li>
            <li>
                <asp:Image ImageUrl="../Design/ruler_add.png" ID="imgAddTest" runat="server" />
                <asp:LinkButton ID="lnkAddTest" runat="Server" Text="Add New Test" />
            </li>
            <li>
                <asp:CheckBox runat="server" ID="chkArchived" Text="Archived" TextAlign="Right" AutoPostBack="true"  />
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddTestAction" runat="server" />
                <asp:LinkButton ID="lnkAddTestAction" runat="Server" Text="Confirm and Save" />
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" Runat="Server">
   <uc1:NotificationList ID="notMain" runat="server" />

    <asp:Panel ID="pnlViewAllTests" runat="server" Width="940px">
        <asp:DropDownList runat="server" ID="ddlTestType" AutoPostBack="true"></asp:DropDownList>
        <asp:GridView ID="gvMain" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" DataSourceID="odsTests" CssClass="FilterableTable" 
            HorizontalAlign="Left" onrowcommand="gvMain_RowCommand" EmptyDataText="There are no tests in remi.">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" 
                    ReadOnly="True" SortExpression="ID" Visible="False" />
                <asp:BoundField DataField="Name" HeaderText="Name" SortExpression="Name"  ReadOnly="true"/>
                <asp:TemplateField HeaderText="Duration" SortExpression="Duration"  >
                    <ItemTemplate>
                        <asp:Label ID="Label3" runat="server" 
                            Text='<%# REMI.BusinessEntities.Helpers.durationformat(Eval("Duration")) %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="ResultIsTimeBased" HeaderText="Time Based" 
                    SortExpression="ResultIsTimeBased" readonly ="true"/>
                <asp:TemplateField HeaderText="Test Type" SortExpression="TestType"  >
                    <ItemTemplate>
                        <asp:Label ID="lblType" runat="server" Text='<%# Eval("TestType").tostring %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Required Test StationType" 
                    SortExpression="TestStationType">
                    <ItemTemplate>
                        <asp:BulletedList  ID="bltTLTypes" runat="server" DataSource='<%# Eval("TrackingLocationTypes") %>'  DataTextField="Name" DataValueField="ID">
                        </asp:BulletedList>
                    </ItemTemplate>                
                </asp:TemplateField>
                <asp:TemplateField HeaderText="WI Location" 
                    SortExpression="WorkInstructionLocation">
                    <ItemTemplate>
                        <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("WorkInstructionLocation") %>' Text="View WI" Visible='<%# Not(String.isnullorempty(Eval("WorkInstructionLocation"))) %>'></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Test Stage" SortExpression="TestStage" >
                    <ItemTemplate>
                        <asp:Label ID="lblTestStage" runat="server" Text='<%# Eval("TestStage") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Job" SortExpression="Job">
                    <ItemTemplate>
                        <asp:Label ID="lblJobName" runat="server" Text='<%# Eval("JobName") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Owner" SortExpression="Owner">
                    <ItemTemplate>
                        <asp:Label ID="lblOwner" runat="server" Text='<%# Eval("Owner") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Trainee" SortExpression="Trainee">
                    <ItemTemplate>
                        <asp:Label ID="lblTrainee" runat="server" Text='<%# Eval("Trainee") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Degradation Calc" SortExpression="DegradationVal">
                    <ItemTemplate>
                        <asp:Label ID="lblDegradationVal" runat="server" Text='<%# Eval("Degradation")%>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server" CommandArgument='<%# Eval("ID") %>' Commandname="EditRow" Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>'>Edit</asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkDelete" runat="server" CausesValidation="False" CommandName="DeleteItem" CommandArgument='<%# Eval("ID") %>' Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>' Visible='<%# Eval("CanDelete") %>' 
                            onclientclick="return confirm('Are you sure you want to delete this Test?');" Text="Delete"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView> 
        <asp:ObjectDataSource ID="odsTests" runat="server" 
            SelectMethod="GetEditableTests" TypeName="REMI.Bll.TestManager" 
            DeleteMethod="DeleteTest" DataObjectTypeName="REMI.BusinessEntities.Test" 
            InsertMethod="SaveTest" OldValuesParameterFormatString="original_{0}">
            <DeleteParameters>
                <asp:Parameter Name="ID" Type="Int32" />
            </DeleteParameters>
            <SelectParameters>
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkArchived" DefaultValue="false" Name="includeArchived" PropertyName="Checked" Type="Boolean" />
                <asp:ControlParameter ControlID="ddlTestType" Name="testType" PropertyName="SelectedValue" Type="String" />
            </SelectParameters>
        </asp:ObjectDataSource>
    </asp:Panel>
    
    <asp:Panel ID="pnlAddEditTest" runat="server" Visible="false">
    <h2>
        <asp:Label ID="lblAddEditTitle" runat="server" Text="Add a new Test"></asp:Label></h2>
        <table style="width:86%;" border="0">
            <tr>
                <td class="HorizTableFirstcolumn">Name:</td>
                <td>
                    <asp:TextBox ID="txtName" runat="server" Width="143px"></asp:TextBox>
                    <asp:HiddenField ID="hdnEditID" runat="server" Value="0" />
                    <asp:Label ID="lblName" runat="server" Text=""></asp:Label>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Type:</td>
                <td>
                    <asp:RadioButton ID="rbnParametric" runat="server" Checked="True" GroupName="TestType" Text="Parametric" />
                    <br />
                    <asp:RadioButton ID="rbnIncoming" runat="server" GroupName="TestType" Text="Incoming Eval" />
                    <br />
                    <asp:RadioButton ID="rbnNonTestingTask" runat="server" GroupName="TestType" Text="NonTestingTask" />
                    <br />
                    <asp:RadioButton ID="rbnEnv" runat="server" GroupName="TestType" Text="EnvironmentalStress" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Duration (hrs):</td>
                <td>&nbsp;<asp:TextBox ID="txtHours" runat="server" Width="60px">0</asp:TextBox>&nbsp;</td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Result Is Time Based:</td>
                <td>
                    <asp:CheckBox ID="chkResultIsTimeBased" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Work Instruction Address:</td>
                <td>
                    <asp:TextBox ID="txtWorkInstructionLocation" runat="server" Width="889px" Rows="3"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Owner:</td>
                <td>
                    <asp2:AutoCompleteExtender runat="server" ID="aceTxtOwner" TargetControlID="txtOwner"
                        ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20">
                    </asp2:AutoCompleteExtender>
                    <asp:TextBox runat="server" ID="txtOwner"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Trainee:</td>
                <td>
                    <asp2:AutoCompleteExtender runat="server" ID="aceTxtTrainee" TargetControlID="txtTrainee"
                        ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20">
                    </asp2:AutoCompleteExtender>
                    <asp:TextBox runat="server" ID="txtTrainee"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Degradation Calc:</td>
                <td>
                    <asp:TextBox runat="server" ID="txtDegradationVal"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Usable Test Fixtures:</td>
                <td>
                    <asp:ObjectDataSource ID="odsTestStationTypes" runat="server" 
                        SelectMethod="GetTrackingLocationTypes" TypeName="REMI.Bll.TrackingLocationManager" OldValuesParameterFormatString="original_{0}">
                    </asp:ObjectDataSource>                       
                    <table style="width:100%; height: 78px;">
                        <tr>
                            <td>
                                <asp:ListBox ID="lstAllTLTypes" runat="server" Width="360px" Height="400px" 
                                    DataSourceID="odsTestStationTypes" DataTextField="Name" DataValueField="ID"></asp:ListBox>
                            </td>
                            <td class="style1">
                                <asp:Button ID="btnAddTLType" runat="server" Text="Add ->" />
                                <br />
                                <asp:Button ID="btnRemoveTLType" runat="server" Text="<- Remove" />
                            </td>
                            <td>
                                <asp:ListBox ID="lstAddedTLTypes" runat="server" Width="360px" Height="400px" DataTextField="Name" DataValueField="ID" ></asp:ListBox>
                            </td>
                        </tr>
                    </table>                       
                </td>
            </tr>
        </table>    
    <br />
    <br />
    </asp:Panel>
    </asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
    <h2>Instructions</h2><p>Here you can add edit or delete the Tests in the system.</p>
</asp:Content>