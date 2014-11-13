<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.TestRecords_EditDetail" Title="Untitled Page" Codebehind="EditDetail.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>Edit Test Record</h1>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="leftSidebarContent" runat="Server">
    <script type="text/javascript">
        function uncheck(id) {
            document.getElementById(id).checked = false;
        }    
    </script>
    <h3>View</h3>
    <ul>
        <li id="li" runat="server">
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="imgTestRecords" runat="server" />
            <asp:HyperLink ID="hypTestRecords" runat="server" ToolTip="Click to view the test records for this batch">All Test Records</asp:HyperLink>
        </li>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/link.png" ID="Image1" runat="server" />
            <asp:HyperLink ID="hypBatchInfo" runat="Server" Text="Batch Info" ToolTip="Click to return to batch info" />
        </li>
        
    </ul>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <asp:Panel ID="pnlDetails" runat="server" Style="width: 1200px">
        <table style="white-space:normal;">
            <tr>
                <td class="HorizTableFirstcolumn">
                    Record For:
                </td>
                <td class="HorizTableSecondColumn">
                    <b>
                        <asp:Label ID="lblResultText" runat="server" Text="Label"></asp:Label></b>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Comment:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:TextBox ID="txtComment" runat="server" Height="111px" TextMode="MultiLine" Width="401px"></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Tracking Logs:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView ID="grdTrackingLog" runat="server" AutoGenerateColumns="False" DataSourceID="odsTrackingLogs"
                        EmptyDataText="No tracking logs available for this test record.">
                        <RowStyle CssClass="evenrow" />
                        <Columns>
                            <asp:BoundField DataField="ID" HeaderText="ID" InsertVisible="False" ReadOnly="True"
                                SortExpression="ID" Visible="False" />
                            <asp:TemplateField HeaderText="Location" SortExpression="TrackingLocation">
                                <ItemTemplate>
                                    <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("TrackingLocationLink") %>'
                                        Text='<%# Eval("TrackingLocationName") %>'></asp:HyperLink>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Logged In" SortExpression="InTime">
                                <ItemTemplate>
                                    <asp:Label ID="Label2" runat="server" Text='<%# Remi.Helpers.DateTimeFormat(Eval("InTime")) %>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Logged In By" SortExpression="InUser">
                                <ItemTemplate>
                                    <asp:Label ID="Label3" runat="server" Text='<%# Remi.Helpers.UserNameFormat(Eval("InUser")) %>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Logged Out" SortExpression="OutTime">
                                <ItemTemplate>
                                    <asp:Label ID="Label4" runat="server" Text='<%# Remi.Helpers.DateTimeformat(Eval("OutTime")) %>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Logged Out By" SortExpression="OutUser">
                                <ItemTemplate>
                                    <asp:Label ID="Label5" runat="server" Text='<%# Remi.Helpers.UserNameFormat(Eval("OutUser")) %>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <AlternatingRowStyle CssClass="oddrow" />
                    </asp:GridView>
                    <asp:ObjectDataSource ID="odsTrackingLogs" runat="server" SelectMethod="GetTrackingLogsForTestRecord"
                        TypeName="REMI.Bll.TrackingLogManager">
                        <SelectParameters>
                            <asp:Parameter Name="trID" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    ReTested Count:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:Label ID="lblReTestCount" runat="server"></asp:Label></b>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Record Status:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlResultStatus" runat="server" Width="277px" DataSourceID="odsResultStatus"
                        DataTextField="Text" DataValueField="Value" AutoPostBack="True">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsResultStatus" runat="server" SelectMethod="GetTestRecordStatusList"
                        TypeName="Remi.Helpers" OldValuesParameterFormatString="{0}"></asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    MFI/SFI/Accessory:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:RadioButtonList runat="server" ID="rblMFISFIAcc" RepeatDirection="Horizontal" RepeatLayout="Flow" Enabled="false" AutoPostBack="true">
                        <asp:ListItem Text="SFI" Value="1" />
                        <asp:ListItem Text="MFI" Value="2" />
                        <asp:ListItem Text="Accessory" Value="3" />
                    </asp:RadioButtonList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Assigned Cater Items:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:Repeater ID="rptDocList" runat="server">
                        <ItemTemplate>
                           <asp:HyperLink ID="hypDocumentName" runat="server" NavigateUrl='<%# DataBinder.Eval(Container.DataItem, "RequestLink")%>'
                                Target="_blank" Text='<%# DataBinder.Eval(Container.DataItem, "RequestNumber")%>'
                                ToolTip="Click to view the full document details" />
                           <asp:Button  ID="lnkRemoveFailDocument" runat="server"  Font-Size="XX-Small" CssClass="button"  Width="15px" Height="15px" CommandArgument='<%# DataBinder.Eval(Container.DataItem, "RequestNumber")%>' Text="Remove"></asp:Button>
                            <br />
                        </ItemTemplate>
                    </asp:Repeater>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Cater Item Selection:
                </td>
                <td class="HorizTableSecondColumn" style="white-space:normal;">
       
                 <asp:DataList ID="rptFAList" runat="server" BorderStyle="None" RepeatColumns="2" DataKeyField="requestnumber" 
                        BorderWidth="0">
                        <ItemTemplate>
                            <asp:HyperLink ID="hypDocumentName" runat="server" NavigateUrl='<%# DataBinder.Eval(Container.DataItem, "RequestLink")%>'
                                Target="_blank" Text='<%# DataBinder.Eval(Container.DataItem, "RequestNumber")%>'
                                ToolTip="Click to view the full document details" />
                            <br />
                            <asp:Label ID="lblSummary" runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "Summary")%>'></asp:Label>
                            <br />
                            <asp:Button ID="btnAssign" runat="server" Font-Size="X-Small"  Text="Assign" CssClass="button"
                                Width="44px" Height="25px"/>
                        </ItemTemplate>
                        <ItemStyle Width="250px" CssClass="faListItem" />
                    </asp:DataList>
                    OR enter other Cater document number:&nbsp;<asp:TextBox ID="txtAssignAnyFailDoc" runat="server"
                        Width="142px"></asp:TextBox><asp:Button ID="btnAssignAnyFailDoc" Width="44px" Height="20px" Font-Size="XX-Small" runat="server" Text="Assign" cssclass="button"/>
                    <br />
                    <asp:HyperLink ID="hypAddNewFA" runat="server" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rtId=40"
                        Visible="False">New FA</asp:HyperLink>
                    &nbsp;<asp:HyperLink ID="hypAddNewRIT" runat="server" Visible="False" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rtId=96">New RIT</asp:HyperLink><asp:HyperLink
                        ID="hypAddNewSCM" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rtId=55"
                        runat="server" Visible="False">New SCM</asp:HyperLink></td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Apply to similar records:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:CheckBox ID="chkApplyToSimilarResults" runat="server" />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    &nbsp;
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:Button ID="btnDetailDone" runat="server" Text="Done" CssClass="button" />
                    <asp:Button ID="btnDetailCancel" runat="server" Text="Cancel" CssClass="button" />
                    <asp:HiddenField ID="hdnTestRecordLink" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnQRANumber" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnBatchID" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnproductGroup" runat="server" Value="0" Visible="False" />
                    <asp:HiddenField ID="hdnTRID" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnTestID" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnTestStageID" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnUnitID" runat="server" Value="0" />
                    <br />
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Audit Logs
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:GridView ID="grdAuditLog" runat="server" DataSourceID="odsAuditLog" AutoGenerateColumns="True" EnableViewState="False" EmptyDataText="No Audit Logs Yet.">
                        <Columns>
                        </Columns>
                    </asp:GridView>
                    <asp:ObjectDataSource ID="odsAuditLog" runat="server" SelectMethod="GetTestRecordAuditLogs" TypeName="REMI.Bll.TestRecordManager">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="hdnTRID" DefaultValue="-1" Name="TestRecordID" PropertyName="Value" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
        </table>
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlRelabMatrix" Visible="false">
        <h3>Functional Results Measurements</h3>
        <asp:GridView ID="gvwRelabMatrix" AutoGenerateColumns="true" runat="server" CssClass="VerticalTable" EnableViewState="True" DataKeyNames="TestUnitID">
            <RowStyle CssClass="evenrow" />
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
    </asp:Panel>
    <br />
    <br />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>
