<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ManageBatches_EditExceptions" Codebehind="EditExceptions.aspx.vb" %>
<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" Runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            //apply css to the table

            $(".FilterableTable >tbody tr td:contains('DNP')").removeClass().addClass("DNP")
            $(".FilterableTable >tbody tr td:contains('Complete')").removeClass().addClass("Pass")
            $(".FilterableTable >tbody tr td:contains('CompleteFail')").removeClass().addClass("Fail")
            $(".FilterableTable >tbody tr td:contains('CompleteKnownFailure')").removeClass().addClass("KnownIssue")
            $(".FilterableTable >tbody tr td:contains('WaitingForResult')").removeClass().addClass("WaitingForResult")
            $(".FilterableTable >tbody tr td:contains('NeedsRetest')").removeClass().addClass("NeedsRetest")
            $(".FilterableTable >tbody tr td:contains('FARaised')").removeClass().addClass("FARaised")
            $(".FilterableTable >tbody tr td:contains('FARequired')").removeClass().addClass("RequiresFA")
            $(".FilterableTable >tbody tr td:contains('InProgress')").removeClass().addClass("WaitingForResult")
            $(".FilterableTable >tbody tr td:contains('Quarantined')").removeClass().addClass("Quarantined")

            $('table#ctl00_Content_gvwTestExceptions').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [10,11],
                alternateRowClassNames: ['evenrow', 'oddrow'] 
            });
        }); //document.ready
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" Runat="Server">
<h1>  <asp:Label ID="lblQRANumber" runat="server"></asp:Label></h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh"
                    runat="server" />
                <asp:HyperLink ID="hypRefresh" runat="server" ToolTip="Click to refresh the current page">Refresh</asp:HyperLink>
            </li>
              <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1"
                    runat="server" />
                <asp:HyperLink ID="hypBatchInfo" runat="server" ToolTip="Click to go back to the batch information page">Batch Info</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/accept.png" ID="imgSaveExceptions"
                    runat="server" />
                <asp:LinkButton ID="lkbSaveExceptions" runat="Server" Text="Save Exceptions"  ToolTip="Click to save the current exceptions"/></li><li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" tooltip="Click to cancel any changes made to the current exceptions"  runat="server" />
                    <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" Runat="Server">
      <uc1:Notifications ID="notMain" runat="server" />     
        <font size="1"><br />Use "*" in filter box as wildcard</font>
        <asp:GridView ID="gvwTestExceptions" runat="server" CssClass="FilterableTable" OnRowDataBound="gvwTestExceptions_OnRowDataBound" AutoGenerateColumns="False" AllowPaging="true" PageSize="100" DataKeyNames="ID" EmptyDataText="No Exception Data Available" DataSourceID="odsExceptions" EnableViewState="True">
            <Columns>
                <asp:BoundField DataField="TestCenter" HeaderText="TestCenter" />
                <asp:BoundField DataField="ProductGroup" HeaderText="ProductGroup" />
                <asp:BoundField DataField="ProductType" HeaderText="Product Type" />
                <asp:BoundField DataField="AccessoryGroupName" HeaderText="Accessory Group Name" />
                <asp:BoundField DataField="ReasonForRequest" HeaderText="ReasonForRequest" />
                <asp:BoundField DataField="ID" HeaderText="ID" Visible="False" />
                <asp:BoundField DataField="QRAnumber" HeaderText="Request" />
                <asp:BoundField DataField="UnitNumber" HeaderText="Unit Number" />
                <asp:BoundField DataField="JobName" HeaderText="Job" />
                <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" />
                <asp:BoundField DataField="TestName" HeaderText="Test" />
                <asp:TemplateField HeaderText=""> 
                    <HeaderTemplate>
                        <asp:Button ID="btnDeleteAll" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure you want to delete these Exception(s)?');" OnClick="btnDeleteAllChecked_Click" />
                    </HeaderTemplate> 
                    <ItemTemplate>   
                       <asp:CheckBox ID="chk1" runat="server" />  
                  </ItemTemplate>  
                </asp:TemplateField>
                <asp:TemplateField ShowHeader="False">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkDelete" runat="server" CausesValidation="False" 
                            CommandArgument='<%# Eval("ID") %>' CommandName="DeleteItem" 
                            OnClientClick="return confirm('Are you sure you want to delete this Exception?');" 
                            Text="Delete"></asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        <asp:ObjectDataSource ID="odsExceptions" runat="server" 
         DeleteMethod="DeleteException" 
         SelectMethod="GetExceptionsForBatch" TypeName="REMI.Bll.ExceptionManager">
            <DeleteParameters>
                <asp:Parameter Name="ID" Type="Int32" />
            </DeleteParameters>
            <SelectParameters>
                <asp:ControlParameter ControlID="hdnQRANumber" Name="qraNumber" PropertyName="Value" Type="String" />
            </SelectParameters>
        </asp:ObjectDataSource>
        <br /><h2>Add New Exception</h2>
        <table border="0" cellpadding="5" cellspacing="5" class="RemoveBorder">
            <tr class="RemoveBorder">
                <td style="text-align:left;font-weight:bold;vertical-align:top;">Unit:</td>
                <td style="text-align:left;">
                    <div style="width: 500px; height: 50px; overflow: auto;text-align:left">
                        <asp:CheckBoxList ID="cblUnit" runat="server" TextAlign="Left" AppendDataBoundItems="true" RepeatDirection="Horizontal"></asp:CheckBoxList>
                    </div>
                </td>
            </tr>
            <tr class="RemoveBorder">
                <td style="text-align:left;font-weight:bold;vertical-align:top;">Test Stage:</td>
                <td style="text-align:left;"><asp:DropDownList ID="ddlTestStageSelection" runat="server" AutoPostBack="True" Width="265px" AppendDataBoundItems="True" DataTextField="TestStageName" DataValueField="TestStageID"></asp:DropDownList></td>
            </tr>
            <tr class="RemoveBorder">
                <td style="text-align:left;font-weight:bold;vertical-align:top;">Test:</td>
                <td style="text-align:left;"><asp:DropDownList ID="ddlTests" runat="server" DataTextField="TestName" DataValueField="TestID" Width="343px" AppendDataBoundItems="True"></asp:DropDownList></td>
            </tr>
            <tr class="RemoveBorder">
                <td style="text-align:left;font-weight:bold;vertical-align:top;">Product Type:</td>
                <td style="text-align:left;"><asp:Label ID="lblProductType" runat="server" /></td>
            </tr>
            <tr class="RemoveBorder">
                <td style="text-align:left;font-weight:bold;vertical-align:top;">Accessory Group:</td>
                <td style="text-align:left;"><asp:Label ID="lblAccessoryGroup" runat="server" /></td>
            </tr>
        </table>
        <asp:HiddenField ID="hdnQRANumber" runat="server" />
        <asp:HiddenField ID="hdnJobName" runat="server" />
        <br />


</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" Runat="Server">
</asp:Content>

