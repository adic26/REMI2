<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Admin_TestStages" Title="Jobs" Codebehind="Jobs.aspx.vb" ValidateRequest="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<%@ Register Src="../Controls/RequestSetup.ascx" TagName="RequestSetup" TagPrefix="rs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            $('table#ctl00_Content_acpTestStages_content_gvwMain').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [4,5],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Jobs</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuviews" runat="server">
        <h3>Admin Menu</h3>
        <ul>
             <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image4" runat="server" />
                <asp:HyperLink ID="Hyperlink3" runat="Server" Text="Tracking Locs" NavigateUrl="~/Admin/trackinglocations.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image7" runat="server" />
                <asp:HyperLink ID="Hyperlink5" runat="Server" Text="Tracking Types" NavigateUrl="~/Admin/trackinglocationtypes.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="Image8" runat="server" />
                <asp:hyperlink ID="Hyperlink7" runat="Server" Text="Tracking Tests" navigateurl="~/Admin/TrackingLocationTests.aspx"/></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/users.png" ID="Image5" runat="server" />
                <asp:HyperLink ID="Hyperlink4" runat="Server" Text="Users" NavigateUrl="~/Admin/users.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image2" runat="server" />
                <asp:HyperLink ID="Hyperlink1" runat="Server" Text="Lookups/Access" NavigateUrl="~/Admin/Lookups.aspx" /></li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/process.png" ID="Image3" runat="server" />
                <asp:HyperLink ID="Hyperlink2" runat="Server" Text="Security" NavigateUrl="~/Admin/Security.aspx" /></li>
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
        <h3>Test Stages</h3>
        <ul>         
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgViewParametricTestStages" runat="server" />
                <asp:LinkButton ID="lnkViewTestStages" runat="Server" Text="Refresh" /></li>
            <li>
                <asp:Image ImageUrl="../Design/ruler_add.png" ID="imgAddParametricTestStage" runat="server" />
                <asp:LinkButton ID="lnkAddTestStage" runat="Server" Text="Add Test Stage" /></li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgAddTestStageAction"
                    runat="server" />
                <asp:LinkButton ID="lnkAddTestStageAction" runat="Server" Text="Confirm and Save" /></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" runat="server" />
                    <asp:LinkButton ID="lnkCancelAction" runat="Server" Text="Cancel" /></li></ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" EnableViewState="False" />
    <asp:HiddenField ID="hdnJobID" runat="server" Value="" />
    <asp:Panel ID="pnlViewAllTestStages" runat="server" Wrap="False" Width="1000">
        <br />
        <table style="width: 65%;">
            <tr>
                <td class="HorizTableFirstcolumn">
                    Select Job:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlJobs" runat="server" DataSourceID="odsJobsList" Width="369px"
                        AutoPostBack="True">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsJobsList" runat="server" OldValuesParameterFormatString="original_{0}"
                        SelectMethod="GetJobList" TypeName="REMI.Bll.JobManager" DeleteMethod="DeleteJob">
                        <DeleteParameters>
                            <asp:Parameter Name="ID" Type="Int32" />
                        </DeleteParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr >
                <td class="HorizTableFirstcolumn">
                    Job WI Location:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtJobWILocation" runat="server" Width="507px" Rows="3"></asp:TextBox>
                </td>
            </tr>
            <tr >
                <td class="HorizTableFirstcolumn">
                    Procedure Location:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtProcedureLocation" runat="server" Width="507px" Rows="3"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Is Drop/Tumble Test:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkIsOperationsTest" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Is Environmental Test:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkIsTechOperationsTest" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Is Mechanical Test:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkIsMechanicalTest" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">No BSN(s):</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox runat="server" ID="chkNoBSN" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">Continue On Failures:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox runat="server" ID="chkContinueFailure" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Is Active:</td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox runat="server" ID="chkIsActive" />
                </td>
            </tr>
        </table>
        
        <div style="float:left">
            <asp:Accordion ID="accTestStages" runat="server" CssClass="Accordion" HeaderCssClass="AccordionHeader"
                ContentCssClass="AccordionContent" FadeTransitions="true" TransitionDuration="250"
                FramesPerSecond="40" RequireOpenedPane="false" AutoSize="None" Width="800px" SelectedIndex="1">
                <Panes>
                    <asp:AccordionPane ID="acpBatches" runat="server">
                        <Header>
                            <h2>Batches</h2>
                        </Header>
                        <Content>
                            <uc3:BatchSelectControl ID="bscJobs" runat="server" AllowPaging="False" AllowSorting="True" PageSize="50" EmptyDataText="There were no batches found for this selection." DisplayMode="JobDisplay" />
                        </Content>
                    </asp:AccordionPane>
                    <asp:AccordionPane ID="acpTestStages" runat="server">
                        <Header>
                            <h2><asp:Label ID="lblViewAllTitle" runat="server"></asp:Label></h2>
                        </Header>
                        <Content>
                            <asp:GridView ID="gvwMain" runat="server" AutoGenerateColumns="False" CssClass="FilterableTable" 
                                DataKeyNames="ID" OnRowCommand="gvMain_RowCommand" EnableViewState="True" 
                                EmptyDataText="There are no test stages set for this job." 
                                DataSourceID="odsTestStage">
                                <RowStyle CssClass="evenrow" />
                                <AlternatingRowStyle CssClass="oddrow" />
                                <Columns>
                                    <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" SortExpression="ID" Visible="False" />
                                    <asp:BoundField DataField="Name" HeaderText="Name" ReadOnly="true" SortExpression="Name" />
                                    <asp:BoundField DataField="TestStageType" HeaderText="Type" ReadOnly="true" SortExpression="TestStageType" />
                                    <asp:BoundField DataField="ProcessOrder" HeaderText="Order" ReadOnly="true" SortExpression="ProcessOrder" />
                                    <asp:TemplateField HeaderText="Duration" SortExpression="Duration">
                                        <ItemTemplate>
                                            <asp:Label ID="lblDuration" runat="server" Text='<%# Remi.BusinessEntities.Helpers.DurationFormat(Eval("Duration"))%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField>
                                        <ItemTemplate>
                                            <asp:LinkButton ID="lnkEdit" runat="server" CommandArgument='<%# Eval("ID") %>' CommandName="Edit" Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>'>Edit</asp:LinkButton>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField ShowHeader="False">
                                        <ItemTemplate>
                                            <asp:LinkButton ID="lnkDelete" runat="server"  
                                                CommandArgument='<%# Eval("ID") %>' onclientclick="return confirm('Are you sure you want to delete this Test Stage?');" CommandName="DeleteItem" Enabled='<%# Not Remi.Bll.UserManager.GetCurrentUser.HasAdminReadOnlyAuthority %>' Visible='<%# Eval("CanDelete") %>'>Delete</asp:LinkButton>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>        
       
                            <asp:ObjectDataSource ID="odsTestStage" runat="server" 
                                OldValuesParameterFormatString="original_{0}" 
                                SelectMethod="GetList" TypeName="REMI.Bll.TestStageManager">
                                <SelectParameters>
                                    <asp:Parameter Name="type" DefaultValue="0" Type="Int32" />
                                    <asp:ControlParameter ControlID="ddlJobs" Name="jobName" 
                                        PropertyName="SelectedValue" Type="String" />
                                </SelectParameters>
                            </asp:ObjectDataSource>
                        </Content>
                    </asp:AccordionPane>
                    <asp:AccordionPane runat="server" ID="acpSetup">
                        <Header>
                            <h2><asp:Label ID="lblSetup" runat="server" Text="Parametric Setup"></asp:Label></h2>
                        </Header>
                        <Content>
                            <rs:RequestSetup ID="JobSetup" runat="server" Visible="true" />
                        </Content>
                    </asp:AccordionPane>
                    <asp:AccordionPane runat="server" ID="acpEnvSetup">
                        <Header>
                            <h2><asp:Label ID="lblEnvSetup" runat="server" Text="Env Setup"></asp:Label></h2>
                        </Header>
                        <Content>
                            <rs:RequestSetup ID="JobEnvSetup" runat="server" Visible="true" />
                        </Content>
                    </asp:AccordionPane>
                    <asp:AccordionPane runat="server" ID="acpOrientation">
                        <Header>
                            <h2><asp:Label runat="server" ID="lblOrientation" Text="Orientations"></asp:Label></h2>
                        </Header>
                        <Content>
                            <asp:GridView runat="server" ShowFooter="true" ID="gdvOrientations" AutoGenerateColumns="false" EnableViewState="true" DataKeyNames="ID" AutoGenerateEditButton="true" OnRowEditing="gdvOrientations_OnRowEditing" OnRowCancelingEdit="gdvOrientations_OnRowCancelingEdit" OnRowUpdating="gdvOrientations_RowUpdating">
                                <Columns>
                                    <asp:BoundField DataField="ID" HeaderText="ID" ReadOnly="true" SortExpression="ID" />
                                    <asp:TemplateField HeaderText="Name">
                                        <ItemTemplate>
                                            <asp:Label runat="server" ID="lblName" Text='<%# Eval("Name")%>' Visible="true" />
                                            <asp:TextBox runat="server" ID="txtName" Text='<%# Eval("Name")%>' Visible="false" EnableViewState="true" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Product Type">
                                        <ItemTemplate>
                                            <asp:HiddenField runat="server" ID="hdnProductTypeID" Value='<%# Eval("ProductTypeID")%>' />
                                            <asp:Label runat="server" ID="lblProductType" Text='<%# Eval("ProductType")%>' Visible="true" />
                                            <asp:DropDownList runat="server" ID="ddlProductTypes" DataTextField="LookupType" DataValueField="LookupID" Visible="false"></asp:DropDownList>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:BoundField DataField="NumUnits" HeaderText="NumUnits" ReadOnly="true" SortExpression="NumUnits" />
                                    <asp:BoundField DataField="NumDrops" HeaderText="NumDrops" ReadOnly="true" SortExpression="NumDrops" />
                                    <asp:TemplateField HeaderText="Description">
                                        <ItemTemplate>
                                            <asp:Label runat="server" ID="lblDescription" Text='<%# Eval("Description")%>' Visible="true" />
                                            <asp:TextBox runat="server" ID="txtDescription" Text='<%# Eval("Description")%>' Visible="false" EnableViewState="true" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:BoundField DataField="CreatedDate" HeaderText="CreatedDate" ReadOnly="true" SortExpression="CreatedDate" />
                                    <asp:TemplateField HeaderText="Active" SortExpression="IsActive">
                                        <ItemTemplate>
                                            <asp:CheckBox runat="server" ID="chkActive" Checked='<%# Eval("IsActive")%>' Enabled="false" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Definition" SortExpression="">
                                        <ItemTemplate>
                                            <asp:LinkButton ID="lbtnXML" runat="server" ToolTip="Orientation Defintion" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="XML" CommandArgument='<%# Eval("Definition") %>'></asp:LinkButton>
                                        </ItemTemplate>
                                        <FooterStyle HorizontalAlign="Right" />
                                        <FooterTemplate>
                                         <asp:Button ID="btnAddOrientation" CssClass="buttonSmall" runat="server" Text="Add Orientation" OnClick="btnAddOrientation_Click" CausesValidation="true" />
                                        </FooterTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                            <br /><br />
                            <asp:Panel runat="server" ID="pnlOrientationAdd" Visible="false">
                                <table>
                                    <tr>
                                        <td class="HorizTableFirstcolumn">Name:</td>
                                        <td class="HorizTableSecondColumn"><asp:TextBox runat="server" ID="txtOrientationName" MaxLength="150" Width="250px" Rows="3" /></td>
                                    </tr>
                                    <tr>
                                        <td class="HorizTableFirstcolumn">Product Type:</td>
                                        <td class="HorizTableSecondColumn"><asp:DropDownList runat="server" ID="ddlPT" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList></td>
                                    </tr>
                                    <tr>
                                        <td class="HorizTableFirstcolumn">Description</td>
                                        <td class="HorizTableSecondColumn"><asp:TextBox runat="server" ID="txtOrientationDescription" MaxLength="250" Width="250px" Rows="3" /></td>
                                    </tr>
                                    <tr>
                                        <td class="HorizTableFirstcolumn">Definition</td>
                                        <td class="HorizTableSecondColumn"><asp:TextBox runat="server" ID="txtDefinition" TextMode="MultiLine" Rows="40" Columns="60"></asp:TextBox></td>
                                    </tr>
                                </table>
                            </asp:Panel>
                        </Content>
                    </asp:AccordionPane>
                    <asp:AccordionPane runat="server" ID="acpAccess">
                        <Header>
                            <h2><asp:Label runat="server" ID="lblAccess" Text="Access"></asp:Label></h2>
                        </Header>
                        <Content>
                            <asp:GridView runat="server" ID="grdAccess" ShowFooter="true" AutoGenerateColumns="false" EnableViewState="true" DataKeyNames="JobAccessID">
                                <Columns>
                                    <asp:BoundField DataField="JobAccessID" HeaderText="JobAccessID" ReadOnly="true" SortExpression="JobAccessID" />
                                    <asp:BoundField DataField="JobName" HeaderText="JobName" SortExpression="JobName" />
                                    <asp:TemplateField HeaderText="Department" SortExpression="">
                                        <ItemTemplate>
                                                <asp:Label runat="server" ID="lblDepartment" Text='<%# Eval("Department")%>' Visible="true" />
                                        </ItemTemplate>
                                        <FooterStyle HorizontalAlign="Right" />
                                        <FooterTemplate>
                                            <asp:DropDownList runat="server" ID="ddlDepartments" DataTextField="LookupType" DataSourceID="odsDepartments" DataValueField="LookupID"></asp:DropDownList>
                                        </FooterTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField ShowHeader="False">
                                        <ItemTemplate>
                                            <asp:LinkButton ID="lnkDelete" runat="server" CommandArgument='<%# Eval("JobAccessID")%>' onclientclick="return confirm('Are you sure you want to delete this department?');" CommandName="DeleteAccess" CausesValidation="false">Delete</asp:LinkButton>
                                        </ItemTemplate>
                                        <FooterTemplate>
                                            <asp:Button ID="btnAddAccess" CssClass="buttonSmall" runat="server" Text="Add Access" OnClick="btnAddAccess_Click" CausesValidation="true" />
                                        </FooterTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                            <asp:ObjectDataSource ID="odsDepartments" runat="server" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLookups" TypeName="REMI.Bll.LookupsManager">
                                <SelectParameters>
                                    <asp:Parameter Type="String" Name="Type" DefaultValue="Department" />
                                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                                    <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
                                    <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
                                    <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
                                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                                </SelectParameters>
                            </asp:ObjectDataSource>
                        </Content>
                    </asp:AccordionPane>
                </Panes>
            </asp:Accordion>
        </div>
    </asp:Panel>
    <asp:Panel ID="pnlAddEditTestStage" runat="server" Visible="False">
        <h2>
            <asp:Label ID="lblAddEditTitle" runat="server" Text="Add a new Test Stage"></asp:Label></h2>
        <table style="width: 25%;">
            <tr>
                <td class="HorizTableFirstcolumn">
                    Name:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtName" runat="server" Width="252px"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Type:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlTestStageType" runat="server" Width="178px" AutoPostBack="True">
                    </asp:DropDownList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Process Order:</td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtProcessOrder" runat="server"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Archive:
                </td>
               <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkArchived" runat="server" />
               </td>                
            </tr>
        </table>
        <asp:Panel runat="server" ID="pnlAddEditTest" Visible="False">
            <table style="width: 80%;">
                <tr>
                    <td class="HorizTableFirstcolumn">
                        Duration (h):
                    </td>
                    <td class="HorizTableSecondColumn">
                       <asp:TextBox ID="txtHours" runat="server" Width="60px">0</asp:TextBox>&nbsp;</td>
                </tr>
                           
                <tr>
                    <td class="HorizTableFirstcolumn">
                        Result Is Time Based:</td>
                    <td class="HorizTableSecondColumn">
                        <asp:CheckBox ID="chkResultIsTimeBased" runat="server" />
                    </td>
                </tr>
                <tr>
                    <td class="HorizTableFirstcolumn">
                        Work Instruction Address:
                    </td>
                    <td class="HorizTableSecondColumn">
                        <asp:TextBox ID="txtWorkInstructionLocation" runat="server" Width="424px" Rows="3"
                            TextMode="MultiLine"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td class="HorizTableFirstcolumn">
                        Applicable Test Fixtures:
                    </td>
                    <td>
                        <asp:ObjectDataSource ID="odsTestStationTypes" runat="server" SelectMethod="GetTrackingLocationTypes"
                            TypeName="REMI.Bll.TrackingLocationManager" OldValuesParameterFormatString="original_{0}">
                        </asp:ObjectDataSource>
                        
                        <table>
                                <tr>
                                    <td >
                                        <asp:ListBox ID="lstAllTLTypes" runat="server" Width="340px" Height="250px" 
                                            DataSourceID="odsTestStationTypes" DataTextField="Name" 
                                            DataValueField="ID"></asp:ListBox>
                                    </td>
                                    <td  >
                                        <asp:Button ID="btnAddTLType" runat="server" Text="Add ->" class="button"/>
                                        <br />
                                        <asp:Button ID="btnRemoveTLType" runat="server" Text="<- Remove" class="button"/>
                                    </td>
                                    <td>
                                        <asp:ListBox ID="lstAddedTLTypes" runat="server" Width="340px" Height="250px" DataTextField="Name" DataValueField="ID" ></asp:ListBox>
                                    </td>
                                </tr>
                            </table>
                    </td>
                </tr>
            </table>
        </asp:Panel>
        <asp:HiddenField ID="hdnTestStageID" runat="server" Value="0" />
        <asp:HiddenField ID="hdnTestID" runat="server" Value="0" />
    </asp:Panel>
    <br />
    <br />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
