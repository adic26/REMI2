<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Scanning_Default" CodeBehind="Default.aspx.vb" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Src="../Controls/ScanIndicator.ascx" TagName="ScanIndicator" TagPrefix="uc2" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Device Tracking Scan</h1>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <h3>Filter</h3>
    <ul>
        <li>
            <asp:Image ImageUrl="../Design/Icons/png/24x24/globe.png" ID="imgDepartmentView" runat="server" />
            <asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID" OnSelectedIndexChanged="ddlRequestType_SelectedIndexChanged"></asp:DropDownList>
        </li>
    </ul>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <uc1:NotificationList ID="notMain" runat="server" />
    <asp:Panel ID="pnlLocationDetails" runat="server">
        <h2>
            <asp:Label ID="lblLocationDetailsTitle" runat="server" Text=""></asp:Label></h2>
        <table>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Select Job (If Applicable):
                </td>
                <td>
                    <asp:DropDownList ID="ddlJobs" runat="server" AppendDataBoundItems="False" AutoPostBack="True" DataTextField="Name" DataValueField="Name" Width="305px"></asp:DropDownList>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Select Test Stage (If Applicable):
                </td>
                <td>
                    <asp:DropDownList ID="ddlTestStage" runat="server" AppendDataBoundItems="True" DataSourceID="odsTestStages"
                        Width="305px">
                        <asp:ListItem>Not Applicable</asp:ListItem>
                    </asp:DropDownList>
                    <asp:ObjectDataSource ID="odsTestStages" runat="server" DataObjectTypeName="REMI.BusinessEntities.TestStage"
                        DeleteMethod="DeleteTestStage" InsertMethod="SaveTestStage" OldValuesParameterFormatString="original_{0}"
                        SelectMethod="GetListOfNamesForChambers" TypeName="REMI.Bll.TestStageManager">
                        <DeleteParameters>
                            <asp:Parameter Name="ID" Type="Int32" />
                        </DeleteParameters>
                        <SelectParameters>
                            <asp:ControlParameter ControlID="ddlJobs" Name="jobName" PropertyName="SelectedValue" Type="String" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
            <tr>
                <td class="HorizTableFirstcolumn">
                    Select Location (If Applicable):
                </td>
                <td>
                    <asp:DropDownList ID="ddlPossibleLocations" runat="server" AppendDataBoundItems="True"
                        DataSourceID="odsLocations" Width="305px" AutoPostBack="true" DataTextField="DisplayName" DataValueField="BarcodePrefix">
                    </asp:DropDownList>
                    <asp:ObjectDataSource EnableCaching="true" CacheDuration="20" ID="odsLocations" runat="server"
                        OldValuesParameterFormatString="{0}" SelectMethod="GetTrackingLocationsByHostName" TypeName="REMI.Bll.TrackingLocationManager">
                        <SelectParameters>
                            <asp:ControlParameter ControlID="hdnHostName" Name="HostName" PropertyName="Value" Type="String" />
                            <asp:Parameter DefaultValue="" Name="trackingLocationType" Type="String" />
                            <asp:Parameter DefaultValue="0" Name="onlyActive" Type="Int32" />
                            <asp:Parameter DefaultValue="1" Name="showHostsNamedAll" Type="Int32" />
                            <asp:Parameter DefaultValue="0" Name="testCenter" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </td>
            </tr>
        </table>
    </asp:Panel>
    <br />
    <p>Use the area below to scan unit(s) out to your name. Once the unit is in your name the device will be considered with you until you scan back into the system.</p>
    <uc2:ScanIndicator ID="sciTracking" runat="server" />
    <p>
        <asp:CheckBox runat="server" Visible="true" ID="chkPick" Text="REMSTAR PICK" /><br />
        <asp:TextBox ID="IESubmitBugRemedy_DoNotRemove" runat="server" Style="visibility:hidden;display: none;" />
        <img alt="Scan Barcode into text box" class="ScanDeviceImage" src="../Design/Icons/png/48x48/barcode.png" />&nbsp;
        <asp:TextBox ID="txtBarcodeReading" runat="server" CssClass="ScanDeviceTextEntryHint" CausesValidation="true" value="Enter Request Number..." onfocus="if (this.value == 'Enter Request Number...') if (this.className=='ScanDeviceTextEntryHint') { this.className = 'ScanDeviceTextEntry'; this.value = ''; }" onblur="if (this.value == '') { this.className = 'ScanDeviceTextEntryHint'; this.value = 'Enter Request Number...'; }"></asp:TextBox>
        <asp:DropDownList runat="server" ID="ddlBinType" DataTextField="BinName" DataValueField="BinName" Visible="false"></asp:DropDownList>
        
        <asp:Button ID="btnSubmit" runat="server"  Text="Submit" Visible="true" />
        <asp:Button ID="btnCancel" runat="server" Text="Clear" Visible="true" />

        <asp:CheckBoxList ID="cblUnit" runat="server" Width="100px" AppendDataBoundItems="true" CssClass="RemoveBorder" AutoPostBack="false" Visible="false" RepeatDirection="Vertical">
        </asp:CheckBoxList>
        <asp:CustomValidator ID="valBarCode" runat="server" Display="Static" ControlToValidate="txtBarcodeReading" OnServerValidate="BarCodeValidation" ErrorMessage="BarCode Must be in this format QRA-##-####-###" ValidateEmptyText="true"></asp:CustomValidator>
    </p>
    <br />
    <asp:HiddenField ID="hdnHostname" runat="server" Value="" />
    <asp:HiddenField ID="hdnUserLocation" runat="server" Value="" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>