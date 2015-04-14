<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="true" EnableEventValidation="false" MaintainScrollPositionOnPostback="true" AutoEventWireup="true" Inherits="Remi.ES_Default" Codebehind="default.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<%@ Register Src="~/Controls/Measurements.ascx" TagName="Measurements" TagPrefix="msm" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server"></asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <asp:Label runat="server" ID="lblPH" Text="&nbsp;" style=""></asp:Label>
    <asp:Panel runat="server" ID="pnlHeader" CssClass="ScrollMenu">
        <asp:Menu ID="ESMenu" RenderingMode="Table" runat="server" Width="85" Orientation="Horizontal" CssClass="MenuESHeader" EnableViewState="true" StaticEnableDefaultPopOutImage="false" DynamicEnableDefaultPopOutImage="false" BorderStyle="None" BorderWidth="0">
            <LevelMenuItemStyles>
                <asp:MenuItemStyle CssClass="MenuESItem" />
                <asp:MenuItemStyle CssClass="MenuESItem" />
                <asp:MenuItemStyle CssClass="MenuESItem" />
            </LevelMenuItemStyles>
            <DynamicHoverStyle BackColor="Black" ForeColor="White" />
            <Items>
                <asp:MenuItem ImageUrl="..\..\Design\Icons\menu.png" Text="">
                    <asp:MenuItem Text="Back To Top" NavigateUrl="#top"></asp:MenuItem>
                    <asp:MenuItem Text="Request Summary" NavigateUrl="#requestSummary"></asp:MenuItem>
                    <asp:MenuItem Text="Request" NavigateUrl="#request"></asp:MenuItem>
                    <asp:MenuItem Text="Approvals" NavigateUrl="#approve"></asp:MenuItem>
                    <asp:MenuItem Text="Result Summary" NavigateUrl="#resultSummary"></asp:MenuItem>
                    <asp:MenuItem Text="Result BreakDown" NavigateUrl="#resultBreakdown"></asp:MenuItem>
                </asp:MenuItem>
            </Items>
        </asp:Menu>
    </asp:Panel>
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="Content" runat="Server">
    <a class="test-popup-link" visible="false">popup</a> 
    <div id="my-popup" class="mfp-hide white-popup">Inline popup</div>    

    <asp:HiddenField ID="hdnBatchID" runat="server" />
    <asp:HiddenField ID="hdnRequestNumber" Value="" runat="server" />
         
    <asp:CollapsiblePanelExtender runat="server" ID="cpeRequestInfo" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" ImageControlID="imgExpCol" TargetControlID="pnlRequestInfo" TextLabelID="lblText" CollapsedSize="0" Collapsed="true" ScrollContents="true" CollapseControlID="pnlRequestInfoHeader" ExpandControlID="pnlRequestInfoHeader"></asp:CollapsiblePanelExtender>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeFA" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" ImageControlID="imgFA" TargetControlID="pnlFAInfo" TextLabelID="lblFA" CollapsedSize="0" Collapsed="true" ScrollContents="true" CollapseControlID="pnlFA" ExpandControlID="pnlFA"></asp:CollapsiblePanelExtender>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeRequestSummary" CollapseControlID="pnlRequestSummaryHeader" TargetControlID="pnlRequestSummary" TextLabelID="lblSummary" ExpandControlID="pnlRequestSummaryHeader" ImageControlID="imgRequestSummaryExpCol" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="false" CollapsedSize="1" ></asp:CollapsiblePanelExtender>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeApprovals" CollapseControlID="pnlApprovalHeader" TargetControlID="pnlApproval" TextLabelID="lblApprove" ExpandControlID="pnlApprovalHeader" ImageControlID="imgApprovals" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="true" CollapsedSize="0" ></asp:CollapsiblePanelExtender>
      
    <a name="top"></a>
    <asp:Label runat="server" ID="lblRequestNumber" CssClass="RequestNumber" ></asp:Label><br /><br />
    <asp:Label runat="server" ID="lblPrinted"></asp:Label>
    <br /><br /><br />
    <asp:Panel runat="server" ID="pnlES" CssClass="CollapseHeader" style="cursor:none;">
        <table class="TableNoBorders" width="100%">
            <tr>
                <td width="50%">
                    <asp:Label runat="server" ID="lblES" Text="Executive<br/><font color='rgb(0,124,186)'>Summary</font>" style="font: bold 28px auto Trebuchet MS, Sans-Serif;"></asp:Label>
                </td>
                <td width="50%">
                    <asp:Label runat="server" ID="lblResult"></asp:Label>
                    <asp:DropDownList runat="server" ID="ddlStatus" Visible="true" AutoPostBack="true">
                        <asp:ListItem Text="Pass" Value="1" />
                        <asp:ListItem Text="Fail" Value="2" />
                        <asp:ListItem Text="No Result" Value="3" />
                        <asp:ListItem Text="Preliminary Pass" Value="4" />
                        <asp:ListItem Text="Preliminary Fail" Value="5" />
                    </asp:DropDownList>
                </td>
            </tr>
        </table><br />
        <asp:Label runat="server" ID="lblESText" style="font-size:19px;font-weight: normal;word-wrap: normal;word-break:break-all;width:100%" ></asp:Label>
        <br />
        <asp:GridView runat="server" ID="grdJIRAS" ShowFooter="false" AutoGenerateColumns="false" AutoGenerateDeleteButton="false">
            <Columns>
                <asp:BoundField DataField="JIRAID" HeaderText="JIRAID" SortExpression="JIRAID" Visible="false" />
                <asp:BoundField DataField="BatchID" HeaderText="BatchID" SortExpression="BatchID" Visible="false" />
                <asp:TemplateField HeaderText="JIRA" SortExpression="">
                    <ItemTemplate>
                        <asp:HyperLink runat="server" ID="hypJIRA" Target="_blank" NavigateUrl='<%# Eval("Link") %>'><%# Eval("DisplayName")%> - <%# Eval("Title") %></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </asp:Panel>
    <br /><br />

    <a name="requestSummary"></a>
    <asp:Panel ID="pnlRequestSummaryHeader" runat="server" CssClass="CollapseHeader">
        <asp:Label runat="server" ID="lblSummary" Text="Request<br/><font color='rgb(0,124,186)'>Summary</font>"></asp:Label><asp:Image runat="server" ID="imgRequestSummaryExpCol" />
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlRequestSummary" CssClass="CollapseBody">
        <asp:HiddenField ID="hdnPartName" runat="server" />

        <asp:Repeater runat="server" ID="rptRequestSummary">
            <ItemTemplate>
                <table width="90%" class="TableNoBorders">
                    <tr>
                        <td>Product</td>
                        <td><%# Eval("ProductGroup") %></td>
                        <td>CPR</td>
                        <td><%# Eval("CPRNumber") %></td>
                    </tr>
                    <tr>
                        <td>Job</td>
                        <td><%# Eval("JobName") %></td>
                        <td>Department</td>
                        <td><%# Eval("Department")%></td>
                    </tr>
                    <tr>
                        <td># of Units</td>
                        <td><%# Eval("NumberOfUnits") %></td>
                        <td>Priority</td>
                        <td><%# Eval("Priority")%></td>
                    </tr>
                    <tr>
                        <td>Reason For Request</td>
                        <td><%# Eval("RequestPurpose") %></td>
                        <td>Part Name</td>
                        <td><%# PartName %></td>
                    </tr>
                    <tr>
                        <td>Product Type</td>
                        <td><%# Eval("ProductType") %></td>
                        <td>M Rev</td>
                        <td><%# Eval("MechanicalTools") %></td>
                    </tr>
                </table>
            </ItemTemplate>
        </asp:Repeater>
    </asp:Panel>
    <br /><br />

    <a name="request"></a>
    <asp:Panel ID="pnlRequestInfoHeader" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
        <asp:Label ID="lblText" runat="server" Text="Test<br/><font color='rgb(0,124,186)'>Request</font>" /><asp:Image runat="server" ID="imgExpCol" />
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlRequestInfo" CssClass="CollapseBody">
        <asp:GridView ID="gvwRequestInfo" runat="server" AutoGenerateColumns="false" ShowHeader="false" Width="600">
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
    </asp:Panel>
    <br /><br />

    <asp:UpdatePanel ID="updResultBreakdown" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="false" EnableViewState="true">
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="rboQRASlider" />
        </Triggers>
        <ContentTemplate>
            <asp:UpdateProgress runat="server" ID="upResultBreakdown" DynamicLayout="true" DisplayAfter="10" AssociatedUpdatePanelID="updResultBreakdown">
                <ProgressTemplate>
                    <div class="LoadingModal"></div>
                    <div class="LoadingGif"></div>
                </ProgressTemplate>
            </asp:UpdateProgress>
            <asp:CollapsiblePanelExtender runat="server" ID="cpeResultSummary" CollapseControlID="pnlResultSummaryHeader" TargetControlID="pnlResultSummary" TextLabelID="lblResultSummary" ExpandControlID="pnlResultSummaryHeader" ImageControlID="imgResultSummary" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="true" CollapsedSize="0" ></asp:CollapsiblePanelExtender>
            <asp:CollapsiblePanelExtender runat="server" ID="cpeResultBreakDown" CollapseControlID="pnlResultBreakdownHeader" TargetControlID="pnlResultBreakDown" TextLabelID="lblResultBreakDown" ExpandControlID="pnlResultBreakdownHeader" ImageControlID="imgResultBreakDown" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="true" CollapsedSize="0" ></asp:CollapsiblePanelExtender>     
            <asp:CollapsiblePanelExtender runat="server" ID="cpeObservations" CollapseControlID="pnlObservations" TargetControlID="pnlObservationsInfo" TextLabelID="lblbservations" ExpandControlID="pnlObservations" ImageControlID="imgObservations" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="true" CollapsedSize="0" ></asp:CollapsiblePanelExtender>     
            <asp:CollapsiblePanelExtender runat="server" ID="cpeObservationSummary" CollapseControlID="pnlObservationSummary" TargetControlID="pnlObservationSummaryInfo" TextLabelID="lblbservationSummary" ExpandControlID="pnlObservationSummary" ImageControlID="imgObservationSummary" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="true" CollapsedSize="0" ></asp:CollapsiblePanelExtender>     
    
            <asp:Panel runat="server" ID="pnlQRASlider" Visible="true" Height="" EnableViewState="true">
                <asp:RadioButtonList runat="server" AutoPostBack="true" CausesValidation="true" EnableViewState="true" ID="rboQRASlider" RepeatDirection="Horizontal" RepeatLayout="Flow"></asp:RadioButtonList>
                <br /><br />
            </asp:Panel>

            <a name="resultSummary"></a>
            <asp:Panel ID="pnlResultSummaryHeader" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
                <asp:Label ID="lblResultSummary" runat="server" Text="Results<br/><font color='rgb(0,124,186)'>Summary</font>" /><asp:Image runat="server" ID="imgResultSummary" />
            </asp:Panel>
            <asp:Panel runat="server" ID="pnlResultSummary" CssClass="CollapseBody">
                <asp:GridView ID="gvwResultSummary" DataSourceID="odsResultSummary" runat="server" AutoGenerateColumns="true" ShowHeader="true">
                </asp:GridView>
                <asp:ObjectDataSource ID="odsResultSummary" runat="server" SelectMethod="ESResultSummary" TypeName="REMI.Bll.ReportManager" OldValuesParameterFormatString="original_{0}">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="rboQRASlider" Name="batchID" PropertyName="SelectedValue" Type="Int32" />
                    </SelectParameters>
                </asp:ObjectDataSource>
            </asp:Panel>
            <br /><br />
        
            <a name="resultBreakdown"></a>
            <asp:Panel ID="pnlResultBreakdownHeader" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
                <asp:Label ID="lblResultBreakDown" runat="server" Text="Results<br/><font color='rgb(0,124,186)'>BreakDown</font>" /><asp:Image runat="server" ID="imgResultBreakDown" />
            </asp:Panel>
            <asp:Panel runat="server" ID="pnlResultBreakDown" CssClass="CollapseBody" EnableViewState="true">
                <script type="text/javascript">
                    $(document).on("click", "[src*=zoom_in]", function () {
                        $(this).closest("tr").after("<tr><td></td><td colspan = '999'>" + $(this).next().html() + "</td></tr>")
                        $(this).attr("src", "../../Design/Icons/png/16x16/zoom_out.png");
                    });

                    $(document).on("click", "[src*=zoom_out]", function () {
                        $(this).attr("src", "../../Design/Icons/png/16x16/zoom_in.png");
                        $(this).closest("tr").next().remove();
                    });
                </script>

                <asp:GridView ID="gvwResultBreakDown" runat="server" DataSourceID="odsResultBreakdown" EnableViewState="true" AutoGenerateColumns="false" DataKeyNames="ID" ShowHeader="true">
                    <Columns>
                        <asp:TemplateField>
                            <ItemTemplate>
                                <img alt = "" style="cursor: pointer" src="../../Design/Icons/png/16x16/zoom_in.png" id="imgadd" runat="server"  EnableViewState="true" />
                                <asp:Panel ID="pnlmeasureBreakdown" runat="server" Style="display: none"  EnableViewState="true">
                                    <msm:Measurements runat="server" ID="msmMeasuerments" Visible="false" EnableViewState="true" ShowExport="false" ShowFailsOnly="false" IncludeArchived="false" DisplayMode="ExecutiveSummaryDisplay" EmptyDataTextInformation="" EmptyDataTextMeasurement="There were no measurements found for this result." />
                                </asp:Panel>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="ID" HeaderText="ID" Visible="false" />
                        <asp:BoundField DataField="BatchUnitNUmber" HeaderText="BatchUnitNUmber" />
                        <asp:BoundField DataField="TestName" HeaderText="TestName" />
                        <asp:BoundField DataField="TestStageName" HeaderText="TestStageName" />
                        <asp:BoundField DataField="PassFail" HeaderText="Result" />
                    </Columns>
                </asp:GridView>
                <asp:ObjectDataSource ID="odsResultBreakdown" runat="server" SelectMethod="ResultSummary" TypeName="REMI.Bll.RelabManager" OldValuesParameterFormatString="original_{0}">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="rboQRASlider" Name="BatchID" PropertyName="SelectedValue" Type="Int32" />
                    </SelectParameters>
                </asp:ObjectDataSource>
            </asp:Panel>
            <br /><br />

            <a name="observationSummary"></a>
            <asp:Panel ID="pnlObservationSummary" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
                <asp:Label ID="lblbservationSummary" runat="server" Text="Observation<br/><font color='rgb(0,124,186)'>Summary</font>" /><asp:Image runat="server" ID="imgObservationSummary" />
            </asp:Panel>
            <asp:Panel runat="server" ID="pnlObservationSummaryInfo" CssClass="CollapseBody">
                <p>This report gives which drop the observation first occured at and gives a count of how many units had that observation.</p>
                <asp:GridView ID="gvwObservationSummary" runat="server" DataSourceID="odsObservations" OnDataBound="gvwObservationSummary_DataBound" EnableViewState="true" AutoGenerateColumns="true" ShowHeader="true">
                    <Columns>
                        <asp:BoundField DataField="Observation" HeaderText="Observation" ItemStyle-HorizontalAlign="Left" />
                    </Columns>
                </asp:GridView>
                <asp:ObjectDataSource ID="odsObservations" runat="server" SelectMethod="GetObservationSummary" TypeName="REMI.Bll.RelabManager" OldValuesParameterFormatString="original_{0}">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="rboQRASlider" Name="BatchID" PropertyName="SelectedValue" Type="Int32" />
                    </SelectParameters>
                </asp:ObjectDataSource>
            </asp:Panel>
            <br /><br />
        
            <a name="observations"></a>
            <asp:Panel ID="pnlObservations" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
                <asp:Label ID="lblbservations" runat="server" Text="Observations" /><asp:Image runat="server" ID="imgObservations" />
            </asp:Panel>
            <asp:Panel runat="server" ID="pnlObservationsInfo" CssClass="CollapseBody">
                <asp:GridView ID="gvwObservations" runat="server" EnableViewState="true" OnDataBound="gvwObservations_DataBound" DataSourceID="odsObservationInfo" AutoGenerateColumns="false" ShowHeader="true">
                    <Columns>
                        <asp:TemplateField HeaderText="Unit">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblUnit" Text='<%# Eval("BatchUnitNumber")%>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Total">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblMaxStage" Text='<%# Eval("MaxStage")%>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Stage">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblTestStage" Text='<%# Eval("TestStageName")%>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Observation" ItemStyle-HorizontalAlign="Left">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblObservation" Text='<%# Eval("Observation")%>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Orientation">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblOrientation" Text='<%# Eval("Orientation")%>' />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Notes" ItemStyle-HorizontalAlign="Left">
                            <ItemTemplate>
                                <asp:Label runat="server" Visible="true" ID="lblComment" Style="word-break: break-all; word-wrap: break-word;" Text='<%# Eval("Comment")%>' Width="600px" />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Attachment">
                            <ItemTemplate>
                                <asp:HiddenField runat="server" ID="hdnHasFiles" Value='<%# Eval("HasFiles") %>' />
                                <input type="image" src="../../Design/Icons/png/24x24/png_file.png" class="img-responsive" runat="server" visible="false" id='viewImages' mID='<%# Eval("MeasurementID") %>' pageID='<%# Me.ClientID %>' role="button" />
                            </ItemTemplate>
                        </asp:TemplateField>           
                    </Columns>
                </asp:GridView>
                <asp:ObjectDataSource ID="odsObservationInfo" runat="server" SelectMethod="GetObservations" TypeName="REMI.Bll.RelabManager" OldValuesParameterFormatString="original_{0}">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="rboQRASlider" Name="BatchID" PropertyName="SelectedValue" Type="Int32" />
                    </SelectParameters>
                </asp:ObjectDataSource>
            </asp:Panel>
        </ContentTemplate>
    </asp:UpdatePanel>
    
    <br /><br />
    <a name="fa"></a>
    <asp:Panel ID="pnlFA" runat="server" style="display:none;" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left">
        <asp:Label ID="lblFA" runat="server" Text="Failure<br/><font color='rgb(0,124,186)'>Analysis</font>" /><asp:Image runat="server" ID="imgFA" />
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlFAInfo" CssClass="CollapseBody">
        <asp:Panel runat="server" ID="pnlFailures" Visible="false"><b>Failure(s) Analysis:</b><br /></asp:Panel>
    </asp:Panel>
    <br /><br />
        
    <a name="approve"></a>
    <asp:Panel ID="pnlApprovalHeader" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left" Visible="true">
        <asp:Label ID="lblApprove" runat="server" Text="Approvals" /><asp:Image runat="server" ID="imgApprovals" />
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlApproval" CssClass="CollapseBody">
        <asp:GridView runat="server" ID="grdApproval" AutoGenerateColumns="true" EmptyDataText="No Approvals"></asp:GridView>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>