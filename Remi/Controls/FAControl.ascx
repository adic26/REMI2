﻿<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="FAControl.ascx.vb" Inherits="Remi.FAControl" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:GridView ID="grdFAs" runat="server" EmptyDataText='<%# EmptyDataText %>' EnableViewState="true" AutoGenerateColumns="False" Width="700px">
    <RowStyle CssClass="evenrow" />
    <Columns>
        <asp:TemplateField HeaderText="Unit">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblUnit" Text='<%# Eval("Unit")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Test">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblTest" Text='<%# Eval("Test")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Stage">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblStage" Text='<%# Eval("Stage")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Description">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblDescription" style="word-break:break-all;word-wrap:break-word;" Text='<%# Eval("Failure Description").Replace(vbCr, "<br/>").Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>")%>' Width="200px"></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="1st Level Fail">
            <ItemTemplate>
                <asp:Label runat="server" ID="lbl1Lvl" Text='<%# Eval("Failed Top Level")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="2nd Level Fail">
            <ItemTemplate>
                <asp:Label runat="server" ID="lbl2Lvl" Text='<%# Eval("Failed 2nd Level")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="3rd Level Fail">
            <ItemTemplate>
                <asp:Label runat="server" ID="lbl3Lvl" Text='<%# Eval("Failed 3rd Level")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Caused By">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblCause" Text='<%# Eval("Caused By")%>'></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Analysis">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblAnaysis" style="word-break:break-all;word-wrap:break-word;" Text='<%# Eval("Analysis").Replace(vbCr, "<br/>").Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>")%>' Width="200px"></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Root Cause">
            <ItemTemplate>
                <asp:Label runat="server" ID="lblRootCause" style="word-break:break-all;word-wrap:break-word;" Text='<%# Eval("Root Cause").Replace(vbCr, "<br/>").Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>")%>' Width="200px"></asp:Label>
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField HeaderText="Link To FA">
            <ItemTemplate>
                <asp:HyperLink runat="server" ID="hplFA" Target="_blank" NavigateUrl='<%# Eval("Request Link")%>' Text='<%# Eval("RequestNumber")%>'></asp:HyperLink>
            </ItemTemplate>
        </asp:TemplateField>
    </Columns>
</asp:GridView>