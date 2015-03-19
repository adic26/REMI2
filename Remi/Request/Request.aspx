<%@ Page Language="vb" EnableViewState="true" AutoEventWireup="false" CodeBehind="Request.aspx.vb" EnableEventValidation="false" Inherits="Remi.Request" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>
<%@ Register Src="../Controls/RequestSetup.ascx" TagName="RequestSetup" TagPrefix="rs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
    <script type="text/javascript" src="../Design/scripts/jQuery/jquery-1.11.1.js"></script>
    <script type="text/javascript" src="../Design/scripts/wz_tooltip.js"></script>
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <asp:HyperLink runat="server" ID="hypAdmin" Visible="false" Text="Admin" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypBatch" Visible="false" Text="Batch" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypResults" Text="Results" Visible="false" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:HyperLink runat="server" ID="hypNew" Enabled="true" Text="Create Request" Target="_blank"></asp:HyperLink>
            </li>
            <li>
                <asp:CheckBox runat="server" ID="chkDisplayChanges" Text="Display Changes" Visible="false" TextAlign="Right" AutoPostBack="true" OnCheckedChanged="chkDisplayChanges_CheckedChanged" />
            </li>
            <li>
                <asp:Button runat="server" ID="btnSave" Text="Save Request" CssClass="buttonSmall" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField runat="server" ID="hdnRequestType" />
    <asp:HiddenField runat="server" ID="hdnRequestTypeID" />
    <asp:HiddenField runat="server" ID="hdnRequestNumber" />
    <asp:HiddenField runat="server" ID="hdnDistribution" />
    <asp:HiddenField runat="server" ID="hdnAddMore" />

    <script type="text/javascript">
        function Img_Click(id) {
            var txt = $("[id$='txt" + id + "']")[0];
            var img = $("[id$='img" + id + "']")[0];
            var hyp = $("[id$='hyp" + id + "']")[0];
            var btnfu = $("[id$='fu" + id + "']")[1];
            var fu = $("[id$='fu" + id + "']")[0];

            txt.value = '';
            img.style.display = 'none';
            hyp.style.display = 'none';
            fu.style.display = '';
            btnfu.style.display = '';
        }

        function SetAddMore(id) {
            document.getElementById('<%= hdnAddMore.ClientID%>').value = id;
            var hdn = $("[id$='hdn" + id + "']");
            hdn[0].value = parseInt(hdn[0].value) + 1;
        }

        function GetValue(source, eventArgs)
        {
            var txt = document.getElementById(source._element.id);
            txt.value = '';

            var o = new Option(eventArgs.get_value(), eventArgs.get_value());
            $(o).html(eventArgs.get_value());
            $('#ctl00_Content_lstDistribution').append(o);

            var dist = document.getElementById('<%= hdnDistribution.ClientID%>');
            dist.value += eventArgs.get_value() + ",";
        }
    </script>

    <uc1:NotificationList ID="notMain" runat="server" />
        
    <asp:Panel runat="server" ID="pnlDisplayChanges" Visible="false">
        <asp:GridView ID="grdDisplayChanges" runat="server" AutoGenerateColumns="False" EnableViewState="False" EmptyDataText="No Changes">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" ReadOnly="True" />
                <asp:BoundField DataField="Value" HeaderText="Value" ReadOnly="True" />
                <asp:BoundField DataField="UserName" HeaderText="User" ReadOnly="True" />
                <asp:BoundField DataField="InsertTime" HeaderText="Inserted" ReadOnly="True" />
                <asp:BoundField DataField="RecordNum" HeaderText="Version" ReadOnly="True" />
                <asp:BoundField DataField="Action" HeaderText="Action" ReadOnly="True" />
            </Columns>
        </asp:GridView>
    </asp:Panel>
    <br />
    <asp:Panel runat="server" ID="pnlRequest" EnableViewState="true" style="display:inline-block;vertical-align:top;">
        <asp:Table runat="server" ID="tbl" EnableViewState="true" CssClass="requestTable"></asp:Table>
    </asp:Panel>

    <asp:Panel runat="server" ID="pnlSetup" EnableViewState="true" style="display:inline-block;vertical-align:top;" Visible="false">
        <rs:RequestSetup ID="setup" runat="server" Visible="false" DisplayMode="Request" Title="Setup Parametric" />
        <rs:RequestSetup ID="setupEnv" runat="server" Visible="false" DisplayMode="Request" Title="Setup Environmental" />
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>