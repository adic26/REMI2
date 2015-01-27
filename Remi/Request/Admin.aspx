<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ReqAdmin" CodeBehind="Admin.aspx.vb" EnableEventValidation="false" EnableViewState="true" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Src="../Controls/Notifications.ascx" TagName="Notifications" TagPrefix="uc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
</asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1><asp:Label runat="server" ID="lblRequest"></asp:Label></h1>
    <br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server"></asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField runat="server" ID="hdnRequestType" />
    <asp:HiddenField runat="server" ID="hdnRequestTypeID" />
    
    <div class="Scrollgrid">
        <asp:GridView runat="server" ID="grdRequestAdmin" AutoGenerateColumns="false" ShowFooter="true" EnableViewState="true" OnRowCommand="grdRequestAdmin_RowDataCommand" DataKeyNames="FieldSetupID" OnRowEditing="grdRequestAdmin_OnRowEditing" AutoGenerateEditButton="true" OnRowCancelingEdit="grdRequestAdmin_OnRowCancelingEdit" OnRowUpdating="grdRequestAdmin_RowUpdating">
            <Columns>
                <asp:BoundField DataField="FieldSetupID" HeaderText="FieldSetupID" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:BoundField DataField="RequestType" HeaderText="RequestType" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:TemplateField HeaderText="Order"> 
                    <ItemTemplate> 
                        <asp:LinkButton ID="btnUp" CommandName="Up" ToolTip="Up" Text="&uArr;" CssClass="Order" runat="server" CommandArgument='<%# CType(Container, GridViewRow).RowIndex%>' />
                        <asp:LinkButton ID="btnDown" CommandName="Down" ToolTip="Down" Text="&dArr;" CssClass="Order" runat="server" CommandArgument='<%# CType(Container, GridViewRow).RowIndex%>' />
                     </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Name" SortExpression="Name">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblName" Text='<%# Eval("Name")%>' Visible="true"></asp:Label>
                        <asp:TextBox runat="server" ID="txtName" Text='<%# Eval("Name")%>' Visible="false" EnableViewState="true"></asp:TextBox>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:TextBox runat="server" ID="txtNewName" Visible="true" />
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Description" SortExpression="Description">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblDescription" Text='<%# Eval("Description")%>' Visible="true"></asp:Label>
                        <asp:TextBox runat="server" ID="txtDescription" Text='<%# Eval("Description")%>' Visible="false" EnableViewState="true"></asp:TextBox>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:TextBox runat="server" ID="txtNewDescription" Visible="true" />
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Field Type" SortExpression="FieldType">
                    <ItemTemplate>
                        <asp:HiddenField runat="server" ID="hdnFieldTypeID" Value='<%# Eval("FieldTypeID")%>' />
                        <asp:Label runat="server" ID="lblFieldType" Text='<%# Eval("FieldType")%>' Visible="true"></asp:Label>
                        <asp:DropDownList runat="server" ID="ddlFieldType" DataTextField="LookupType" DataValueField="LookupID" Visible="false" DataSourceID="odsFieldTypes"></asp:DropDownList>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:DropDownList runat="server" ID="ddlNewFieldType" DataTextField="LookupType" DataValueField="LookupID" Visible="true" DataSourceID="odsFieldTypes"></asp:DropDownList>
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="FieldValidation" SortExpression="FieldValidation">
                    <ItemTemplate>
                        <asp:HiddenField runat="server" ID="hdnValidationTypeID" Value='<%# Eval("FieldValidationID")%>' />
                        <asp:Label runat="server" ID="lblValidationType" Text='<%# Eval("FieldValidation")%>' Visible="true"></asp:Label>
                        <asp:DropDownList runat="server" ID="ddlValidationType" DataTextField="LookupType" DataValueField="LookupID" Visible="false" DataSourceID="odsValidation"></asp:DropDownList>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:DropDownList runat="server" ID="ddlNewValidationType" DataTextField="LookupType" DataValueField="LookupID" Visible="true" DataSourceID="odsValidation"></asp:DropDownList>
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="IsRequired" SortExpression="IsRequired">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" Checked='<%# Eval("IsRequired")%>' ID="chkIsRequired" Enabled="false" />
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:CheckBox runat="server" ID="chkNewIsRequired" Enabled="true" />
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Archived" SortExpression="Archived">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" Checked='<%# Eval("IsArchived")%>' ID="chkArchived" Enabled="false" />
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:CheckBox runat="server" ID="chkNewArchived" Enabled="true" />
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Options Type" SortExpression="OptionsType">
                    <ItemTemplate>
                        <asp:HiddenField runat="server" ID="hdnOptionsTypeID" Value='<%# Eval("OptionsTypeID")%>' />
                        <asp:Label runat="server" ID="lblOptionsType" Text='<%# Eval("OptionsTypeName")%>' Visible="true"></asp:Label>
                        <asp:DropDownList runat="server" ID="ddlOptionsType" DataTextField="Name" DataValueField="LookupTypeID" Visible="false" DataSourceID="odsLookupTypes"></asp:DropDownList>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:DropDownList runat="server" ID="ddlNewOptionsType" DataTextField="Name" DataValueField="LookupTypeID" Visible="true" DataSourceID="odsLookupTypes"></asp:DropDownList>
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="RequestTypeID" HeaderText="RequestTypeID" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:BoundField DataField="RequestNumber" HeaderText="RequestNumber" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:BoundField DataField="RequestID" HeaderText="RequestID" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:BoundField DataField="Value" HeaderText="Value" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:TemplateField HeaderText="IntField" SortExpression="IntField">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblIntField" Text='<%# Eval("IntField")%>' Visible="true"></asp:Label>
                        <asp:DropDownList runat="server" ID="ddlIntField" Visible="false" DataTextField="IntField" DataValueField="IntField" DataSourceID="odsFieldMapping"></asp:DropDownList>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:DropDownList runat="server" ID="ddlNewIntField" Visible="true" DataTextField="IntField" DataValueField="IntField" DataSourceID="odsFieldMapping"></asp:DropDownList>
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="ExtField" HeaderText="ExtField" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:TemplateField HeaderText="Internal" SortExpression="Internal">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" Checked='<%# Eval("InternalField")%>' ID="chkInternalField" Enabled="false" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="NewRequest" HeaderText="NewRequest" InsertVisible="False" ReadOnly="True" Visible="false" />
                <asp:TemplateField HeaderText="External System" SortExpression="External System">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" Checked='<%# Eval("IsFromExternalSystem")%>' ID="chkExternalSystem" Enabled="false" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Category" SortExpression="Category">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblCategory" Text='<%# Eval("Category")%>' Visible="true"></asp:Label>
                        <asp:TextBox runat="server" ID="txtCategory" Text='<%# Eval("Category")%>' Visible="false" EnableViewState="true"></asp:TextBox>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:TextBox runat="server" ID="txtNewCategory" Visible="true" />
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Parent Field" SortExpression="Parent Field">
                    <ItemTemplate>
                        <asp:HiddenField runat="server" ID="hdnParentFieldID" Value='<%# Eval("ParentFieldSetupID")%>' />
                        <asp:Label runat="server" ID="lblParentField" Text='<%# Eval("ParentFieldSetupName")%>' Visible="true"></asp:Label>
                        <asp:DropDownList runat="server" ID="ddlParentField" DataTextField="Name" DataValueField="ReqFieldSetupID" Visible="false" DataSourceID="odsParents"></asp:DropDownList>
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:DropDownList runat="server" ID="ddlNewParentField" DataTextField="Name" DataValueField="ReqFieldSetupID" Visible="true" DataSourceID="odsParents"></asp:DropDownList>
                    </FooterTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Integrated Remi" SortExpression="Integrated Remi">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" Checked='<%# Eval("HasIntegration")%>' ID="chkIntegrated" Enabled="false" />
                    </ItemTemplate>
                    <FooterStyle HorizontalAlign="Right" />
                    <FooterTemplate>
                        <asp:Button runat="server" ID="btnSave" CssClass="buttonSmall" Text="Add Field" OnClick="btnSave_Click" CausesValidation="true" />
                    </FooterTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>
    <br /><br />

    <asp:ObjectDataSource runat="server" ID="odsParents" OldValuesParameterFormatString="original_{0}" SelectMethod="GetRequestParent" TypeName="REMI.Bll.RequestManager">
        <SelectParameters>
            <asp:ControlParameter ControlID="ctl00$Content$hdnRequestTypeID" Name="requestTypeID" PropertyName="Value" Type="Int32" />
            <asp:Parameter Name="includeArchived" DefaultValue="true" Type="Boolean" />
            <asp:Parameter Name="includeSelect" DefaultValue="true" Type="Boolean" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <asp:ObjectDataSource runat="server" ID="odsFieldMapping" OldValuesParameterFormatString="original_{0}" SelectMethod="GetRequestMappingFields" TypeName="REMI.Bll.RequestManager"></asp:ObjectDataSource>
    <asp:ObjectDataSource runat="server" ID="odsLookupTypes" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLookupTypes" TypeName="REMI.Bll.LookupsManager"></asp:ObjectDataSource>

    <asp:ObjectDataSource runat="server" ID="odsValidation" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLookups" TypeName="REMI.Bll.LookupsManager">
        <SelectParameters>
            <asp:Parameter Type="String" Name="Type" DefaultValue="ValidationTypes" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>
    </asp:ObjectDataSource>

    <asp:ObjectDataSource runat="server" ID="odsFieldTypes" OldValuesParameterFormatString="original_{0}" SelectMethod="GetLookups" TypeName="REMI.Bll.LookupsManager">
        <SelectParameters>
            <asp:Parameter Type="String" Name="Type" DefaultValue="FieldTypes" />
            <asp:Parameter Type="Int32" Name="productID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="parentID" DefaultValue="0" />
            <asp:Parameter Type="String" Name="ParentLookupType" DefaultValue=" " />
            <asp:Parameter Type="String" Name="ParentLookupValue" DefaultValue=" " />
            <asp:Parameter Type="Int32" Name="RequestTypeID" DefaultValue="0" />
            <asp:Parameter Type="Int32" Name="RemoveFirst" DefaultValue="0" />
        </SelectParameters>

    </asp:ObjectDataSource>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>