<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="Versions.aspx.vb" MasterPageFile="~/MasterPages/MasterPage.master" EnableEventValidation="false" Inherits="Remi.Versions"  MaintainScrollPositionOnPostback="true" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_grdVersionSummary').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [6, 7],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });

            $('table#ctl00_Content_grdMeasurementLinks').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblHeader"></asp:Label></h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgBatchAction" ToolTip="Go Back to Batch" runat="server" />
                <asp:HyperLink ID="hypBatch" runat="server">Batch Info</asp:HyperLink>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgResultAction" ToolTip="Go Back To Result OverView" runat="server" />
                <asp:HyperLink ID="hypResult" runat="server">Result</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">

    <asp:GridView ID="grdVersionSummary" runat="server" EmptyDataText="There were no versions found for this batch." CssClass="FilterableTable" DataSourceID="odsVersionSummary"
            HeaderStyle-Wrap="false" AllowPaging="False" AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" AutoGenerateColumns="false">
        <RowStyle CssClass="evenrow" />
        <HeaderStyle Wrap="False" />
        <AlternatingRowStyle CssClass="oddrow" />
        <Columns>
            <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit" SortExpression="BatchUnitNumber" />
            <asp:BoundField DataField="TestStage" HeaderText="Test Stage" SortExpression="TestStage" />
            <asp:BoundField DataField="StationName" HeaderText="Station Name" SortExpression="StationName" />
            <asp:BoundField DataField="StartDate" HeaderText="Start Date" SortExpression="StartDate" />
            <asp:BoundField DataField="EndDate" HeaderText="End Date" SortExpression="EndDate" />
            <asp:BoundField DataField="VerNum" HeaderText="Version" SortExpression="VerNum" />
            <asp:TemplateField HeaderText="XML" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnXML" runat="server" ToolTip="XML File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="XML" CommandArgument='<%# Eval("ResultXML") %>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Product XML" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnProductXML" runat="server" ToolTip="Product File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="ProductXML" CommandArgument='<%# Eval("ProductXML")%>' Visible='<%# Eval("ProductXML") <> String.Empty%>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Test XML" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnTestXML" runat="server" ToolTip="Test File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="TestXML" CommandArgument='<%# Eval("TestXML")%>' Visible='<%# Eval("TestXML") <> String.Empty%>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Sequence XML" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnSequenceXML" runat="server" ToolTip="Sequence File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="SequenceXML" CommandArgument='<%# Eval("SequenceXML")%>' Visible='<%# Eval("SequenceXML") <> String.Empty%>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Station XML" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnStationXML" runat="server" ToolTip="Station File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="StationXML" CommandArgument='<%# Eval("StationXML")%>' Visible='<%# Eval("StationXML") <> String.Empty %>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Loss File" SortExpression="">
                <ItemTemplate>
                    <asp:LinkButton ID="lbtnLoss" runat="server" ToolTip="Loss File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="LOSS" CommandArgument='<%# Eval("LossFile") %>' Visible='<%# Eval("LossFile") <> String.Empty %>'></asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="Processed" HeaderText="Processed" SortExpression="Processed" />
        </Columns>
    </asp:GridView>
    <asp:ObjectDataSource ID="odsVersionSummary" runat="server" EnablePaging="False" SelectMethod="ResultVersions" TypeName="REMI.Bll.RelabManager">
        <SelectParameters>
            <asp:QueryStringParameter Name="BatchID" Type="Int32" QueryStringField="Batch" />
            <asp:QueryStringParameter Name="TestID" Type="Int32" QueryStringField="TestID" />
            <asp:QueryStringParameter Name="UnitNUmber" Type="Int32" QueryStringField="unitNumber" DefaultValue="0" />
            <asp:QueryStringParameter Name="TestStageID" Type="Int32" QueryStringField="TestStageID" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <br />
    <asp:GridView ID="grdMeasurementLinks" runat="server" EmptyDataText="There were no measurement links found for this batch." CssClass="FilterableTable" DataKeyNames="ID"
            HeaderStyle-Wrap="false" AllowPaging="False" AllowSorting="False" EnableViewState="false" RowStyle-Wrap="false" AutoGenerateColumns="false">
        <RowStyle CssClass="evenrow" />
        <HeaderStyle Wrap="False" />
        <AlternatingRowStyle CssClass="oddrow" />
        <Columns>
            <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit" SortExpression="BatchUnitNumber" />
            <asp:TemplateField HeaderText="Measurement" SortExpression="">
                <ItemTemplate>
                    <asp:HyperLink ID="hplDetail" runat="server" Text='<%# Eval("TestStageName") %>' Target="_self"></asp:HyperLink>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>