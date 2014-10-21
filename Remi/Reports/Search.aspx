<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Search" Codebehind="Search.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<%@ Register Src="../Controls/BatchSelectControl.ascx" TagName="BatchSelectControl" TagPrefix="uc3" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">        
        function gvrowtoggle(row) {
            try {
                row_num = row;
                ctl_row = row - 1;
                rows = document.getElementById('<%= gvwENVReport.ClientID %>').rows;
                rowElement = rows[ctl_row];
                img = rowElement.cells[0].firstChild;

                if (rows[row_num].className !== 'hidden') {
                    rows[row_num].className = 'hidden';
                    img.src = '/Design/Icons/png/16x16/link.png';
                }
                else {
                    rows[row_num].className = '';
                    img.src = '/Design/Icons/png/16x16/link.png';
                }
            }
            catch (ex) { alert(ex) }
        }

        function ClearTextBoxes() {
            document.getElementById('<%= txtStart.ClientID %>').value = '';
            document.getElementById('<%= txtEnd.ClientID %>').value = '';
        }
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h2>Advanced Search</h2>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <h3>Quick Search</h3>
    <ul>
        <li>
            <asp:Button runat="server" Text="Testing Complete" ID="btnTestingComplete" CausesValidation="true" CssClass="buttonSmall" OnClick="btn_OnClick" />
        </li>
        <li>
            <asp:Button runat="server" Text="Held" ID="btnHeld" CausesValidation="true" OnClick="btn_OnClick" CssClass="buttonSmall" />
        </li>
        <li>
            <asp:Button runat="server" Text="Reporting" ID="btnReporting" CausesValidation="true" OnClick="btn_OnClick" CssClass="buttonSmall" />
        </li>
        <li>
            <asp:Button runat="server" Text="Incoming" ID="btnIncoming" CausesValidation="true" OnClick="btn_OnClick" CssClass="buttonSmall" />
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:ToolkitScriptManager ID="ToolkitScriptManager1" runat="server"></asp:ToolkitScriptManager>

    <asp:RadioButtonList runat="server" ID="rblSearchBy" TextAlign="right" RepeatDirection="Horizontal" CellPadding="10" RepeatLayout="Flow" RepeatColumns="3" OnSelectedIndexChanged="rblSearchBy_OnSelectedIndexChanged" CausesValidation="true" AutoPostBack="true" EnableViewState="true">
        <asp:ListItem Text="Batchs" Selected="True" Value="1"></asp:ListItem>
        <asp:ListItem Text="Units" Value="6"></asp:ListItem>
        <asp:ListItem Text="Exceptions" Value="2" Enabled="false"></asp:ListItem>
        <asp:ListItem Text="Users" Value="3" Enabled="false"></asp:ListItem>
        <asp:ListItem Text="RQ Results" Value="4" Enabled="false"></asp:ListItem>
        <asp:ListItem Text="Environment Report" Value="5" Enabled="false"></asp:ListItem>
        <asp:ListItem Value="7" Enabled="false">KPI <img src="../Design/beta.jpg" /></asp:ListItem>
        <asp:ListItem Text="Training" Value="8"></asp:ListItem>
    </asp:RadioButtonList><br />

    <asp:Panel Visible="false" runat="server" ID="pnlTraining">
    Test Center: <asp:DropDownList ID="ddlTestCenterTraining" runat="server" AppendDataBoundItems="True" AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList><br />
        Training: <asp:DropDownList ID="ddlSearchTraining" runat="server" AutoPostBack="False" DataTextField="LookupType" DataValueField="LookupID" Width="238px" AppendDataBoundItems="True" CausesValidation="true">
        </asp:DropDownList><br />
        User: <asp:DropDownList runat="server" ID="ddlUserTraining" AutoPostBack="False" DataTextField="LDAPName" DataValueField="ID"></asp:DropDownList><br />
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlSearchUser">
        Test Center: <asp:DropDownList ID="ddlTestCentersUser" runat="server" AppendDataBoundItems="True" AutoPostBack="False" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID">
        </asp:DropDownList>
        <br />
        Department: <asp:DropDownList ID="ddlDepartmentUser" runat="server" AppendDataBoundItems="True" AutoPostBack="False" Width="140px" ForeColor="#0033CC"  DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        <br />
        Training: <asp:DropDownList ID="ddlTraining" runat="server" AutoPostBack="False" DataSourceID="odsTraining" DataTextField="LookupType" DataValueField="LookupID" Width="238px" AppendDataBoundItems="True" CausesValidation="true">
        </asp:DropDownList>
        <br />
        Training Level: <asp:DropDownList ID="ddlTrainingLevel" runat="server" AutoPostBack="False" DataSourceID="odsTrainingLevel" DataTextField="LookupType" DataValueField="LookupID" Width="238px" AppendDataBoundItems="True" CausesValidation="true">
        </asp:DropDownList>
        <br />
        Product: <asp:DropDownList ID="ddlProductFilterUser" runat="server" Width="189px" AppendDataBoundItems="True"  AutoPostBack="False" DataTextField="ProductGroupName" DataValueField="ID">
        </asp:DropDownList>
        <br />
        Has ByPass Product Limitation: <asp:CheckBox ID="chkByPass" runat="server" />
        <br /><br />
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlSearchUnits">
        BSN: <asp:TextBox runat="server" ID="txtBSN"></asp:TextBox>
        <br /><br />
    </asp:Panel>
    
    <asp:Panel Visible="true" runat="server" ID="pnlSearchBatch">
        Test Center: <asp:DropDownList ID="ddlTestCenters" runat="server" AppendDataBoundItems="True" AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID">
        </asp:DropDownList>
        <br />
        Department: <asp:DropDownList ID="ddlDepartment" runat="server" AppendDataBoundItems="true" AutoPostBack="false" Width="140px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        <br /> 
        Product: <asp:DropDownList ID="ddlProductFilter" runat="server" Width="189px" AppendDataBoundItems="True"  AutoPostBack="False" DataTextField="ProductGroupName" DataValueField="ID">
        </asp:DropDownList>&nbsp;<asp:CheckBox runat="server" ID="chkShowArchived" TextAlign="Right" Text="Show Archived" AutoPostBack="true" CausesValidation="true" />
        &nbsp; Revision: <asp:TextBox runat="server" ID="txtRevision" MaxLength="10"></asp:TextBox>
        <br />
        Product Type: <asp:DropDownList ID="ddlProductType" runat="server" AutoPostBack="True" DataTextField="LookupType" DataValueField="LookupID"
            Width="238px" AppendDataBoundItems="True" OnSelectedIndexChanged="ddlProductType_SelectedIndexChanged" CausesValidation="true">
        </asp:DropDownList>
        <br />
        Accessory Type: <asp:DropDownList ID="ddlAccessoryGroup" runat="server" AutoPostBack="False" DataTextField="LookupType" DataValueField="LookupID"
            Width="238px" AppendDataBoundItems="True">
        </asp:DropDownList>
        <br />
        Request: <asp:DropDownList ID="ddlRequestReason" runat="server" Width="239px" AppendDataBoundItems="True" AutoPostBack="False" DataTextField="Description" DataValueField="LookupID">
        </asp:DropDownList>
        <br />
        Jobs: <asp:DropDownList ID="ddlJobs" runat="server" DataSourceID="odsJobs" AutoPostBack="True" Width="239px" AppendDataBoundItems="True">
            <asp:ListItem>All</asp:ListItem>
        </asp:DropDownList>
        <br />
        Test Stage: <asp:DropDownList ID="ddlTestStages" runat="server" AutoPostBack="False" Width="237px" AppendDataBoundItems="True" DataTextField="Name" DataValueField="ID">
            <asp:ListItem>All</asp:ListItem>
        </asp:DropDownList>
        &nbsp;<b>OR</b>&nbsp;<asp:TextBox runat="server" ID="txtTestStage" Text=""></asp:TextBox>
        <br />
        Test Stage Type: <asp:DropDownList ID="ddlTestStageType" runat="server" AutoPostBack="false" Width="237px" AppendDataBoundItems="true">
        </asp:DropDownList>
        &nbsp;<b>Exclude</b>&nbsp;
        <asp:CheckBoxList runat="server" ID="chkTestStageType" CssClass="removeStyleWithLeft" RepeatDirection="Horizontal" AutoPostBack="false" Width="237px" AppendDataBoundItems="true"></asp:CheckBoxList>
        Test: <asp:DropDownList ID="ddlTests" DataSourceID="odsTests" runat="server" AutoPostBack="False" Width="238px" AppendDataBoundItems="True" DataValueField="ID" DataTextField="Name">
            <asp:ListItem>All</asp:ListItem>
        </asp:DropDownList>
        <br />
        Batch Status: <asp:DropDownList ID="ddlBatchStatus" runat="server" AutoPostBack="False" Width="239px" AppendDataBoundItems="True"></asp:DropDownList>
        &nbsp;<b>Exclude</b>&nbsp;
        <asp:CheckBoxList runat="server" ID="chkBatchStatus" CssClass="removeStyleWithLeft" RepeatDirection="Horizontal" AutoPostBack="false" Width="239px" AppendDataBoundItems="true"></asp:CheckBoxList>
        Priority: <asp:DropDownList ID="ddlPriority" runat="server" AutoPostBack="False" AppendDataBoundItems="False" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        <br />
        User: <asp:DropDownList runat="server" ID="ddlUsers" AutoPostBack="False" DataTextField="LDAPName" DataValueField="ID"></asp:DropDownList>
        <br />
        Location Type: <asp:DropDownList runat="server" ID="ddlTrackingLocationType" AutoPostBack="False" DataTextField="Name" DataValueField="ID"></asp:DropDownList>
        <br />
        Location Function: <b>IN</b> <asp:DropDownList runat="server" ID="ddlLocationFunction" AutoPostBack="false" AppendDataBoundItems="true"></asp:DropDownList>
        <b>OR</b> <b>NOT IN</b> <asp:DropDownList runat="server" ID="ddlNotInLocationFunction" AutoPostBack="false" AppendDataBoundItems="true"></asp:DropDownList>
        <br />
        Batch Updated Between: <asp:TextBox ID="txtStart" runat="server" DefaultValue="12am"></asp:TextBox><asp:CalendarExtender ID="txtStart_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtStart"></asp:CalendarExtender>
        And:&nbsp;<asp:TextBox ID="txtEnd" runat="server" DefaultValue="12pm"></asp:TextBox><asp:CalendarExtender ID="txtEnd_CalendarExtender" runat="server" Enabled="True" TargetControlID="txtEnd"></asp:CalendarExtender>
        &nbsp;<input type="button" value="Clear Date" onclick="JavaScript: ClearTextBoxes();" />
        <br /><br />
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlSearchExceptions">
        Test Center: <asp:DropDownList ID="ddlTestCentersException" runat="server" AppendDataBoundItems="True" AutoPostBack="True" Width="120px" ForeColor="#0033CC" DataSourceID="odsTestCenters" DataTextField="LookupType" DataValueField="LookupID">
        </asp:DropDownList>
        <br />
        Product: <asp:DropDownList ID="ddlProductFilter2" runat="server" Width="189px" AppendDataBoundItems="True"  AutoPostBack="False" DataTextField="ProductGroupName" DataValueField="ID">
        </asp:DropDownList>
        <br />
        Product Type:
        <asp:DropDownList ID="ddlProductType2" runat="server" AutoPostBack="True" DataTextField="LookupType" DataValueField="LookupID"
            Width="238px" AppendDataBoundItems="True" OnSelectedIndexChanged="ddlProductType2_SelectedIndexChanged" CausesValidation="true">
        </asp:DropDownList>
        <br />
        Accessory Group:
        <asp:DropDownList ID="ddlAccesssoryGroup2" runat="server" AutoPostBack="False" DataTextField="LookupType" DataValueField="LookupID"
            Width="238px" AppendDataBoundItems="True">
        </asp:DropDownList>
        <br />
        Job Name:
        <asp:DropDownList ID="ddlJobs2" runat="server" OnChange="JavaScript:alert('Please Select a Test Stage.\nJobs are Not Exceptioned');" AutoPostBack="True" Width="239px" AppendDataBoundItems="True">
        </asp:DropDownList>
        <br />
        Test Stage Name:
        <asp:DropDownList ID="ddlTestStages2" runat="server" AutoPostBack="True" Width="237px" AppendDataBoundItems="True" DataTextField="Name" DataValueField="ID">
            <asp:ListItem>All</asp:ListItem>
        </asp:DropDownList>
        <br />
        Test Name:
        <asp:DropDownList ID="ddlTests2" runat="server" DataSourceID="odsTests" AutoPostBack="True" DataValueField="ID" DataTextField="Name" Width="238px" AppendDataBoundItems="True">
            <asp:ListItem>All</asp:ListItem>
        </asp:DropDownList>
        <br />
        Request: <asp:DropDownList ID="ddlRequestReasonException" runat="server" Width="239px" AppendDataBoundItems="True" AutoPostBack="False" DataTextField="Description" DataValueField="LookupID"></asp:DropDownList>
        <br />
        IsMQual: <asp:CheckBox runat="server" ID="chkIsMQual" Text="" />
        <br />
        <asp:CheckBox runat="server" ID="chkIncludeBatch" Text="Include Batch Exceptions " TextAlign="Left" />
        <br />
        QRA: <asp:TextBox ID="txtQRANumber" runat="server" CausesValidation="true"></asp:TextBox>
        <asp:CustomValidator ID="valQRANumber" runat="server" Display="Static" ControlToValidate="txtQRANumber" OnServerValidate="QRAValidation" ValidateEmptyText="true"></asp:CustomValidator>

        <br /><br />
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlEnvReport">
        Start: <asp:TextBox ID="txtStartENV" runat="server" DefaultValue="12am"></asp:TextBox>
        <asp:CalendarExtender ID="CalendarExtender1" runat="server" Enabled="True" TargetControlID="txtStartENV"></asp:CalendarExtender>
        <br />
        End:
        <asp:TextBox ID="txtEndENV" runat="server" DefaultValue="12pm"></asp:TextBox>
        <asp:CalendarExtender ID="CalendarExtender2" runat="server" Enabled="True" TargetControlID="txtEndENV"></asp:CalendarExtender>
        <br />
        Report Based On #: <asp:DropDownList ID="ddlReportBasedOn" runat="server">
            <asp:ListItem Value="1" Text="Batches" Selected="True"/>
            <asp:ListItem Value="2" Text="Units" Selected="False"/>
        </asp:DropDownList>
        <br />
        Test Centers: <asp:DropDownList ID="ddlTestCentersENV" runat="server" AppendDataBoundItems="True" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        <br /><br />
        <h4>If you cannot see the paperclip or the counts don't match it is because the units that were done at that item were not scanned in using automation. Test Records were manually done.</h4>
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlSearchResults">
        <asp:UpdatePanel ID="updResults" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="chkShowOnlyFailValue" EventName="CheckedChanged" />
                <asp:AsyncPostBackTrigger ControlID="chkJobsRQ" />
                <asp:AsyncPostBackTrigger ControlID="chkStagesRQ" />
                <asp:AsyncPostBackTrigger ControlID="ddlTestsResults" />
                <asp:AsyncPostBackTrigger ControlID="ddlMeasurementType" />
                <asp:AsyncPostBackTrigger ControlID="ddlParameter" />
                <asp:AsyncPostBackTrigger ControlID="ddlParameterValue" />
            </Triggers>
            <ContentTemplate>
                <br />
                Test Center: <asp:DropDownList ID="ddlTestCenterRQ" runat="server" AppendDataBoundItems="false" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
                <br />
                <asp:CheckBox runat="server" ID="chkShowOnlyFailValue" Text="Fail Options Only: " Checked="false" AutoPostBack="true" TextAlign="Left" />
                <br />

                <table cellpadding="0" cellspacing="0" border="0" class="removeStyleWithLeft">
                    <tr>
                        <td>
                            Product: <div style="OVERFLOW-Y:scroll; WIDTH:200px; HEIGHT:200px"><asp:CheckBoxList runat="server" ID="chkProductFilterRQ" CssClass="removeStyleWithLeft" RepeatDirection="Vertical" AutoPostBack="false" Width="239px" AppendDataBoundItems="true" DataTextField="ProductGroupName" DataValueField="ID"></asp:CheckBoxList></div>
                        </td>
                        <td>
                            Jobs: <div style="OVERFLOW-Y:scroll; WIDTH:300px; HEIGHT:200px"><asp:CheckBoxList runat="server" ID="chkJobsRQ" CssClass="removeStyleWithLeft" RepeatDirection="Vertical" AutoPostBack="true" Width="239px" AppendDataBoundItems="true" DataValueField="ID" DataTextField="Name"></asp:CheckBoxList></div>
                        </td>
                        <td>
                            Stages: <div style="OVERFLOW-Y:scroll; WIDTH:300px; HEIGHT:200px"><asp:CheckBoxList runat="server" ID="chkStagesRQ" CssClass="removeStyleWithLeft" RepeatDirection="Vertical" AutoPostBack="true" Width="239px" AppendDataBoundItems="true" DataValueField="ID" DataTextField="Name"></asp:CheckBoxList></div>
                        </td>
                    </tr>
                </table>
                <br />
                Test Name:
                <asp:DropDownList ID="ddlTestsResults" runat="server" DataTextField="Name" DataValueField="ID" AutoPostBack="true" style="width:150px;" CausesValidation="true" AppendDataBoundItems="true">
                    <asp:ListItem Selected="True" Text="Select A Test" Value="0"></asp:ListItem>
                </asp:DropDownList>
                <br />
                Measurements: 
                <asp:DropDownList runat="server" style="width:150px;" ID="ddlMeasurementType" Visible="true" CausesValidation="true" AutoPostBack="true" DataTextField="Measurement" AppendDataBoundItems="true" DataValueField="MeasurementTypeID">
                    <asp:ListItem Selected="True" Text="Select A Measurement" Value="0"></asp:ListItem>
                </asp:DropDownList>
                <br />
                Parameter:
                <asp:DropDownList runat="server" style="width:150px;" ID="ddlParameter" Visible="true" CausesValidation="true" AutoPostBack="true" DataTextField="ParameterName" AppendDataBoundItems="true" DataValueField="ParameterName">
                    <asp:ListItem Selected="True" Text="Select A Parameter" Value="0"></asp:ListItem>
                </asp:DropDownList>
                <br />
                Parameter Value:
                <asp:DropDownList runat="server" ID="ddlParameterValue" style="width:150px;" Visible="true" CausesValidation="true" AutoPostBack="false" DataTextField="ParameterName" AppendDataBoundItems="true" DataValueField="ParameterName">
                    <asp:ListItem Selected="True" Text="Select A Value" Value="0"></asp:ListItem>
                </asp:DropDownList>

                <asp:UpdateProgress ID="upResults" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updResults">
                    <ProgressTemplate>
                        <div class="LoadingModal"></div>
                        <div class="LoadingGif"></div>
                    </ProgressTemplate>
                </asp:UpdateProgress>
            </ContentTemplate>
        </asp:UpdatePanel>
        <br /><br />
    </asp:Panel>

    <asp:Panel Visible="false" runat="server" ID="pnlKPI">
        Start: <asp:TextBox ID="txtStartKPI" runat="server" DefaultValue="12am"></asp:TextBox>
        <asp:CalendarExtender ID="CalendarExtender3" runat="server" Enabled="True" TargetControlID="txtStartKPI"></asp:CalendarExtender>
        <br />
        End: <asp:TextBox ID="txtEndKPI" runat="server" DefaultValue="12pm"></asp:TextBox>
        <asp:CalendarExtender ID="CalendarExtender4" runat="server" Enabled="True" TargetControlID="txtEndKPI"></asp:CalendarExtender>
        <br />
        Test Centers: <asp:DropDownList ID="ddlTestCenterKPI" runat="server" AppendDataBoundItems="True" Width="120px" ForeColor="#0033CC" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
        <br />
        Type: <asp:DropDownList runat="server" ID="ddlKPIType" Width="120px">
            <asp:ListItem Selected="true" Text="Incoming Loss" Value="1" />
        </asp:DropDownList>
        <br /><br />
    </asp:Panel>
    
    <asp:UpdatePanel ID="updProcessing" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="btnSearching" />
            <asp:PostBackTrigger ControlID="lnkExportAction" />
        </Triggers>
        <ContentTemplate>
            <script type="text/javascript">
                var prm = Sys.WebForms.PageRequestManager.getInstance();
                prm.add_pageLoaded(EndRequestOverall);

                function EndRequestOverall(sender, args) {
                    if (prm._postBackSettings != null) {
                        if (prm._postBackSettings.sourceElement.id == 'ctl00_Content_btnSearching') {
                            $('table#ctl00_Content_bscMain_grdBatches').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                excludeColumns: [16, 17, 18],
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });

                            $('table#ctl00_Content_gvwTestExceptions').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                excludeColumns: [13, 14],
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });

                            $('table#ctl00_Content_gvwRQResultsTrend').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                excludeColumns: [9],
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });

                            $('table#ctl00_Content_gvwUsers').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                excludeColumns: [1],
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });

                            $('table#ctl00_Content_gvwKPI').columnFilters(
                            {
                                caseSensitive: false,
                                underline: true,
                                wildCard: '*',
                                alternateRowClassNames: ['evenrow', 'oddrow']
                            });
                        }
                    }
                }
            </script>

            <asp:Button ID="btnSearching" Text="Search" CssClass="buttonSmall" runat="server" OnClick="btn_OnClick" />
            <asp:Button ID="lnkExportAction" runat="Server" Text="Export Result" EnableViewState="false" Enabled="true" CssClass="buttonSmall"  />
            <uc1:Notifications ID="notMain" runat="server" Visible="true" EnableViewState="true" />
                        
            <asp:GridView ID="gvwTraining" runat="server" Visible="false" AutoGenerateColumns="true" EnableViewState="true" EmptyDataText="No Users Training Data Available">
                <HeaderStyle CssClass="slantHeader" />
            </asp:GridView>

            <asp:GridView ID="gvwUsers" runat="server" Visible="false" AutoGenerateColumns="false" EnableViewState="true" EmptyDataText="No Users Data Available" DataKeyNames="ID">
                <Columns>
                    <asp:TemplateField ShowHeader="True" HeaderText="UserName">
                        <ItemTemplate>
                            <asp:HyperLink ID="hplUser" runat="server" Text='<%# Eval("LDAPLogin") %>'></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField ShowHeader="True" HeaderText="Edit User">
                        <ItemTemplate>
                            <asp:HyperLink ID="hplAdmin" runat="server" Text='Edit'></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>

            <asp:GridView runat="server" ID="gvwENVReport" Visible="false" AutoGenerateColumns="True" EmptyDataText="No Data Available" EnableViewState="True">
            </asp:GridView>

            <asp:GridView ID="gvwRQResultsTrend" runat="server" Visible="false" AutoGenerateColumns="false" DataKeyNames="" EmptyDataText="No Data Available" EnableViewState="True">
                <Columns>
                    <asp:TemplateField HeaderText="Request">
                        <ItemTemplate>
                            <asp:HyperLink EnableViewState="false" ID="hypQRANumber" runat="server" NavigateUrl='<%# "/ScanForInfo/Default.aspx?QRA=" + Eval("QRANumber") %>'
                            Text='<%# Eval("QRANumber") %>' ToolTip='<%# "Click to view the information page for this batch" %>' Target="_blank"></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit Number" />
                    <asp:TemplateField HeaderText="Product">
                        <ItemTemplate>
                            <asp:HyperLink EnableViewState="false" ID="hypproduct" runat="server" NavigateUrl='<%# "/ScanForInfo/productgroup.aspx?Name=" + Eval("ProductID").ToString() %>'
                            Text='<%# Eval("ProductGroupName") %>' ToolTip='<%# "Click to view the information page for this Product" %>' Target="_blank"></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="TestCenter" HeaderText="Test Center" />
                    <asp:BoundField DataField="JobName" HeaderText="Job" />
                    <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" />
                    <asp:BoundField DataField="MeasurementName" HeaderText="Measurement" />
                    <asp:BoundField DataField="MeasurementValue" HeaderText="Measured Value" />
                    <asp:BoundField DataField="DegradationVal" HeaderText="Degradation" />
                    <asp:BoundField DataField="LowerLimit" HeaderText="Lower Limit" />
                    <asp:BoundField DataField="UpperLimit" HeaderText="Upper Limit" />
                    <asp:BoundField DataField="PassFail" HeaderText="Pass / Fail" />
                    <asp:BoundField DataField="Params" HeaderText="Parameters" />
                    <asp:TemplateField HeaderText="View">
                        <ItemTemplate>
                            <asp:HyperLink EnableViewState="false" ID="hypViewResults" runat="server" NavigateUrl='<%# "/Relab/Measurements.aspx?ID=" + Eval("ResultID").ToString() + "&Batch=" + Eval("BatchID").ToString() %>'
                            Text="View" ToolTip='<%# "Click to view the measurements for this." %>' Target="_blank"></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            
            <asp:GridView ID="gvwKPI" Visible="false" runat="server" AutoGenerateColumns="true" EmptyDataText="No Data Available" EnableViewState="True">
            </asp:GridView>
            
            <asp:GridView ID="gvwTestExceptions" Visible="false" runat="server" AutoGenerateColumns="False" DataKeyNames="ID" EmptyDataText="No Exception Data Available" EnableViewState="True">
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
                    <asp:BoundField DataField="ReasonForRequest" HeaderText="ReasonForRequest" />
                    <asp:BoundField DataField="ID" HeaderText="ID" Visible="False" />
                    <asp:BoundField DataField="QRAnumber" HeaderText="Request" />
                    <asp:BoundField DataField="UnitNumber" HeaderText="Unit Number" />
                    <asp:BoundField DataField="JobName" HeaderText="Job" />
                    <asp:BoundField DataField="TestStageName" HeaderText="Test Stage" />
                    <asp:BoundField DataField="TestName" HeaderText="Test" />
                    <asp:BoundField DataField="IsMQual" HeaderText="IsMQual" />
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

            <asp:Label runat="server" ID="lblTopInfo" CssClass="InformationMessage" Visible="false" Text="<br/><br/>Displays Top 100 Batches Only!" />
            <uc3:BatchSelectControl ID="bscMain" Visible="false" runat="server" DisplayMode="SearchInfoDisplay" EnableViewState="false" EmptyDataText="No Batches Found. Please refine your search." />
                        
            <asp:GridView runat="server" Visible="false" ID="gvwUnits" AutoGenerateColumns="false" EnableViewState="true" EmptyDataText="No Units Match">
                <Columns>
                    <asp:TemplateField HeaderText="Request">
                        <ItemTemplate>
                            <asp:HyperLink EnableViewState="false" ID="hypQRANumber" runat="server" NavigateUrl='<%# "/ScanForInfo/Default.aspx?QRA=" + Eval("QRANumber") %>'
                            Text='<%# Eval("QRANumber") %>' ToolTip='<%# "Click to view the information page for this batch" %>' Target="_blank"></asp:HyperLink>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="BatchUnitNumber" HeaderText="Unit" />
                </Columns>
            </asp:GridView>

            <asp:UpdateProgress ID="upProcessing" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updProcessing">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>
        </ContentTemplate>
    </asp:UpdatePanel>
    <br /><br />

    <asp:ObjectDataSource ID="odsTraining" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
        <SelectParameters>
            <asp:Parameter Type="Int32" Name="Type" DefaultValue="5" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>
    
    <asp:ObjectDataSource ID="odsTrainingLevel" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
        <SelectParameters>
            <asp:Parameter Type="Int32" Name="Type" DefaultValue="6" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <asp:ObjectDataSource ID="odsTests" runat="server" SelectMethod="GetTestsByType" TypeName="Remi.Bll.TestManager" OldValuesParameterFormatString="original_{0}">
        <SelectParameters>
            <asp:Parameter Type="Int32" Name="Type" DefaultValue="1" />
            <asp:Parameter Type="Boolean" Name="includeArchived" DefaultValue="False" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <asp:ObjectDataSource ID="odsJobs" runat="server" SelectMethod="GetJobList" TypeName="Remi.Bll.JobManager" OldValuesParameterFormatString="original_{0}"></asp:ObjectDataSource>
        
    <asp:ObjectDataSource ID="odsTestCenters" runat="server" SelectMethod="GetLookups" TypeName="Remi.Bll.LookupsManager" OldValuesParameterFormatString="original_{0}">
        <SelectParameters>
            <asp:Parameter Type="Int32" Name="Type" DefaultValue="4" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>