<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ES_Default" Codebehind="default.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="server"></asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" Runat="Server">
    <asp:AlwaysVisibleControlExtender runat="server" ID="ave" TargetControlID="pnlHeader" UseAnimation="true" VerticalOffset="100"></asp:AlwaysVisibleControlExtender>

    <asp:Label runat="server" ID="lblPH" Text="&nbsp;" style=""></asp:Label>
    <asp:Panel runat="server" ID="pnlHeader" CssClass="ScrollMenu">
        <asp:Menu ID="ESMenu" RenderingMode="Table" runat="server" OnMenuItemClick="ESMenu_MenuItemClick" Width="85" Orientation="Horizontal" CssClass="MenuESHeader" EnableViewState="true" StaticEnableDefaultPopOutImage="false" DynamicEnableDefaultPopOutImage="false" BorderStyle="None" BorderWidth="0">
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
                </asp:MenuItem>
            </Items>
        </asp:Menu>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeRequestInfo" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" ImageControlID="imgExpCol" TargetControlID="pnlRequestInfo" ExpandedSize="600" TextLabelID="lblText" CollapsedSize="0" Collapsed="true" ScrollContents="true" CollapseControlID="pnlRequestInfoHeader" ExpandControlID="pnlRequestInfoHeader"></asp:CollapsiblePanelExtender>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeRequestSummary" CollapseControlID="pnlRequestSummaryHeader" TargetControlID="pnlRequestSummary" TextLabelID="lblSummary" ExpandControlID="pnlRequestSummaryHeader" ImageControlID="imgRequestSummaryExpCol" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" Collapsed="false" CollapsedSize="0" ScrollContents="false"></asp:CollapsiblePanelExtender>
    <asp:CollapsiblePanelExtender runat="server" ID="cpeFA" CollapsedImage="..\..\Design\Icons\png\24x24\green_arrow_down.png" ExpandedImage="..\..\Design\Icons\png\24x24\green_arrow_up.png" ImageControlID="imgFA" TargetControlID="pnlFAInfo" TextLabelID="lblFA" CollapsedSize="0" Collapsed="true" ScrollContents="true" CollapseControlID="pnlFA" ExpandControlID="pnlFA"></asp:CollapsiblePanelExtender>
   
    <asp:HiddenField ID="hdnBatchID" runat="server" />
    <asp:HiddenField ID="hdnRequestNumber" Value="" runat="server" />
    
    <a name="top"></a>
    <asp:Label runat="server" ID="lblRequestNumber" CssClass="RequestNumber" ></asp:Label>
    <br /><br /><br />
    <asp:Panel runat="server" ID="pnlES" CssClass="CollapseHeader" style="cursor:none;">
        <table class="TableNoBorders" width="100%">
            <tr>
                <td width="50%">
                    <asp:Label runat="server" ID="lblES" Text="Executive<br/><font color='rgb(0,124,186)'>Summary</font>" style="font: bold 28px auto Trebuchet MS, Sans-Serif;"></asp:Label>
                </td>
                <td width="50%">
                    <asp:Label runat="server" ID="lblResult"></asp:Label>
                    <asp:DropDownList runat="server" ID="ddlStatus" Visible="true" OnSelectedIndexChanged="ddlStatus_SelectedIndexChanged" AutoPostBack="true">
                        <asp:ListItem Text="Pass" Value="1" />
                        <asp:ListItem Text="Fail" Value="2" />
                        <asp:ListItem Text="No Result" Value="3" />
                    </asp:DropDownList>
                </td>
            </tr>
        </table><br />
        <asp:Label runat="server" ID="lblESText" style="font-size:19px;font-weight: normal;word-wrap: normal;word-break:break-all;width:100%" ></asp:Label>
    </asp:Panel>
    <br /><br />

    <a name="requestSummary"></a>
    <asp:Panel ID="pnlRequestSummaryHeader" runat="server" CssClass="CollapseHeader" Height="75">
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
        <br />
        <asp:GridView runat="server" ID="grdApproval" AutoGenerateColumns="true" EmptyDataText="No Approvals"></asp:GridView>
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

    <a name="fa"></a>
    <asp:Panel ID="pnlFA" runat="server" CssClass="CollapseHeader" Height="75" HorizontalAlign="Left" Visible="false">
        <asp:Label ID="lblFA" runat="server" Text="Failure<br/><font color='rgb(0,124,186)'>Analysis</font>" /><asp:Image runat="server" ID="imgFA" />
    </asp:Panel>
     <asp:Panel runat="server" ID="pnlFAInfo" CssClass="CollapseBody">

     </asp:Panel>


<asp:Panel runat="server" ID="pnlFailures" Visible="false"><b>Failure(s) Analysis:</b><br /></asp:Panel>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>