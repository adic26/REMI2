<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.TestRecords_Add" Title="Add Test Record" CodeBehind="Add.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1>
        <asp:Label ID="lblTitle" runat="server" Text="Add Test Record"></asp:Label>
    </h1>
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
        <table>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Unit:
                </td>
                <td class="HorizTableSecondColumn">
                    <div style="width: 200px; height: 100px; overflow: auto">
                        <asp:CheckBoxList ID="cblUnit" runat="server" Width="100px" AppendDataBoundItems="true" AutoPostBack="true"
                            RepeatDirection="Vertical" DataTextField="BatchUnitNumber" DataValueField="ID">
                        </asp:CheckBoxList>
                    </div>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Job:
                </td>
                <td class="HorizTableSecondColumn">
                    <b>
                        <asp:Label ID="lblJobName" runat="server" Text="Label"></asp:Label>
                    </b>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Test Stage
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlTestStage" runat="server" Width="278px" AutoPostBack="True" DataTextField="value" DataValueField="key">
                    </asp:DropDownList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Test:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlTest" runat="server" Width="277px" AutoPostBack="true" DataTextField="value" DataValueField="key" AppendDataBoundItems="true">
                        <asp:ListItem Selected="True" Text="" Value="" />
                    </asp:DropDownList>
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
                    Record Status:
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:DropDownList ID="ddlResultStatus" runat="server" Width="277px" DataSourceID="odsResultStatus"
                        DataTextField="Text" DataValueField="Value" AutoPostBack="True">
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsResultStatus" runat="server" SelectMethod="GetTestRecordStatusList"
                        TypeName="Remi.BusinessEntities.Helpers" OldValuesParameterFormatString="{0}"></asp:ObjectDataSource>
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
                    &nbsp;
                </td>
                <td class="HorizTableSecondColumn">
                    <asp:Button ID="btnDetailDone" runat="server" Text="Done" CssClass="button" />
                    <asp:Button ID="btnDetailCancel" runat="server" Text="Cancel" CssClass="button" />
                    <asp:HiddenField ID="hdnTestRecordLink" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnQRANumber" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnBatchID" runat="server" Value="0" />
                    <asp:HiddenField ID="hdnTRID" runat="server" Value="0" />
                    <br />
                </td>
            </tr>
        </table>
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlRelabMatrix" Visible="false">
        <h3>SFI Functional Test Results Measurements</h3>
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