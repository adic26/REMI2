<%@ Control Language="VB" AutoEventWireup="false" Inherits="Remi.Controls_BatchSelectControl" Codebehind="BatchSelectControl.ascx.vb" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:GridView ID="grdBatches" runat="server" EmptyDataText="There are no batches available." EnableViewState="true" OnRowCommand="grdBatches_RowDataCommand" 
    AutoGenerateColumns="False" DataKeyNames="ID" OnRowUpdating="grdBatches_RowUpdating" OnRowCancelingEdit="grdBatches_RowCancelingEdit" OnRowEditing="grdBatches_RowEditing">
    <RowStyle CssClass="evenrow" />
    <Columns>
        <asp:TemplateField>
            <HeaderTemplate>
                <asp:CheckBox EnableViewState="true" ID="chkAll" runat="server" OnCheckedChanged="chkAll_CheckedChanged" AutoPostBack="True" />
            </HeaderTemplate>
            <ItemTemplate>
                <asp:CheckBox EnableViewState="true" ID="chkSelect" runat="server" OnCheckedChanged="chkSelect_CheckedChanged" AutoPostBack="True" />
            </ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True" SortExpression="ID" Visible="True" />
        <asp:TemplateField HeaderText="Request" SortExpression="QRANumber">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="hypQRANumber" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>' Target="_blank" 
                    Text='<%# Eval("QRANumber") %>' ToolTip='<%# "Click to view the information page for this batch" %>'></asp:HyperLink></ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Product" SortExpression="ProductGroup">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="hypBatchProductLink" runat="server" NavigateUrl='<%# Eval("ProductGroupLink") %>' Target="_blank" 
                    Text='<%# Eval("ProductGroup") %>' ToolTip='<%# "Click to view the information page for this product" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="MechanicalTools" HeaderText="Revision" SortExpression="MechanicalTools" ReadOnly="true" />
        <asp:BoundField DataField="ProductType" HeaderText="Product Type" SortExpression="ProductType" ReadOnly="true" />
        <asp:BoundField DataField="AccessoryGroup" HeaderText="Accessory Group" SortExpression="AccessoryGroup" ReadOnly="true" />
        <asp:BoundField DataField="TestCenterLocation" HeaderText="Test Center" SortExpression="TestCenterLocation" ReadOnly="true" />
        <asp:BoundField DataField="Department" HeaderText="Department" SortExpression="Department" ReadOnly="true" />
        <asp:TemplateField HeaderText="Assignee" SortExpression="ActiveTaskAssignee">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblActiveTaskAssignee" runat="server" Text='<%# Eval("ActiveTaskAssignee") %>' Visible="true"></asp:Label>
                <asp:TextBox runat="server" ID="txtActiveTaskAssignee" Text='<%# Eval("ActiveTaskAssignee")%>' Visible="false" EnableViewState="true" />
                <asp:AutoCompleteExtender runat="server" ID="aceTxtAssignedTo" 
                    ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20" EnableCaching="false" TargetControlID="txtActiveTaskAssignee">
                </asp:AutoCompleteExtender>
                <asp:CheckBox runat="server" Checked="true" ID="chkBatch" Visible="false" ToolTip="Assign To Batch" />
            </ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="NumberOfUnits" HeaderText="# Units" SortExpression="NumberOfUnits" ReadOnly="true" />
        <asp:BoundField DataField="NumberOfUnitsExpected" HeaderText="# Units Exp" SortExpression="NumberOfUnitsExpected" ReadOnly="true" />
        <asp:BoundField DataField="RequestPurpose" HeaderText="Purpose" SortExpression="RequestPurpose" ReadOnly="true" />
        <asp:TemplateField HeaderText="Job" SortExpression="JobName">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblJobName" runat="server" Text='<%# Eval("JobName") %>' Visible="false"></asp:Label>
                <asp:HyperLink EnableViewState="true" ID="hypBatchJobLink" runat="server" NavigateUrl='<%# Eval("JobLink") %>' Target="_blank" 
                    Text='<%# Eval("JobName") %>' ToolTip='<%# "Click to view the information for this job" %>' Visible="false"></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Test Stage" SortExpression="TestStageName">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblTestStageName" runat="server" Text='<%# Eval("teststagename") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="CPR" SortExpression="CPRNumber">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblCPR" runat="server" Text='<%# Eval("CPRNumber") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="Priority" HeaderText="Priority" SortExpression="Priority" ReadOnly="true" />    
        <asp:TemplateField HeaderText="Job Rem (h)" SortExpression="EstJobCompletionTime">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblEstJobCompletionTime" runat="server" Text='<%# string.format("{0:F2}",Eval("EstJobCompletionTime")) %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="TS Rem (h)" SortExpression="EstTSCompletionTime">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblEstTSCompletionTime" runat="server" Text='<%# string.format("{0:F2}",Eval("EstTSCompletionTime")) %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="TS Due" SortExpression="TSDue">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="TSDue" runat="server" Text='<%# Eval("GetExpectedCompletionDateTime") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Report Due By" SortExpression="ReportRequestedByDate">
            <ItemTemplate>
                <asp:Label EnableViewState="true" ID="lblReportDate" runat="server" Text='<%# REMI.BusinessEntities.Helpers.DateTimeformat(Eval("ReportRequiredby"))%>'></asp:Label></ItemTemplate>
        </asp:TemplateField>
        <asp:BoundField DataField="Status" HeaderText="Status" SortExpression="Status" Visible="True" ReadOnly="true" />
        <asp:TemplateField HeaderText="RTR">
            <ItemTemplate>              
               <asp:Label EnableViewState="true" ID="lblRTR" runat="server" Text='<%# Eval("HasUnitsRequiredToBeReturnedToRequestorString") %>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Comments">
            <ItemTemplate>              
               <asp:Label EnableViewState="true" ID="lblComments" runat="server" ToolTip='<%# Eval("GetJoinedComments")%>' Text='<%# Remi.BusinessEntities.Helpers.GetStringMaxLength(Eval("GetJoinedComments").ToString(), 50)%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>      
        <asp:TemplateField HeaderText="WI">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("JobWILocation") %>' Target="_blank" 
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the WI for the job for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Request">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="hypTRSLink" runat="server" NavigateUrl='<%# Eval("RequestLink") %>' Target="_blank" 
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the request page for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Results">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="hypRelabLink" runat="server" NavigateUrl='<%# Eval("RelabResultLink") %>' Target="_blank" 
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the Results page for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Info">
            <ItemTemplate>
                <asp:HyperLink EnableViewState="true" ID="hypBatchInfoLink" runat="server" NavigateUrl='<%# Eval("BatchInfoLink") %>' Target="_blank" 
                    Text='<%# "View" %>' ToolTip='<%# "Click to view the information page for this batch" %>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Order"> 
            <ItemTemplate> 
                <asp:LinkButton ID="btnUp" CommandName="Up" ToolTip="Up" Text="&uArr;" CssClass="Order" runat="server" CommandArgument='<%# CType(Container, GridViewRow).RowIndex%>' />
                <asp:LinkButton ID="btnDown" CommandName="Down" ToolTip="Down" Text="&dArr;" CssClass="Order" runat="server" CommandArgument='<%# CType(Container, GridViewRow).RowIndex%>' />
             </ItemTemplate>
        </asp:TemplateField>
    </Columns>
    <AlternatingRowStyle CssClass="oddrow" />
</asp:GridView>
