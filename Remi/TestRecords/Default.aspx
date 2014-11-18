<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="true"
    AutoEventWireup="false" Inherits="Remi.TestRecords_Default" Codebehind="Default.aspx.vb" %>

<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    
    <script type="text/javascript">
        $(document).ready(function() { //when the page has loaded
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

            $('table#ctl00_Content_grdTestRecords').columnFilters({ alternateRowClassNames: ['evenrow', 'oddrow'] });

        }); //document.ready
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>
       <asp:Label ID="lblPageTitle" runat="server" Text="Test Records"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <h3>
        View</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgSummaryView" runat="server" />
            <asp:LinkButton ID="lnkSummaryView" runat="Server" Text="Refresh" ToolTip="Click to refresh the page" />
        </li>
              <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
            <asp:HyperLink ID="hypBatchInfo" runat="Server" Text="Batch Info" ToolTip="Click to return to batch info" />
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/add.png" ID="imgAddTR" runat="server" enabled="false"/>
            <asp:HyperLink ID="hypAddTR" runat="Server" Text="Add New Record" ToolTip="Click to add a test record for this batch." enabled="false"/>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server">
    </asp:ToolkitScriptManager>
    <uc1:NotificationList ID="notMain" runat="server" />
    <asp:GridView ID="grdTestRecords" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" OnRowCommand="grdTestRecords_RowCommand"
        EnableViewState="true" cssclass="FilterableTable" EmptyDataText="There are no test records available for the given criteria.">
        <RowStyle CssClass="evenrow" />
        <Columns>
            <asp:BoundField DataField="ID" HeaderText="ID" SortExpression="ID" Visible="False" />
            <asp:TemplateField HeaderText="Request" SortExpression="QRANumber">
                <ItemTemplate>
                    <asp:HyperLink ID="hypQRANumber" runat="server" Text='<%# Eval("QRANumber") %>' NavigateUrl='<%# Eval("BatchInfoLink") %>'
                        ToolTip="Click to view the information for this batch." EnableViewState="False"></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Unit #" SortExpression="BatchUnitNumber">
                <ItemTemplate>
                    <asp:HyperLink ID="hypUnitNumber" runat="server" Text='<%# Eval("BatchUnitNumber") %>'
                        NavigateUrl='<%# Eval("UnitInfoLink") %>' ToolTip="Click to view the information for this unit."
                        EnableViewState="False"></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Results" SortExpression="">
                <ItemTemplate>
                    <asp:HyperLink ID="hypRQResult" runat="server" Text='Measurements' Visible="false" ToolTip="Click to view the measurements for this unit." EnableViewState="False"></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="TestName" HeaderText="Test" SortExpression="TestName" />
            <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" SortExpression="TestStageName" />
            <asp:TemplateField HeaderText="Status" SortExpression="Status">
                <ItemTemplate>
                    <asp:Label ID="lblStatus" runat="server" Text='<%# Eval("Status").tostring %>' EnableViewState="False"></asp:Label>
                    <br />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="Comments" HeaderText="Comments" SortExpression="Comments" />
            <asp:BoundField DataField="TotalTestTimeInHours" HeaderText="Total TT (h)" ReadOnly="True" SortExpression="TotalTestTimeInHours" DataFormatString="{0:F2}" />
            <asp:BoundField DataField="NumberOfTests" HeaderText="# Scans" SortExpression="NumberOfTests" />
            <asp:BoundField DataField="CurrentRelabResultVersion" HeaderText="ReTests" SortExpression="CurrentRelabResultVersion" />
            <asp:TemplateField HeaderText="FA / RIT" SortExpression="FailDocLink">
                <ItemTemplate>
                    <asp:Literal  Mode="PassThrough" ID="litFailDocLink" runat="server" Text='<%# Eval("FailDocLiteralHTMLLinkList") %>'></asp:Literal>
                    <br />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Edit" SortExpression="editdetailslink">
                <ItemTemplate>
                    <asp:HyperLink ID="hypEditDetailsLink" runat="server" Text="Edit" NavigateUrl='<%# Eval("editdetailslink") %>' Enabled="false" ToolTip="Click to edit the status, FA & RIT for this test record." EnableViewState="False"></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="TestID" HeaderText="TestID" SortExpression="TestID" Visible="false" />
            <asp:BoundField DataField="TestStageID" HeaderText="TestStageID" SortExpression="TestStageID" Visible="false" />
            <asp:BoundField DataField="TestUnitID" HeaderText="TestUnitID" SortExpression="TestUnitID" Visible="false" />
            <asp:TemplateField HeaderText="Delete" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lnkDelete" runat="server" CommandArgument='<%# Eval("ID") %>' EnableViewState="true" onclientclick="return confirm('Are you sure you want to delete this Test Record?');" CommandName="DeleteItem" Enabled='false' Visible='false'>Delete</asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
        <AlternatingRowStyle CssClass="oddrow" />
    </asp:GridView>
    <asp:HiddenField ID="hdnQRANumber" runat="server" Value="No Value" />
    <asp:HiddenField ID="hdnProductGroup" runat="server" Value="No Value" />
    <asp:HiddenField ID="hdnTestName" runat="server" Value="-1" />
    <asp:HiddenField ID="hdnTestStageName" runat="server" Value="-1" />
    <asp:HiddenField ID="hdnTestUnitID" runat="server" Value="-1" />
    <asp:HiddenField ID="hdnJobName" runat="server" Value="-1" />
    <asp:HiddenField ID="hdnQRAID" runat="server" Value="-1" />
    <asp:HiddenField ID="hdnDepartmentID" runat="server" Value="-1" />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
