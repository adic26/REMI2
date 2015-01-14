<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.ScanForInfo_Default" Codebehind="Default.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<%@ Register Src="../Controls/RequestSetup.ascx" TagName="RequestSetup" TagPrefix="rs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>
        <asp:Label runat="server" ID="lblQRANumber" Text="Batch Information"></asp:Label>
    </h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
    <script type="text/javascript" src="../design/scripts/jQuery/jquery.min.js"></script> 
    <script type="text/javascript" src="../design/scripts/jQueryUI/jquery-ui.min.js"></script>
    <script type="text/javascript" src="../design/scripts/gridviewScroll.min.js"></script>
    <script type="text/javascript" src="../Design/scripts/jquery.columnfilters.js"></script>
    
    <script type="text/javascript">
        function ApplyTableFormatting() {  //apply css to the table
            $(".ScrollTable >tbody tr td:contains('False')").removeClass().addClass("Fail")
            $(".ScrollTable >tbody tr td:contains('True')").removeClass().addClass("Pass")
            $(".ScrollTable >tbody tr td:contains('N/A')").removeClass().addClass("DNP")
            $(".ScrollTable >tbody tr td:contains('DNP')").removeClass().addClass("DNP")
            $(".ScrollTable >tbody tr td:contains('Complete')").removeClass().addClass("Pass")
            $(".ScrollTable >tbody tr td:contains('CompleteFail')").removeClass().addClass("Fail")
            $(".ScrollTable >tbody tr td:contains('CompleteKnownFailure')").removeClass().addClass("KnownIssue")
            $(".ScrollTable >tbody tr td:contains('WaitingForResult')").removeClass().addClass("WaitingForResult")
            $(".ScrollTable >tbody tr td:contains('NeedsRetest')").removeClass().addClass("NeedsRetest")
            $(".ScrollTable >tbody tr td:contains('FARaised')").removeClass().addClass("FARaised")
            $(".ScrollTable >tbody tr td:contains('FARequired')").removeClass().addClass("RequiresFA")
            $(".ScrollTable >tbody tr td:contains('InProgress')").removeClass().addClass("WaitingForResult")
            $(".ScrollTable >tbody tr td:contains('Quarantined')").removeClass().addClass("Quarantined")
            $(".ScrollTable >tbody tr td a:contains('Complete')").parent().removeClass().addClass("Pass")
            $(".ScrollTable >tbody tr td a:contains('CompleteFail')").parent().removeClass().addClass("Fail")
            $(".ScrollTable >tbody tr td a:contains('CompleteKnownFailure')").parent().removeClass().addClass("KnownIssue")
            $(".ScrollTable >tbody tr td a:contains('WaitingForResult')").parent().removeClass().addClass("WaitingForResult")
            $(".ScrollTable >tbody tr td a:contains('NeedsRetest')").parent().removeClass().addClass("NeedsRetest")
            $(".ScrollTable >tbody tr td a:contains('FARaised')").parent().removeClass().addClass("FARaised")
            $(".ScrollTable >tbody tr td a:contains('FARequired')").parent().removeClass().addClass("RequiresFA")
            $(".ScrollTable >tbody tr td a:contains('FAComplete_OutOfTest')").parent().removeClass().addClass("FARaised")
            $(".ScrollTable >tbody tr td a:contains('FAComplete_InTest')").parent().removeClass().addClass("Pass")
            $(".ScrollTable >tbody tr td a:contains('InProgress')").parent().removeClass().addClass("WaitingForResult")
            $(".ScrollTable >tbody tr td a:contains('Quarantined')").parent().removeClass().addClass("Quarantined")
        }

        $(document).ready(function () {
            gridviewScroll();
            ApplyTableFormatting();
        });

        function gridviewScroll2() {
            $('#<%=gvwStressingSummary.ClientID%>').gridviewScroll({
                width: 1250,
                height: 500,
                freezesize: 1
            });
        }

        function gridviewScroll() {
            $('#<%=gvwTestingSummary.ClientID%>').gridviewScroll({
                width: 1250,
                height: 500,
                freezesize: 1
            });
        }

        function AddException(jobname, TestStageName, TestName, qranumber, unitcount, unitNumber) {
            $.ajax({
                type: "POST",
                url: "default.aspx/AddException",
                data: '{jobname: "' + jobname + '", teststagename: "' + TestStageName + '", testname: "' + TestName + '", qraNumber: "' + qranumber + '", unitcount: "' + unitcount + '", unitnumber: "' + unitNumber + '" }',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    if (response.d == true) {
                        var check = document.getElementById(jobname + TestStageName + TestName + qranumber + unitNumber);
                        var lbl = document.getElementById("label" + jobname + TestStageName + TestName + qranumber + unitNumber);
                        $(check).hide();
                        $(lbl).text("DNP");
                    } else {
                        alert("Add Exception Failed");
                    }
                },
                failure: function (response) {
                    alert("Add Exception Failed");
                }
            });
        }

        $(document).ready(function () {
            $('table#ctl00_Content_acpUnitInfo_content_grdDetail').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });
    </script>

    <script type="text/javascript" src='<%= ResolveUrl("~/Design/scripts/wz_tooltip.js")%>'></script>
    <h3>Menu</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgSummaryView" runat="server" />
            <asp:HyperLink ID="hypRefresh" runat="server">Refresh</asp:HyperLink>
        </li>
        <li id="liEditExceptions" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/Delete.png" ID="imgEditExceptions"
                runat="server" />
            <asp:HyperLink ID="hypEditExceptions" runat="server" ToolTip="Click to edit the exceptions for this batch" Target="_blank">Edit Exceptions</asp:HyperLink>
        </li>
        <li id="liModifyStatus" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeStatus" runat="server" />
            <asp:HyperLink ID="hypChangeStatus" runat="server" ToolTip="Click to change the status for this batch">Modify Status</asp:HyperLink>
        </li>
        <li id="liModifyStage" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgChangeTestStage"
                runat="server" />
            <asp:HyperLink ID="hypChangeTestStage" runat="server" ToolTip="Click to change the test stage for this batch">Modify Stage</asp:HyperLink>
        </li>
        <li id="liModifyTestDurations" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgModifyTestDurations"
                runat="server" />
            <asp:HyperLink ID="hypModifyTestDurations" runat="server" ToolTip="Click to change the test durations for this batch">Modify Durations</asp:HyperLink>
        </li>
        <li id="liModifyPriority" runat="server" visible="false">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgchangePriority" runat="server" />
            <asp:HyperLink ID="hypChangePriority" runat="server" ToolTip="Click to change the priority for this batch">Modify Priority</asp:HyperLink>
        </li>
        <li id="li" runat="server">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgTestRecords" runat="server" Visible="false" />
            <asp:HyperLink ID="hypTestRecords" runat="server" Visible="false" ToolTip="Click to view the test records for this batch" Target="_blank">Test Records</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/mobile_phone.png" ID="imgProductGroupLink" runat="server" Visible="false" />
            <asp:HyperLink ID="hypProductGroupLink" runat="server" Visible="false" ToolTip="Click to view the product group information for this batch" Text="Product Info" Target="_blank">Product Info</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgTRSLink" runat="server" Visible="false" />
            <asp:HyperLink ID="hypTRSLink" runat="server" ToolTip="Click to view the TRS for this batch" Target="_blank" Visible="false">Request Link</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgRelabLink" runat="server" Visible="false" />
            <asp:HyperLink ID="hypRelabLink" runat="server" ToolTip="Click to view the Results for this batch" Visible="false" Target="_blank">Results</asp:HyperLink>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:Panel ID="pnlSummary" runat="server">
        <asp:Panel ID="submitform" runat="server" DefaultButton="btnSubmit">
            <asp:HiddenField ID="hdnQRANumber" runat="server" Value="0" />
            <asp:HiddenField ID="hdnDepartmentID" runat="Server" Value="0" />
            <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility: hidden;
                display: none;" />
            <img alt="Scan Barcode into text box" class="ScanDeviceImage" src="../Design/Icons/png/48x48/barcode.png" />
            &nbsp;<asp:TextBox ID="txtBarcodeReading" runat="server" CssClass="ScanDeviceTextEntryHint"
                value="Enter Request Number..." onfocus="if (this.className=='ScanDeviceTextEntryHint') { this.className = 'ScanDeviceTextEntry'; this.value = ''; }"
                onblur="if (this.value == '') { this.className = 'ScanDeviceTextEntryHint'; this.value = 'Enter Request Number...'; }"></asp:TextBox><asp:Button
                    ID="btnSubmit" runat="server" CssClass="ScanDeviceButton" Text="Submit" />

            &nbsp&nbsp;<asp:Label runat="server" ID="lblResult"></asp:Label>
        </asp:Panel>
        <uc3:BatchSelectControl ID="bscMain" runat="server" DisplayMode="BatchInfoDisplay" />
        <asp:Accordion ID="accMain" runat="server" CssClass="Accordion" HeaderCssClass="AccordionHeader"
            ContentCssClass="AccordionContent" FadeTransitions="false" RequireOpenedPane="false" AutoSize="None" SuppressHeaderPostbacks="true">
            <Panes>
                <asp:AccordionPane ID="acpExecutiveSummary" runat="server">
                    <Header>
                        <h2>Executive Summary</h2>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updExecutiveSummary" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
                            <ContentTemplate>
                                <img src="http://go/remi/Design/beta.jpg" alt="Executive Summary" /><br />
                                <asp:TextBox ID="txtExecutiveSummary" runat="server" Rows="5" Columns="60" Enabled="false" TextMode="MultiLine"></asp:TextBox>
                                <asp:HyperLink runat="server" ID="hpyES" Target="_blank">Executive Summary</asp:HyperLink>
                                <br /><asp:Button runat="server" ID="btnExecutiveSummary" Text="Save" CssClass="button" Visible="false" OnClick="btnExecutiveSummary_OnClick" />

                                <asp:UpdateProgress ID="upExecutiveSummary" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updExecutiveSummary">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpRequest" runat="server">
                    <Header>
                        <h2>Request Info</h2>
                    </Header>
                    <Content>
                        <asp:GridView ID="gvwRequestInfo" runat="server" AutoGenerateColumns="false">
                            <Columns>
                                <asp:BoundField DataField="Name" HeaderText="Field" ReadOnly="True" SortExpression="ID" Visible="True" />
                                <asp:TemplateField HeaderText="Info" ItemStyle-Wrap="true">
                                    <ItemTemplate>
                                        <div style="white-space:normal;text-align:left;">
                                            <asp:HiddenField runat="server" ID="hdnType" Value='<%# Eval("FieldType")%>' />
                                            <asp:Label runat="server" ID="lblValue" Width="500px" Text='<%# Eval("Value") %>' Visible="true"></asp:Label>
                                            <asp:HyperLink ID="hylValue"  runat="server" Target="_blank" Text="Link" NavigateUrl='<%# Eval("Value")%>' Visible="false"></asp:HyperLink>
                                        </div>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpBatchInfo" runat="server">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="lblNotificationHeader" Text="Notifications"></asp:Label></h2>
                    </Header>
                    <Content>
                        <uc1:NotificationList ID="notMain" runat="server" />
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpComments" runat="server">
                    <Header>
                        <asp:UpdatePanel ID="UpdatePanel1" runat="server" ChildrenAsTriggers="true" UpdateMode="Conditional">
                   
                            <ContentTemplate>
                                <h2>
                                    <asp:Label runat="server" ID="lblAccordionCommentsSectionHeader" Text="Comments"></asp:Label></h2>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updComments" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" >
                            <ContentTemplate>
                                <asp:Repeater runat="server" ID="rptBatchComments">
                                    <HeaderTemplate>
                                        <ul class="InformationMessage">
                                    </HeaderTemplate>
                                    <FooterTemplate>
                                        </ul>
                                    </FooterTemplate>
                                    <ItemTemplate>
                                        <li><b>
                                            <%# REMI.BusinessEntities.Helpers.DateTimeformat(DataBinder.Eval(Container.DataItem, "dateadded"))%></b>
                                            -
                                            <%#DataBinder.Eval(Container.DataItem, "username")%>
                                            <br />
                                            <%#DataBinder.Eval(Container.DataItem, "text")%>
                                            <asp:LinkButton ID="lnkDeleteComment" runat="server" OnClick="lnkDeleteComment_Click" Style="display: block; width: 50px; border-bottom: none;" CommandArgument='<%# DataBinder.Eval(Container.DataItem, "id") %>'>Remove</asp:LinkButton>
                                            <asp:HiddenField ID="hdnUserName" runat="server" Value='<%#DataBinder.Eval(Container.DataItem, "username")%>' />
                                        </li>
                                    </ItemTemplate>
                                </asp:Repeater>
                                <asp:TextBox runat="server" ID="txtNewCommentText" Rows="5" Columns="60" TextMode="MultiLine" Enabled="true"></asp:TextBox>
                                <br />
                                <asp:Button runat="server" CssClass="button" Text="Add Comment" ID="btnAddComment" OnClick="btnAddComment_Click" Enabled="true" />
                                     <asp:UpdateProgress ID="UpdateProgress4" runat="server" DynamicLayout="true" DisplayAfter="100"
                                    AssociatedUpdatePanelID="updComments">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpTaskAssignments" runat="server">
                    <Header>
                        <asp:UpdatePanel ID="updTaskAssignmentHeader" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" >
                            <ContentTemplate>
                                <h2>
                                    <asp:Label runat="server" ID="Label6" Text="Assignment"></asp:Label></h2>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updTaskAssignments" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" >
                            <ContentTemplate>
                                <asp:GridView ID="gvwTaskAssignments" runat="server" DataKeyNames="TaskID" AutoGenerateColumns="false">
                                    <Columns>
                                        <asp:BoundField DataField="TaskID" HeaderText="TaskID" Visible="false" ReadOnly="true" />
                                        <asp:TemplateField HeaderText="Stage Name">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="lblTaskName" Text='<%# Eval("TaskName") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Assigned To">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="lblTaskAssignedTo" Text='<%# Eval("AssignedTo") %>'></asp:Label>
                                                <asp:Panel runat="server" ID="pnlRemoveLink" Visible='<%# Not String.IsNullOrEmpty(DataBinder.Eval(Container.DataItem, "AssignedTo")) andalso REMI.Bll.UserManager.GetCurrentUser().HasTaskAssignmentAuthority %>'>
                                                    (<asp:LinkButton runat="server" ID="lnkRemoveTaskAssignment" Text="Remove" CommandName="RemoveTaskAssignment"
                                                        CommandArgument='<%# Eval("TaskID") %>'></asp:LinkButton>)
                                                </asp:Panel>
                                                <asp:Panel runat="server" ID="pnlReassignTask" Visible='<%# String.IsNullOrEmpty(DataBinder.Eval(Container.DataItem, "AssignedTo")) andalso REMI.Bll.UserManager.GetCurrentUser().HasTaskAssignmentAuthority %>'>
                                                    <asp:AutoCompleteExtender runat="server" ID="aceTxtAssignedTo" 
                                                        ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20" EnableCaching="false" TargetControlID="txtAssignTaskToUser">
                                                    </asp:AutoCompleteExtender>
                                                    <asp:TextBox runat="server" ID="txtAssignTaskToUser"></asp:TextBox>
                                                    <asp:Button ID="btnAssignTaskToUser" runat="server" Text="Reassign" CommandName="ReassignTask"
                                                        CommandArgument='<%# Eval("TaskID") %>' />
                                                </asp:Panel>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Assigned By">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="lblTaskAssignedBy" Text='<%# Eval("AssignedBy") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Assigned On">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="lblTaskAssignedOn" Text='<%# REMI.BusinessEntities.Helpers.DateTimeformat(Eval("AssignedOn"))%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <RowStyle CssClass="evenrow" />
                                    <AlternatingRowStyle CssClass="oddrow" />
                                </asp:GridView>
                                 <asp:UpdateProgress ID="UpdateProgress3" runat="server" DynamicLayout="true" DisplayAfter="100"
                                    AssociatedUpdatePanelID="updTaskAssignments">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpUnitInfo" runat="server" Width="1200px">
                    <Header>
                        <h2>
                            <asp:Label runat="server" ID="lblUnitCount" Text="Unit Info"></asp:Label>
                        </h2>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="TestUnitUP" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true" >
                            <ContentTemplate>
                                <asp:GridView ID="grdDetail" runat="server" DataKeyNames="ID" AutoGenerateColumns="false">
                                    <Columns>
                                        <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                                            SortExpression="ID" Visible="False" />
                                        <asp:TemplateField HeaderText="Unit #" SortExpression="BatchUnitNumber">
                                            <ItemTemplate>
                                                <asp:HyperLink ID="hypBUN" runat="server" ToolTip="Click to view the information for this Unit" Target="_blank" NavigateUrl='<%# Eval("UnitInfoLink") %>' Text='<%# Eval("BatchUnitNumber") %>'></asp:HyperLink>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="BSN" SortExpression="BSN">
                                            <ItemTemplate>
                                                <asp:Label runat="server" ID="lblNoBSN" Visible='<%# Eval("NoBSN") %>' Text="No BSN Required" />
                                                <asp:HyperLink ID="hypBSN" Visible='<%# Not Eval("NoBSN") %>' runat="server" Target="_blank" ToolTip="Click to view the manufactuaring information page for this Unit" NavigateUrl='<%# Eval("MfgWebLink") %>' Text='<%# Eval("BSN") %>'></asp:HyperLink>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="IMEI" HeaderText="IMEI" ReadOnly="True" SortExpression="IMEI" Visible="True" />
                                        <asp:TemplateField HeaderText="Assigned To" SortExpression="AssignedTo">
                                            <ItemTemplate>
                                                <asp:Label ID="Label1" runat="server" Text='<%# REMI.BusinessEntities.Helpers.UserNameformat(Eval("AssignedTo"))%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Current Test Stage" SortExpression="CurrentTestStage">
                                            <ItemTemplate>
                                                <asp:Label ID="Label4" runat="server" Text='<%# Eval("CurrentTestStage") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Current Test" SortExpression="CurrentTest">
                                            <ItemTemplate>
                                                <asp:Label ID="Label3" runat="server" Text='<%# Eval("CurrentTest") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Current Location">
                                            <ItemTemplate>
                                                <asp:Label ID="Label5" runat="server" Text='<%# Eval("LocationString") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField ShowHeader="False">
                                            <ItemTemplate>
                                                <asp:LinkButton ID="lnkDelete" runat="server"  
                                                    CommandArgument='<%# Eval("ID") %>' onclientclick="return confirm('Are you sure you want to delete this unit?');" CommandName="DeleteUnit" CausesValidation="false">Delete</asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="CanDelete" HeaderText="CanDelete" InsertVisible="False" ReadOnly="True" SortExpression="CanDelete" Visible="False" />
                                    </Columns>
                                    <RowStyle CssClass="evenrow" />
                                    <AlternatingRowStyle CssClass="oddrow" />
                                </asp:GridView>
                                <asp:UpdateProgress ID="UpdateProgress5" runat="server" DynamicLayout="true" DisplayAfter="100"
                                    AssociatedUpdatePanelID="TestUnitUP">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpTestingSummary" runat="server">
                    <Header>
                        <h2>
                            Testing Summary
                        </h2>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updSetupTesting" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="btnEdit" />
                            </Triggers>
                            <ContentTemplate>
                                <asp:Button runat="server" ID="btnEdit" Text="Edit Setup" CssClass="buttonSmall" CausesValidation="true" OnClick="btnEdit_Click" />
                                
                                <rs:RequestSetup ID="setup" runat="server" Visible="false" />

                                <asp:UpdatePanel ID="updTestingsummary" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true"  >
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="lnkCheckForUpdates" />
                                    </Triggers>
                                    <ContentTemplate>
                                        <asp:GridView ID="gvwTestingSummary" runat="server" CssClass="ScrollTable" EmptyDataText="No Data." HeaderStyle-Wrap="false" Width="100%" htmlencode="false">
                                            <RowStyle CssClass="evenrow" />
                                            <AlternatingRowStyle CssClass="oddrow" />
                                        </asp:GridView>
                                        <asp:Button ID="lnkCheckForUpdates" runat="server"  Text="Update Results" CssClass="button" Style="float: left;" Enabled="false" />
                                    </ContentTemplate>
                                </asp:UpdatePanel>

                                <asp:UpdateProgress ID="upSetupTesting" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updSetupTesting">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpStressingSummary" runat="server">
                    <Header>
                        <h2>
                            Stressing Summary
                        </h2>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updSetupStressing" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="btnEditStressing" />
                            </Triggers>
                            <ContentTemplate>
                                <asp:Button runat="server" ID="btnEditStressing" Text="Edit Setup" CssClass="buttonSmall" CausesValidation="true" OnClick="btnEditStressing_Click" />
                                <h2><asp:Label runat="server" ID="lblOrientation"></asp:Label></h2>
                                
                                <rs:RequestSetup runat="server" Visible="false" ID="setupStressing" />
        
                                <asp:UpdatePanel ID="updStressingSummary" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="lnkCheckForUpdates2" />
                                    </Triggers>
                                    <ContentTemplate>
                                        <asp:Label runat="server" ID="lblNote"><h4>If you see TestingSuspended it is due to the unit being scanned into that location more than once so the test record thinks an error has occured or you have removed the units prematurely. Reset the test record to In Progress</h4></asp:Label>
                                        
                                        <asp:GridView ID="gvwStressingSummary" runat="server" CssClass="ScrollTable" EmptyDataText="No Data." HeaderStyle-Wrap="false" Width="100%" htmlencode="false">
                                            <RowStyle CssClass="evenrow" />
                                            <AlternatingRowStyle CssClass="oddrow" />
                                        </asp:GridView>
                                        <asp:Button runat="server" ID="lnkCheckForUpdates2" Text="Update Results" CssClass="button" Style="float: left;" Enabled="false" />
                                    </ContentTemplate>
                                </asp:UpdatePanel>
                        
                                <asp:UpdateProgress ID="upSetupStressing" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updSetupStressing">
                                    <ProgressTemplate>
                                        <div class="LoadingModal"></div>
                                        <div class="LoadingGif"></div>
                                    </ProgressTemplate>
                                </asp:UpdateProgress>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
               
                <asp:AccordionPane ID="acpTrackingLogs" runat="server">
                    <Header>
                        <h2>
                            Tracking Logs
                        </h2>
                    </Header>
                    <Content>
                        Select Timeframe:
                        <asp:DropDownList ID="ddlTime" runat="server" AutoPostBack="True" Width="162px" Enabled="False">
                            <asp:ListItem Value="1">Last Hour</asp:ListItem>
                            <asp:ListItem Value="12">Last 12 Hours</asp:ListItem>
                            <asp:ListItem Value="24">Last 24 Hours</asp:ListItem>
                            <asp:ListItem Value="168">Last Week</asp:ListItem>
                            <asp:ListItem Value="720">Last 30 Days</asp:ListItem>
                            <asp:ListItem Value="2191" Selected="True">Last 3 Months</asp:ListItem>
                            <asp:ListItem Value="4382">Last 6 Months</asp:ListItem>
                            <asp:ListItem Value="8766">Last Year</asp:ListItem>
                            <asp:ListItem Value="999999">All</asp:ListItem>
                        </asp:DropDownList>
                        <asp:UpdateProgress ID="UpdateProgress2" runat="server" DynamicLayout="true" DisplayAfter="100"
                            AssociatedUpdatePanelID="updPanelLogs">
                            <ProgressTemplate>
                                <div class="LoadingModal"></div>
                                <div class="LoadingGif"></div>
                            </ProgressTemplate>
                        </asp:UpdateProgress>
                        <br />
                        <br />
                        <asp:UpdatePanel ID="updPanelLogs" runat="server" UpdateMode="Conditional">
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="ddlTime" />
                            </Triggers>
                            <ContentTemplate>
                                <script type="text/javascript">
                                    var prm = Sys.WebForms.PageRequestManager.getInstance();
                                    prm.add_pageLoaded(EndRequestOverall);

                                    function EndRequestOverall(sender, args) {
                                        if (prm._postBackSettings != null) {
                                            if (prm._postBackSettings.sourceElement.id == 'ctl00_Content_acpTrackingLogs_content_ddlTime') {
                                                $('table#ctl00_Content_acpTrackingLogs_content_grdTrackingLog').columnFilters(
                                                {
                                                    caseSensitive: false,
                                                    underline: true,
                                                    wildCard: '*',
                                                    alternateRowClassNames: ['evenrow', 'oddrow']
                                                });
                                            }
                                        }
                                        else {
                                            $('table#ctl00_Content_acpTrackingLogs_content_grdTrackingLog').columnFilters(
                                            {
                                                caseSensitive: false,
                                                underline: true,
                                                wildCard: '*',
                                                alternateRowClassNames: ['evenrow', 'oddrow']
                                            });
                                        }
                                    }
                                </script>

                                <asp:GridView ID="grdTrackingLog" runat="server" AutoGenerateColumns="False" EnableViewState="False"
                                    DataSourceID="odsTrackingLog" EmptyDataText="No tracking logs available for this time period.">
                                    <Columns>
                                        <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                                            SortExpression="ID" Visible="False" />
                                        <asp:BoundField DataField="TestUnitID" HeaderText="TestUnitID" SortExpression="TestUnitID"
                                            Visible="False" />
                                        <asp:TemplateField HeaderText="Unit" SortExpression="BatchUnitNumber">
                                            <ItemTemplate>
                                                <asp:Label ID="lblUnitNumber" runat="server" Text='<%# Eval("TestUnitBatchUnitNumber") %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Location" SortExpression="TrackingLocation">
                                            <ItemTemplate>
                                                <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("TrackingLocationLink") %>'
                                                    Text='<%# Eval("TrackingLocationName") %>'></asp:HyperLink>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Logged In" SortExpression="InTime">
                                            <ItemTemplate>
                                                <asp:Label ID="Label2" runat="server" Text='<%# REMI.BusinessEntities.Helpers.DateTimeformat(Eval("InTime"))%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Logged In By" SortExpression="InUser">
                                            <ItemTemplate>
                                                <asp:Label ID="Label3" runat="server" Text='<%# REMI.BusinessEntities.Helpers.UserNameformat(Eval("InUser"))%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                        <asp:ObjectDataSource ID="odsTrackingLog" runat="server" SelectMethod="Get24HourLogsForBatch"
                            TypeName="REMI.Bll.TrackingLogManager" OldValuesParameterFormatString="original_{0}">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnQRANumber" DefaultValue="-1" Name="QRANumber"
                                    PropertyName="Value" Type="String" />
                                <asp:ControlParameter ControlID="ddlTime" DefaultValue="-1" Name="TimeInHours" PropertyName="SelectedValue"
                                    Type="Int32" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpAuditLogs" runat="server">
                    <Header>
                        <h2>Audit Logs</h2>
                    </Header>
                    <Content>
                        <asp:GridView ID="grdAuditLog" runat="server" DataSourceID="odsAuditLog" AutoGenerateColumns="True" EnableViewState="False" EmptyDataText="No Audit Logs Yet.">
                            <Columns>
                            </Columns>
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsAuditLog" runat="server" SelectMethod="GetBatchAuditLogs" TypeName="REMI.Bll.BatchManager">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnQRANumber" DefaultValue="-1" Name="QRANumber" PropertyName="Value" Type="String" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpUnitExceptions" runat="server">
                    <Header>
                        <h2>Unit Exceptions</h2>
                    </Header>
                    <Content>
                        <asp:UpdatePanel ID="updException" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <script type="text/javascript">
                                    var prm = Sys.WebForms.PageRequestManager.getInstance();
                                    prm.add_pageLoaded(EndRequestOverall);

                                    function EndRequestOverall(sender, args) {
                                        $('table#ctl00_Content_acpUnitExceptions_content_gvwTestExceptions').columnFilters(
                                        {
                                            caseSensitive: false,
                                            underline: true,
                                            wildCard: '*',
                                            alternateRowClassNames: ['evenrow', 'oddrow']
                                        });
                                    }
                                </script>

                                <asp:GridView ID="gvwTestExceptions" Visible="true" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" EmptyDataText="No Exception Data Available" CssClass="FilterableTable" EnableViewState="True" AllowPaging="true" PageSize="150">
                                    <Columns>
                                        <asp:TemplateField HeaderText="ID" SortExpression="ID">
                                            <ItemTemplate>
                                                <asp:Label ID="lblID" runat="server" Text='<%# Eval("ID") %>' Visible='<%# Remi.Bll.UserManager.GetCurrentUser.IsAdmin %>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="LastUser" HeaderText="LastUser" />
                                        <asp:BoundField DataField="TestCenter" HeaderText="TestCenter" />
                                        <asp:BoundField DataField="ProductGroup" HeaderText="ProductGroup" />
                                        <asp:BoundField DataField="ProductType" HeaderText="Product Type" />
                                        <asp:BoundField DataField="AccessoryGroupName" HeaderText="Accessory Group Name" />
                                        <asp:BoundField DataField="ID" HeaderText="ID" Visible="False" />
                                        <asp:BoundField DataField="UnitNumber" HeaderText="Unit Number" />
                                        <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" />
                                        <asp:BoundField DataField="TestName" HeaderText="Test" />
                                        <asp:BoundField DataField="IsMQual" HeaderText="IsMQual" />
                                    </Columns>
                                </asp:GridView>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </Content>
                </asp:AccordionPane>
                <asp:AccordionPane ID="acpDocuments" runat="server">
                    <Header>
                        <h2>
                            Documents
                        </h2>
                    </Header>
                    <Content>
                        <asp:GridView ID="gvwDocuemnts" runat="server" CssClass="FilterableTable" AutoGenerateColumns="false" DataSourceID="odsDocuments" EmptyDataText="No Data." HeaderStyle-Wrap="false" EnableViewState="False">
                            <RowStyle CssClass="evenrow" />
                            <HeaderStyle Wrap="False" />
                            <AlternatingRowStyle CssClass="oddrow" />
                            <Columns>
                                <asp:TemplateField HeaderText="Document Link(s)" SortExpression="InUser" ItemStyle-CssClass="removeStyle">
                                    <ItemTemplate>
                                        <asp:Image ID="imgDoc" runat="server" ImageUrl="/Design/Icons/png/24x24/doc_file.png"  />
                                        <asp:HyperLink ID="hylDocument"  runat="server" Target="_blank" Text='<%# Eval("WIType")%>' NavigateUrl='<%# Eval("Location")%>'></asp:HyperLink>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                        <asp:ObjectDataSource ID="odsDocuments" runat="server" SelectMethod="GetBatchDocuments" TypeName="REMI.Bll.BatchManager">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="hdnQRANumber" DefaultValue="-1" Name="QRANumber" PropertyName="Value" Type="String" />
                            </SelectParameters>
                        </asp:ObjectDataSource>
                    </Content>
                </asp:AccordionPane>
            </Panes>
        </asp:Accordion>
        <br />
    </asp:Panel> 
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
