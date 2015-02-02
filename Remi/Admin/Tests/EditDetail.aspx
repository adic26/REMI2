<%@ Page Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" AutoEventWireup="false" Inherits="Remi.Admin_Tests_EditDetail" Title="Untitled Page"  Codebehind="EditDetail.aspx.vb" %>
<%@ Register src="../../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
    <h1><asp:Label ID="lblTitle" runat="server" Text="Add a new Test"></asp:Label></h1>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <uc1:Notifications ID="notMain" runat="server" />
    <table style="width: 86%;" border="0">
        <tr>
            <td class="HorizTableFirstcolumn">
                Name:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox ID="txtName" runat="server" Width="143px"></asp:TextBox>
                <asp:HiddenField ID="hdnEditID" runat="server" Value="0" />
                <asp:Label ID="lblTestName" runat="server" Text="Label"></asp:Label>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Type:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:RadioButton ID="rbnParametric" runat="server" GroupName="TestType" Text="Parametric" Checked="True" />
                <br />
                <asp:RadioButton ID="rbnIncoming" runat="server" GroupName="TestType" Text="Incoming Eval" />
                <br />
                <asp:RadioButton ID="rbnEnvironmentalStress" runat="server" GroupName="TestType" Text="Environmental Stress" />
                <br />
                <asp:RadioButton ID="rbnNonTestingTask" runat="server" GroupName="TestType" Text="NonTestingTask" />
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Duration (hrs):
            </td>
            <td class="HorizTableSecondColumn">
                &nbsp;<asp:TextBox ID="txtHours" runat="server" Width="60px">0</asp:TextBox></td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Result Is Time Based:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:CheckBox ID="chkResultIsTimeBased" runat="server" />
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Work Instruction Address:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox ID="txtWorkInstructionLocation" runat="server" Width="889px" Rows="3"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">Owner:</td>
            <td class="HorizTableSecondColumn">
                <asp:AutoCompleteExtender runat="server" ID="aceTxtOwner" TargetControlID="txtOwner"
                    ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20">
                </asp:AutoCompleteExtender>
                <asp:TextBox runat="server" ID="txtOwner"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">Trainee:</td>
            <td class="HorizTableSecondColumn">
                <asp:AutoCompleteExtender runat="server" ID="aceTxtTrainee" TargetControlID="txtTrainee"
                    ServicePath="~/webservice/AutoCompleteService.asmx" ServiceMethod="GetActiveDirectoryNames" MinimumPrefixLength="1" CompletionSetCount="20">
                </asp:AutoCompleteExtender>
                <asp:TextBox runat="server" ID="txtTrainee"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">Degradation Calc:</td>
            <td class="HorizTableSecondColumn">
                <asp:TextBox runat="server" ID="txtDegradation"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Usable Test Fixtures:
            </td>
            <td >
                <asp:ObjectDataSource ID="odsTestStationTypes" runat="server" SelectMethod="GetTrackingLocationTypes"
                    TypeName="REMI.Bll.TrackingLocationManager" OldValuesParameterFormatString="original_{0}">
                </asp:ObjectDataSource>
                <table style="width: 100%; height: 78px; border-width:0px;">
                    <tr>
                        <td style="border-width: 0px;">
                            <asp:ListBox ID="lstAllTLTypes" runat="server" Width="360px" Height="400px" DataSourceID="odsTestStationTypes"
                                DataTextField="Name" DataValueField="ID"></asp:ListBox>
                        </td>
                        <td style="border-width: 0px; text-align:left;">
                            <asp:Button ID="btnAddTLType" runat="server" Text="Add ->" cssclass="button"/>
                            <br /><br />
                            <asp:Button ID="btnRemoveTLType" runat="server" Text="<- Remove" cssclass="button"/>
                        </td>
                        <td style="border-width: 0px;">
                            <asp:ListBox ID="lstAddedTLTypes" runat="server" Width="360px" Height="400px" DataTextField="Name" DataValueField="ID"></asp:ListBox>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                Archive:
            </td>
            <td class="HorizTableSecondColumn">
                <asp:CheckBox ID="chkArchived" runat="server" />
            </td>
        </tr>
        <tr>
            <td class="HorizTableFirstcolumn">
                &nbsp;</td>
            <td class="HorizTableSecondColumn">
                <asp:Button ID="btnSave" runat="server"  Text="Save" cssclass="button"/>
                <asp:Button ID="btnCancel" runat="server"  Text="Cancel" cssclass="button"/>
            </td>
        </tr>
    </table>
    <br /><br />  
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>