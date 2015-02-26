<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="Measurements.ascx.vb" Inherits="Remi.Measurements" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
   
<link href="/Design/jQueryCSS/jQueryUI/jquery-ui-1.11.3.css" rel="stylesheet" />
<link href="/Design/jQueryCSS/MagnificPopup/magnific-popup.css" rel="stylesheet" />


<asp:Panel runat="server" ID="pnlMeasurements">
    <script type="text/javascript">
        function SaveComment(txtid, id, passFailOverride, currentPassFail, passFailText) {
            var comment = document.getElementById(txtid.id).innerHTML.trim().replace("&nbsp;", "");

            if (comment == '') {
                alert("Save Not Completed. You Must Enter A Comment");
            }
            else {
                var requestParams = JSON.stringify({
                    "value": comment.toString().replace('"', '&#34;'),
                    "ID": id,
                    "passFailOverride": passFailOverride.checked,
                    "currentPassFail": currentPassFail,
                    "passFailText": passFailText
                });

                $.ajax({
                    type: "POST",
                    url: "../webservice/REMIInternal.asmx/UpdateComment",
                    data: requestParams,
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

    <asp:HiddenField runat="server" ID="hdnTestID" Value="0" />
    <asp:HiddenField runat="server" ID="hdnResultID" Value="0" />
    <asp:HiddenField runat="server" ID="hdnBatchID" Value="0" />
        
    <div class="removeStyle">
        <asp:ImageButton runat="server" ID="imgExport" ImageUrl="../Design/Icons/png/24x24/xls_file.png" OnClick="imgExport_Click" style="text-align:left;display:inline;" />
        <b><asp:CheckBox ID="chkOnlyFails" runat="server" Text="Show Fails Only" AutoPostBack="true" OnCheckedChanged="chkOnlyFails_CheckedChanged" /></b>
        <b><asp:CheckBox ID="chkIncludeArchived" runat="server" Text="Include Archived" AutoPostBack="true" OnCheckedChanged="chkIncludeArchived_CheckedChanged" /></b>
        <asp:Label runat="server" ID="lblInfo" Text="<font size='1'><br />Use '*' in filter box as wildcard</font>"></asp:Label>
    </div>

    <asp:GridView ID="grdResultMeasurements" runat="server" Width="100%" EmptyDataText="There were no measurements found for this result." AllowPaging="False" AllowSorting="False" EnableViewState="True" AutoGenerateColumns="true" DataKeyNames="MeasurementTypeID,ID" CssClass="FilterableTable">
        <RowStyle CssClass="evenrow" />
        <Columns>
            <asp:TemplateField HeaderText="Image" ItemStyle-Width="50px" ControlStyle-CssClass="removeStyle" >
                <ItemTemplate>                    
                    <input type="image" src="../Design/Icons/png/24x24/png_file.png" class="img-responsive" runat="server" visible="false" id='viewImages' mID='<%# Eval("ID") %>' pageID='<%# Me.ClientID %>' role="button" />
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
    <asp:Panel runat="server" ID="pnlLegend">
        <font size="1">
            <ul>
                <li>Measurement link graphs that particular measurement.</li>
                <li>Hover over "Pass/Fail" to enter a comment.</li>
                <li>Hover over image thumbnail to see full image for that measurement.</li>
            </ul>
        </font>
    </asp:Panel>
    <asp:Panel runat="server" ID="pnlInformation" Visible="false">
        <h2>Additional Information:</h2>
        <asp:GridView ID="grdResultInformation" runat="server" Width="100%" EmptyDataText="There is no information found for this result." AllowPaging="False" AllowSorting="False" EnableViewState="True" AutoGenerateColumns="false" CssClass="FilterableTable">
            <RowStyle CssClass="evenrow" />
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:TemplateField HeaderText="Info" SortExpression="">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblValue" Visible="true" Text='<%# Eval("Value") %>'></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="VerNum" HeaderText="Version" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="IsArchived" HeaderText="Archived" InsertVisible="False" ReadOnly="True"  Visible="true" ItemStyle-CssClass="hidden" HeaderStyle-CssClass="hidden" />
            </Columns>
        </asp:GridView>
    </asp:Panel>
</asp:Panel>