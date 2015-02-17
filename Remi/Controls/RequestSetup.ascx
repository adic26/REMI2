<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="RequestSetup.ascx.vb" Inherits="Remi.RequestSetup" EnableViewState="true" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="NotificationList" TagPrefix="uc1" %>

<asp:UpdatePanel ID="updRequestSetup" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
    <Triggers>
        <asp:AsyncPostBackTrigger ControlID="ddlRequestSetupOptions" EventName="SelectedIndexChanged" />
    </Triggers>
    <ContentTemplate>
        <asp:HiddenField ID="hdnProductID" runat="server" />
        <asp:HiddenField ID="hdnOrientationID" runat="server" />
        <asp:HiddenField ID="hdnBatchID" runat="server" />
        <asp:HiddenField ID="hdnJobID" runat="server" />
        <asp:HiddenField ID="hdnJobName" runat="server" />
        <asp:HiddenField ID="hdnProductName" runat="server" />
        <asp:HiddenField ID="hdnQRANumber" runat="server" />
        <asp:HiddenField ID="hdnTestStageType" runat="server" />
        <asp:HiddenField ID="hdnIsProjectManager" runat="server" />
        <asp:HiddenField ID="hdnIsAdmin" runat="server" />
        <asp:HiddenField ID="hdnRequestTypeID" runat="server" />
        <asp:HiddenField ID="hdnHasEditItemAuthority" runat="server" />
        <asp:HiddenField ID="hdnUserID" runat="server" />

        <h2><asp:Label runat="server" ID="lblTitle" Text='<%# Title %>'></asp:Label></h2>

        <uc1:NotificationList ID="notMain" runat="server" />

        <asp:Panel runat="server" ID="Orientation" Visible="false">
            Select Orientation/Sequence: 
            <asp:DropDownList runat="server" ID="ddlOrientations" DataTextField="Name" DataValueField="ID" AppendDataBoundItems="true">
            </asp:DropDownList>
        </asp:Panel>

        <asp:label runat="server" Text="Load Setup:" ID="lblLoadSetup"></asp:label>
        <asp:DropDownList runat="server" ID="ddlRequestSetupOptions" CausesValidation="true"
            AutoPostBack="true">
        </asp:DropDownList><br />
        <asp:label runat="server" Text="Save Options:" ID="lblSaveOptions"></asp:label><asp:CheckBoxList runat="server" ID="chklSaveOptions" CausesValidation="true" CssClass="removeStyleWithLeftSameLine" RepeatDirection="Horizontal"></asp:CheckBoxList>
        <asp:Button runat="server" ID="btnSave" Text="Save" CssClass="buttonSmall" Visible="false" />

        <br />
        <asp:TreeView runat="server" ID="tvRequest" ShowLines="false" CssClass="removeStyleWithLeftSameLine"></asp:TreeView>
        
        <asp:UpdateProgress ID="upRequestSetup" runat="server" DynamicLayout="true" DisplayAfter="100" AssociatedUpdatePanelID="updRequestSetup">
            <ProgressTemplate>
                <div class="LoadingModal"></div>
                <div class="LoadingGif"></div>
            </ProgressTemplate>
        </asp:UpdateProgress>
    </ContentTemplate>
</asp:UpdatePanel>