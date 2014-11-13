<%@ Control Language="VB" AutoEventWireup="false" Inherits="Remi.Controls_IBatchListControl" Codebehind="IBatchListControl.ascx.vb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:GridView ID="grdBatches" runat="server" EmptyDataText="There are no batches available."
    AutoGenerateColumns="False" DataKeyNames="ID">
    <RowStyle CssClass="evenrow" />
    <Columns>
        
        <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" Visible = "false" SortExpression="ID" />
        <asp:TemplateField HeaderText="QRA" SortExpression="QRANumber">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="false" ID="hypQRANumber" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>'
                    Text='<%# Eval("QRANumber") %>' ToolTip='<%# "Click to view the information page for this batch" %>'></asp:HyperLink></ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="ProductGroup" HeaderText="Product" SortExpression="ProductGroup" ReadOnly="true" />
        <asp:BoundField DataField="TestCenterLocation" HeaderText="Test Center" SortExpression="TestCenterLocation" ReadOnly="true" />
        <asp:BoundField DataField="NumberOfUnits" HeaderText="# Units" SortExpression="NumberOfUnits" visible="false" ReadOnly="true" />
        <asp:BoundField DataField="NumberOfUnitsExpected" HeaderText="# Units Exp" SortExpression="NumberOfUnitsExpected" visible="false" ReadOnly="true" />
        <asp:BoundField DataField="RequestPurpose" HeaderText="Purpose" SortExpression="RequestPurpose" />
        <asp:TemplateField HeaderText="Job" SortExpression="JobName">
            <ItemTemplate>
                <asp:Label EnableViewState="false" ID="lblJobName" runat="server" Text='<%# Eval("JobName") %>'></asp:Label></ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Test Stage" SortExpression="TestStageName" visible="false" >
            <ItemTemplate>
                <asp:Label EnableViewState="false" ID="lblTestStageName" runat="server" Text='<%# Eval("teststagename") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
             
        <asp:TemplateField HeaderText="Report Due By" SortExpression="ReportRequestedByDate">
            <ItemTemplate>
                <asp:Label EnableViewState="false" ID="lblReportDate" runat="server" Text='<%# Remi.Helpers.datetimeformat(Eval("ReportRequiredby")) %>'></asp:Label></ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="Priority" HeaderText="Priority" SortExpression="Priority" ReadOnly="true" />
        <asp:BoundField DataField="Status" HeaderText="Status" SortExpression="Status" visible="false" ReadOnly="true" />
        <asp:TemplateField HeaderText="RTR">
            <ItemTemplate>
               <asp:Label EnableViewState="false" ID="lblRTR" runat="server" Text='<%# Eval("HasUnitsRequiredToBeReturnedToRequestorString") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="Comments" HeaderText="Comments" SortExpression="Comments" ReadOnly="true" />
        <asp:TemplateField HeaderText="WI">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="false" ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("JobWILocation") %>'
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the WI for the job for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Request">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="false" ID="hypTRSLink" runat="server" NavigateUrl='<%# Eval("RequestLink")%>'
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the request page for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Results">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="false" ID="hypRelabLink" runat="server" NavigateUrl='<%# Eval("RelabResultLink") %>'
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the Results for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Info">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="false" ID="hypBatchInfoLink" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>'
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the information page for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
    </Columns>
    <AlternatingRowStyle CssClass="oddrow" />
</asp:GridView>
