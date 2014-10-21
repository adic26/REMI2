<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableViewState="false" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Measurements" Codebehind="Measurements.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jquery.js"></script>
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () { //when the page has loaded
            $('table#ctl00_Content_grdResultMeasurements').columnFilters(
            {
                caseSensitive: false,
                underline: true,
                wildCard: '*',
                excludeColumns: [0],
                alternateRowClassNames: ['evenrow', 'oddrow']
            });
        });

        function SaveComment(txtid, id, passFailOverride, currentPassFail, passFailText) {
            var comment = document.getElementById(txtid.id).innerHTML.trim().replace("&nbsp;", "");
            
            if (comment == '') {
                alert("Save Not Completed. You Must Enter A Comment");
            }
            else {
                $.ajax({
                    type: "POST",
                    url: "Measurements.aspx/UpdateComment",
                    data: '{value: "' + comment.toString().replace('"', '&#34;') + '", ID: "' + id + '", passFailOverride: "' + passFailOverride.checked + '", currentPassFail: "' + currentPassFail + '", passFailText: "' + passFailText + '" }',
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        if (response.d == true) {
                            location.reload();
                        } else {
                            alert("Save Failed");
                        }
                    },
                    failure: function (response) {
                        alert("Save Failed");
                    }
                });
            }
        }
    </script>
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
<asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>
    <h1><asp:Label runat="server" ID="lblHeader"></asp:Label></h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <script type="text/javascript" src='<%= ResolveUrl("~/Design/scripts/wz_tooltip.js")%>'></script>
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgCancelAction" ToolTip="Go Back to Overview" runat="server" />
                <asp:HyperLink ID="hypCancel" runat="server">Results</asp:HyperLink>
            </li>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/xls_file.png" ID="imgExportAction" runat="server" />
                <asp:LinkButton ID="lnkExportAction" runat="Server" Text="Export Measurements" />
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlLeftMenuFilter">
        <h3>Filter</h3>
        <ul>
            <li>
                <asp:DropDownList runat="server" ID="ddlTestStage" Width="150px" DataTextField="TestStageName" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:DropDownList runat="server" ID="ddlTests" Width="150px" DataTextField="TestName" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:DropDownList runat="server" ID="ddlUnits" Width="150px" DataTextField="BatchUnitNumber" DataValueField="ID"></asp:DropDownList>
            </li>
            <li>
                <asp:Button runat="server" ID="btnSubmit" Text="Query Measurements" />
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:Label runat="server" ID="lblNoResults" Visible="false"><h2>No Measurements For Selected Criteria</h2></asp:Label>
    <asp:Panel runat="server" ID="pnlMeasurements">
        <asp:HiddenField runat="server" ID="hdnUnit" />

        <b><asp:CheckBox ID="chkOnlyFails" runat="server" Text="Show Fails Only" AutoPostBack="true" /></b>
        <b><asp:CheckBox ID="chkIncludeArchived" runat="server" Text="Include Archived" AutoPostBack="true" /></b>
        <font size="1"><br />Use "*" in filter box as wildcard</font>
        <asp:GridView ID="grdResultMeasurements" runat="server" Width="100%" EmptyDataText="There were no measurements found for this result." AllowPaging="False" AllowSorting="False" EnableViewState="True" AutoGenerateColumns="true" DataKeyNames="MeasurementTypeID,ID" CssClass="FilterableTable">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:TemplateField HeaderText="Image" ItemStyle-Width="50px" ControlStyle-CssClass="removeStyle" >
                    <ItemTemplate>
                        <asp:Image Visible="false" runat="server" ImageUrl="" ID="img" />
                        <asp:HiddenField runat="server" ID="hdnImgStr" Value='<%# "data:image/" + Eval("ContentType") + ";base64," + Convert.ToBase64String(Eval("Image")) %>' />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Measurement" SortExpression="Measurement" ItemStyle-Width="250px" ItemStyle-HorizontalAlign="Left" ItemStyle-Wrap="true" ItemStyle-CssClass="removeStyle">
                    <ItemTemplate>
                        <asp:Label runat="server" Visible="false" ID="lblMeasurementType" Text='<%# Eval("Measurement") %>' />
                        <asp:HyperLink ID="hplMeasurementType" runat="server" Text='<%# Eval("Measurement") %>' Target="_blank"></asp:HyperLink>
                    </ItemTemplate>
                </asp:TemplateField>            
            </Columns>
            <AlternatingRowStyle CssClass="oddrow" />
        </asp:GridView>
        <font size="1">
            <ul>
                <li>Measurement link graphs that particular measurement.</li>
                <li>Hover over "Pass/Fail" to enter a comment.</li>
                <li>Hover over image thumbnail to see full image for that measurement.</li>
            </ul>
        </font>
        <h2>Additional Information:</h2>
        <asp:GridView ID="grdResultInformation" runat="server" Width="100%" EmptyDataText="There is no information found for this result." AllowPaging="False" AllowSorting="False" EnableViewState="True" AutoGenerateColumns="false" CssClass="FilterableTable">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="Value" HeaderText="Info" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="VerNum" HeaderText="Version" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="IsArchived" HeaderText="Archived" InsertVisible="False" ReadOnly="True"  Visible="true" ItemStyle-CssClass="hidden" HeaderStyle-CssClass="hidden" />
            </Columns>
        </asp:GridView>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>