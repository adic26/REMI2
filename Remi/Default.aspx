<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master"
    AutoEventWireup="false" Inherits="Remi._Default"  Codebehind="Default.aspx.vb" %>

<%@ Register Src="Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc3" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="./design/scripts/jquery.js"></script>
    <script src="Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            //apply css to the table

            $(".FilterableTable >tbody tr td:contains('DNP')").removeClass().addClass("DNP")
            $(".FilterableTable >tbody tr td:contains('N/A')").removeClass().addClass("DNP")
            $(".FilterableTable >tbody tr td a:contains('Complete')").parent().removeClass().addClass("Pass")
            $(".FilterableTable >tbody tr td a:contains('CompleteFail')").parent().removeClass().addClass("Fail")
            $(".FilterableTable >tbody tr td a:contains('CompleteKnownFailure')").parent().removeClass().addClass("KnownIssue")
            $(".FilterableTable >tbody tr td a:contains('WaitingForResult')").parent().removeClass().addClass("WaitingForResult")
            $(".FilterableTable >tbody tr td a:contains('NeedsRetest')").parent().removeClass().addClass("NeedsRetest")
            $(".FilterableTable >tbody tr td a:contains('FARaised')").parent().removeClass().addClass("FARaised")
            $(".FilterableTable >tbody tr td a:contains('FARequired')").parent().removeClass().addClass("RequiresFA")
            $(".FilterableTable >tbody tr td a:contains('InProgress')").parent().removeClass().addClass("WaitingForResult")
            $(".FilterableTable >tbody tr td a:contains('Quarantined')").parent().removeClass().addClass("Quarantined")

            $('table#ctl00_Content_gvwDailyList').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });

        function AddException(jobname, TestStageName, TestName, qranumber, unitcount) {
            $.ajax({
                type: "POST",
                url: "default.aspx/AddException",
                data: '{jobname: "' + jobname + '", teststagename: "' + TestStageName + '", testname: "' + TestName + '", qraNumber: "' + qranumber + '", unitcount: "' + unitcount + '" }',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    if (response.d == true) {
                        var check = document.getElementById(jobname + TestStageName + TestName + qranumber);
                        var lbl = document.getElementById("label" + jobname + TestStageName + TestName + qranumber);
                        $(check).hide();
                        $(lbl).text("DNP");
                    } else
                        alert("Add Exception Failed");
                },
                failure: function (response) {
                    alert("Add Exception Failed");
                }
            });
        }
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
  <script type="text/javascript" src='<%= ResolveUrl("~/Design/scripts/wz_tooltip.js")%>'></script>
    <h3>Filter</h3>
    <ul>
        <li>
            <asp:RadioButtonList Style="margin-left: 27px; padding: 0px; border: 0px;" ID="rbtnTestStageCompletion" runat="server" AutoPostBack="True" BorderWidth="0px" Width="128px" RepeatLayout="Flow">
                <asp:ListItem  Value="0">All</asp:ListItem>
                <asp:ListItem Selected="True" Value="1">In Progress</asp:ListItem>
                <asp:ListItem Value="2">Retests</asp:ListItem>
            </asp:RadioButtonList>
        </li>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/mobile_phone.png" ID="imgProductGroupView" runat="server" />
            <asp:DropDownList ID="ddlProductGroups" runat="server" AppendDataBoundItems="True" DataTextField="ProductGroupName" DataValueField="ID"
                AutoPostBack="True" Width="120px" ForeColor="#0033CC">
            </asp:DropDownList>
        </li>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/globe.png" ID="imgTestCenterView" runat="server" />
            <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True"
                AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataSourceID="odsTestCenters" DataTextField="LookupType" DataValueField="LookupID">
            </asp:DropDownList> 
            <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
                <SelectParameters>
                    <asp:Parameter Type="Int32" Name="Type" DefaultValue="4" />
                    <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
                    <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
                </SelectParameters>
            </asp:ObjectDataSource>
        </li>    
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/turquoise_button.png" ID="Image4" runat="server"
                EnableViewState="false" /><asp:CheckBox ID="chkGetTechOpsTests" 
                runat="server" Text="Get TechOps Tests" AutoPostBack="True" checked="true"/></li>
                 <li><asp:Image ImageUrl="./Design/Icons/png/24x24/turquoise_button.png" ID="Image3" runat="server"
                EnableViewState="false" /><asp:CheckBox ID="chkGetOpsTests" 
                runat="server" Text="Get DTATTA Tests" AutoPostBack="True" />
        </li>
        <li>
            <asp:RadioButtonList Style="margin-left: 27px; padding: 0px; border: 0px;" ID="rbtnTSCHSelection"
                runat="server" AutoPostBack="True" BorderWidth="0px" Width="128px" RepeatLayout="Flow">
                <asp:ListItem Selected="True" Value="1">Parametric</asp:ListItem>
                <asp:ListItem Value="2">Env Stresses</asp:ListItem>
             </asp:RadioButtonList>
        </li>
    </ul>
    <h3>View</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/turquoise_button.png" ID="Image5" runat="server" EnableViewState="false" />
            <asp:CheckBox ID="chkShowTests" runat="server" Text="Show Tests" AutoPostBack="True" />
        </li>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/delete.png" ID="Image2" runat="server" EnableViewState="false" />
            <asp:CheckBox ID="chkGetFailParams" runat="server" Text="Get Fails" AutoPostBack="True" />
        </li>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/refresh.png" ID="imgViewDailyList" runat="server" EnableViewState="false" />
            <asp:LinkButton ID="lkbViewDailyList" runat="Server" Text="Refresh" EnableViewState="false" />
        </li>
        <li>
            <asp:Image ImageUrl="./Design/Icons/png/24x24/xls_file.png" ID="imgExport" runat="server" EnableViewState="false" />
            <asp:LinkButton ID="lnkExport" runat="Server" Text="Export Data" EnableViewState="false" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc3:Notifications ID="notDailyList" runat="server" EnableViewState="False" />

    <asp:Panel ID="pnlDailyList" Width="1270px" runat="server" ScrollBars="Horizontal"
        EnableViewState="False">
        <asp:GridView ID="gvwDailyList" runat="server" EmptyDataText="There were no batches found for this selection."
            HeaderStyle-Wrap="false" AllowPaging="True" AllowSorting="True" PageSize="50"
            RowStyle-Wrap="false" DataSourceID="odsDailyList" PagerStyle-Wrap="True" class="FilterableTable">
            <RowStyle CssClass="evenrow" Wrap="false" />
            <HeaderStyle Wrap="False" />
            <PagerStyle CssClass="gridViewPager" HorizontalAlign="left" />
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        
        <asp:ObjectDataSource ID="odsDailyList" runat="server" DataObjectTypeName="REMI.BusinessEntities.Batch"
            DeleteMethod="Delete" OldValuesParameterFormatString="{0}" EnablePaging="true"
            SortParameterName="sortExpression" SelectMethod="GetDailyList" TypeName="REMI.Bll.BatchManager"
            UpdateMethod="Save" SelectCountMethod="CountDailyListBatches">
            <SelectParameters>
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$ddlProductGroups" DefaultValue="0" Name="ProductID" PropertyName="SelectedValue" Type="Int32" />
       
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$ddlTestCenters" DefaultValue="0"
                    Name="TestCenterLocation" PropertyName="SelectedValue" Type="Int32" />
                <asp:ControlParameter ControlID="ctl00$leftSidebarContent$rbtnTestStageCompletion" DefaultValue="1"
                    Name="testStageCompletion" PropertyName="SelectedValue" Type="Int32" />
                     <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkGetFailParams" DefaultValue="0"
                    Name="getFailParams" PropertyName="Checked" Type="Boolean" />
                          <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkGetOpsTests" DefaultValue="0"
                    Name="getOpsTests" PropertyName="Checked" Type="Boolean" />
                         <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkGetTechOpsTests" DefaultValue="1"
                    Name="getTechOpsTests" PropertyName="Checked" Type="Boolean" />
                            <asp:ControlParameter ControlID="ctl00$leftSidebarContent$rbtnTSCHSelection" DefaultValue="1"
                    Name="ViewType" PropertyName="SelectedValue" Type="Int32" />
                     <asp:ControlParameter ControlID="ctl00$leftSidebarContent$chkShowTests" DefaultValue="0"
                    Name="chkShowTests" PropertyName="Checked" Type="Boolean" />
            </SelectParameters>
        </asp:ObjectDataSource>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>