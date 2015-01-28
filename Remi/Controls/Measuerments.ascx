﻿<%@ Control Language="vb" AutoEventWireup="true" CodeBehind="Measuerments.ascx.vb" Inherits="Remi.Measuerments" EnableViewState="true"  %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
   
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
    <asp:HiddenField runat="server" ID="hdnTestID" />
    <asp:HiddenField runat="server" ID="hdnResultID" />
    <asp:HiddenField runat="server" ID="hdnBatchID" />
    <asp:Button ID="btnShowPopup" runat="server" style="display:none" />
    <asp:ModalPopupExtender ID="ModalPopupExtender1" runat="server" EnableViewState="true" BackgroundCssClass="ModalBackground" CancelControlID="btnCancel" PopupControlID="pnlpopup" TargetControlID="btnShowPopup"></asp:ModalPopupExtender> 
     
    <asp:Panel ID="pnlpopup" runat="server" BackColor="White" style="display:none;" Width="1050" EnableViewState="true" Height="850" HorizontalAlign="Center" CssClass="ModalPopup">
        <asp:HiddenField runat="server" ID="hdnMeasurementID" />
        <asp:Label runat="server" ID="lblTitle"></asp:Label><br />
        <asp:Image ID="imgslides" runat="server" /><br />
        <asp:Button ID="btnPrevious" runat="server" Text="Prev" CssClass="buttonSmall"/>
        <asp:Button ID="btnPlay" runat="server" Text="Play" CssClass="buttonSmall"/>
        <asp:Button ID="btnNext" runat="server" Text="Next" CssClass="buttonSmall"/>
        <asp:Button ID="btnCancel" runat="server" Text="Cancel" CssClass="buttonSmall" /><br />
        <asp:Label ID="lblDesc" runat="server"></asp:Label>

        <asp:SlideShowExtender runat="server" ID="sseImages" Enabled="false" EnableViewState="true" UseContextKey="true" TargetControlID="imgslides" ImageTitleLabelID="lblTitle" ImageDescriptionLabelID="lblDesc" PlayInterval="2000" Loop="true" 
            SlideShowServicePath="../WebService/REMIInternal.asmx" SlideShowServiceMethod="GetSlides" NextButtonID="btnNext" PreviousButtonID="btnPrevious" PlayButtonID="btnPlay" ></asp:SlideShowExtender>
    </asp:Panel>
    <div class="removeStyle">
        <asp:ImageButton runat="server" ID="imgExport" ImageUrl="../Design/Icons/png/24x24/xls_file.png" OnClick="imgExport_Click" style="text-align:left;display:inline;" />
        <b><asp:CheckBox ID="chkOnlyFails" runat="server" Text="Show Fails Only" AutoPostBack="true" /></b>
        <b><asp:CheckBox ID="chkIncludeArchived" runat="server" Text="Include Archived" AutoPostBack="true" /></b>
        <asp:Label runat="server" ID="lblInfo" Text="<font size='1'><br />Use '*' in filter box as wildcard</font>"></asp:Label>
    </div>
    <asp:GridView ID="grdResultMeasurements" runat="server" Width="100%" EmptyDataText="There were no measurements found for this result." AllowPaging="False" AllowSorting="False" EnableViewState="True" AutoGenerateColumns="true" DataKeyNames="MeasurementTypeID,ID" CssClass="FilterableTable">
        <RowStyle CssClass="evenrow" />
        <Columns>
            <asp:TemplateField HeaderText="Image" ItemStyle-Width="50px" ControlStyle-CssClass="removeStyle" >
                <ItemTemplate>
                    <asp:ImageButton ID="img" runat="server" Visible="false" CausesValidation="true" EnableViewState="true" ImageUrl="../Design/Icons/png/24x24/png_file.png" Height="30px" Width="30px" OnClick="imgbtn_Click" />
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
                <asp:BoundField DataField="Value" HeaderText="Info" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="VerNum" HeaderText="Version" InsertVisible="False" ReadOnly="True"  Visible="true" />
                <asp:BoundField DataField="IsArchived" HeaderText="Archived" InsertVisible="False" ReadOnly="True"  Visible="true" ItemStyle-CssClass="hidden" HeaderStyle-CssClass="hidden" />
            </Columns>
        </asp:GridView>
    </asp:Panel>
</asp:Panel>