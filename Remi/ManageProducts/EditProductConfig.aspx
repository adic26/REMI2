<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" EnableEventValidation="false"
    AutoEventWireup="false" Inherits="Remi.ManageProducts_EditProductConfig" ValidateRequest="false" Codebehind="EditProductConfig.aspx.vb" %>
    
<%@ Register src="../Controls/Notifications.ascx" tagname="Notifications" tagprefix="uc1" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <script type="text/javascript" src="../design/scripts/jQuery/jquery-1.4.2.js"></script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="leftSidebarContent" runat="Server">
<asp:Panel ID="pnlLeftMenuViews" runat="server">
        <h3>
            Menu</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgRefresh" runat="server" />
                <asp:HyperLink ID="hypRefresh" runat="server" ToolTip="Click to refresh the current page">Refresh</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuActions" Visible="False" runat="server">
        <h3>
            Actions</h3>
        <ul>
            <li>
                    <asp:Image ImageUrl="../Design/Icons/png/24x24/block.png" ID="imgCancelAction" ToolTip="Click to cancel any changes made to the current config"
                        runat="server" />
                    <asp:HyperLink ID="hypCancel" runat="server">Cancel</asp:HyperLink>
                </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="pageTitleContent" runat="Server">
<h1>
        <asp:Label ID="lblProductName" runat="server"></asp:Label></h1><br /><br />
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="Content" runat="Server">
    <asp:HiddenField ID="hdnProductID" runat="server" />
    <asp:HiddenField ID="hdnTestID" runat="server" />

    <asp:Label runat="server" ID="lvlTests">Select A Test:</asp:Label><asp:DropDownList ID="ddlTests" CausesValidation="false" AutoPostBack="true" runat="server" Width="200px" AppendDataBoundItems="True"></asp:DropDownList>

    <br /><asp:Label runat="server" ID="lblConfigs" Visible="false">Test Case: </asp:Label><asp:DropDownList runat="server" ID="ddlProductConfig" AutoPostBack="true" DataTextField="PCName" DataValueField="PCID" Visible="false"></asp:DropDownList>
    <asp:Button runat="server" ID="btnUploadNew" Text="Upload Additional Config" Visible="false" OnClick="btnUploadNew_OnClick" />
    <asp:GridView ID="grdvVersions" runat="server" CssClass="FilterableTable" AutoGenerateColumns="false" AutoGenerateEditButton="true" DataKeyNames="APVID,PCVersionID,VerID" OnRowEditing="grdvVersions_OnRowEditing" OnRowCancelingEdit="grdvVersions_OnRowCancelingEdit" OnRowUpdating="grdvVersions_RowUpdating">
        <Columns>
            <asp:TemplateField HeaderText="ID" SortExpression="ID" Visible="false">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblID" Text='<%# Eval("ID")%>' Visible="true" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Release Version" SortExpression="VerNum">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblReleaseVersion" Text='<%# Eval("VerNum")%>' Visible="true" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Applicable To All" SortExpression="ApplicableToAll">
                <ItemTemplate>
                    <asp:CheckBox runat="server" Checked='<%# Eval("ApplicableToAll")%>' ID="chkATA" Enabled="false" />
                 </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Product Config Version" SortExpression="PCVersion">
                <ItemTemplate>
                    <asp:Label runat="server" ID="lblVersion" Text='<%# Eval("PCVersion")%>' Visible="true" />
                    <asp:DropDownList runat="server" ID="ddlVersions" DataTextField="VersionNum" DataValueField="ID" Visible="false"></asp:DropDownList>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <asp:Label ID="lblMissingConfiguration" runat="server" Visible="false"><br /><br />There is no configuration for this Test and product.<br />But you can copy from one of the below saved configurations:<b>OR</b><br /></asp:Label><br />
    <asp:DropDownList ID="ddlCopyFrom" Visible="false" runat="server" DataTextField="ProductGroupName" DataValueField="ID"></asp:DropDownList>
    <asp:Button ID="btnCopyFrom" runat="server" Visible="false" Text="Copy Configuration" /><br />
    <asp:Label ID="lblMissingConfiguration2" runat="server" Visible="false">You can import an XML file. This file will be processed within 15-30 minutes</asp:Label><br />
    

    <asp:Label runat="server" Visible="false" ID="lblProcessing" Text="XML Processing! Your XML Will Be Processed at 1pm.<br/><br/>If You Need it Sooner Contact <a href=mailto:'tsdinfrastructure@blackberry.com'>Reliability Infrastructure</a>." CssClass="Processing"></asp:Label>
    <br /><br /><asp:Button runat="server" Visible="false" ID="btnProcessPendingXML" OnClick="btnProcessPendingXML_Click" Text="Click Here To Process Pending XML" CssClass="Processing" />

    <table cellspacing="0" cellpadding="0" border="0" class="">
        <tr>
            <td valign="top" style="vertical-align:top;border:0;margin:0px;">
                <script type="text/javascript">
                    function gvrowtoggle(row, clientid) {
                        try {

                            if (document.getElementById(clientid).className !== 'hidden') //if the row is not currently hidden 
                            {
                                document.getElementById(clientid).className = 'hidden'; //hide the row
                            }
                            else {
                                document.getElementById(clientid).className = ''; //set the css class of the row to default 
                            }
                        }
                        catch (ex) { alert(ex) }
                    }

                    function SwitchDropText(rbl, txt, ddl) {
                        if (document.getElementById(rbl).getElementsByTagName("input")(1).checked) {
                            document.getElementById(txt).className = "";
                            document.getElementById(ddl).className = "hidden";
                        }
                        else {
                            document.getElementById(txt).className = "hidden";
                            document.getElementById(ddl).className = "";
                        }
                    }

                    function AddDetail(pcID, txt, ddl, grdvDetails, chk, txtLookupsAdd) {
                        var lookupType = document.getElementById(ddl);
                        var isAttribute = document.getElementById(chk);
                        var lookupTypeValue = lookupType.options[lookupType.selectedIndex].value;
                        
                        if (document.getElementById(txt).value == '') {
                            document.getElementById(txt).focus();
                            alert("Please enter a value");
                            return false;
                        }
                        else if ((lookupTypeValue == '' || parseInt(lookupTypeValue) == 0) && txtLookupsAdd == '') {
                            lookupType.focus();
                            alert("Please enter a lookup type");
                            return false;
                        }

                        PageMethods.AddRowDetail(pcID, document.getElementById(txt).value, lookupTypeValue, isAttribute.checked, document.getElementById(txtLookupsAdd).value);
                        $(document.getElementById('<%=btnViewMode.ClientID %>')).click();

                        return true;
                    }

                    function deleteDetail(configID, image, rowID) {
                        var doDelete = confirm("Are you sure you want to delete this detail?");

                        if (doDelete) {
                            PageMethods.DeleteConfig(configID, OnSuccess);
                            $(document.getElementById(rowID)).remove()
                        }
                    }

                    function deleteRow(pcID, rowID) {
                        var doDelete = confirm("Are you sure you want to delete this entire row?");

                        if (doDelete) {
                            PageMethods.DeleteRow(pcID, OnSuccess);
                            $(document.getElementById(rowID)).remove()
                        }
                    }

                    function btnAddDetail_Click(txt, droplist, btnSave, chk, rbl) {
                        document.getElementById(droplist).className = "";
                        document.getElementById(txt).className = "";
                        document.getElementById(btnSave).className = "";
                        document.getElementById(rbl).className = "removeStyleWithLeftSameLine";

                        document.getElementById(chk).removeAttribute('class');
                        document.getElementById(chk).parentNode.attributes.removeNamedItem('class');
                    }

                    function deleteAllNodes(pcUID) {
                        var doDelete = confirm("Are you sure you want to delete ALL nodes?");

                        if (doDelete) {
                            PageMethods.DeleteAll(pcUID, OnSuccess);
                            $(document.getElementById('<%=btnViewMode.ClientID %>')).click();

                            return true;
                        }
                        return false;
                    }

                    function OnSuccess(response, userContext, methodName) {
                    }
                </script>
                <asp:Panel ID="pnlOverAll" runat="server" style="overflow-y:scroll;max-height:700px;text-align:left;">
                    <asp:Button ID="btnEditMode" runat="server" Text="Edit Mode" Visible="false" CausesValidation="false" UseSubmitBehavior="false"  />
                    <asp:Button ID="btnViewMode" runat="server" Text="View Mode" Visible="false" CausesValidation="false" UseSubmitBehavior="false" />
                    <asp:Button ID="btnUpdate" runat="server" Text="Save" Visible="false" CausesValidation="false" UseSubmitBehavior="false" />
                    
                    <asp:Button ID="btnAddNode" runat="server" Text="Add New Node" Visible="true" UseSubmitBehavior="false" OnClick="btnAddNode_Click" />

                    <asp:Panel ID="pnlAddNode" runat="server" CssClass="hidden" style="width:300px">
                        <table cellpadding="0" cellspacing="0" border="0">
                            <tr>
                                <th>Node Name</th>
                                <th>Parent</th>
                                <th>ViewOrder</th>
                                <th>&nbsp;</th>
                            </tr>
                            <tr>
                                <td><asp:TextBox ID="txtAddNodeName" runat="server" /></td>
                                <td><asp:DropDownList ID="ddlAddParentNames" runat="server" DataTextField="ParentName" DataValueField="ParentID"></asp:DropDownList></td>
                                <td><asp:TextBox ID="txtAddViewOrder" runat="server" Width="45" /></td>
                                <td><asp:Button ID="btnSaveNode" runat="server" Text="Save" OnClick="btnSaveNode_Click" /></td>
                                <td><asp:Button ID="btnCancel" runat="server" Text="Cancel" /></td>
                            </tr>
                        </table>
                    </asp:Panel><br/><br />
                    
                    <asp:GridView ID="grdvProductConfig" runat="server" DataKeyNames="ID,ParentID"  CssClass="FilterableTable">
                        <RowStyle CssClass="evenrow" />
                        <AlternatingRowStyle CssClass="oddrow" />
                        <HeaderStyle CssClass="" />
                        <Columns>
                            <asp:TemplateField HeaderText="ConfigID" Visible="false">
                                <ItemTemplate>
                                    <asp:Label ID="lblConfigID" runat="server" Text='<%# Eval("ID") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="ParentID" Visible="false">
                                <ItemTemplate>
                                    <asp:Label ID="lblParentID" runat="server" Text='<%# Eval("ParentID") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Parent">
                                <ItemTemplate>
                                    <asp:Label ID="lblParentName" Visible='<%# Not(IsInEditMode) %>' runat="server" Text='<%# Eval("ParentName") %>' />
                                    <asp:DropDownList ID="ddlParentNames" Visible='<%# IsInEditMode %>' runat="server" DataTextField="ParentName" DataValueField="ParentID"></asp:DropDownList>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="View Order">
                                <ItemTemplate> 
                                    <asp:Label ID="lblViewOrder" Visible='<%# Not(IsInEditMode) %>' runat="server" Text='<%# Eval("ViewOrder") %>' />
                                    <asp:TextBox ID="txtViewOrder" Visible='<%# IsInEditMode %>' runat="server" Text='<%# Eval("ViewOrder") %>' Width="45" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Node Name">
                                <ItemTemplate> 
                                    <asp:Label ID="lblNodeName" Visible='<%# Not(IsInEditMode) %>' runat="server" Text='<%# Eval("NodeName") %>' />
                                    <asp:TextBox ID="txtNodeName" Visible='<%# IsInEditMode %>' runat="server" Text='<%# Eval("NodeName") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Details">
                                <ItemStyle HorizontalAlign="Left" />
                                <ItemTemplate>
                                    <div style="width:300px;">
                                        <asp:Image ID="btnAddDetail" runat="server" CssClass="hidden" />
                                        <asp:Image runat="server" ID="imgDeleteRow" ImageUrl="/Design/Icons/png/16x16/delete.png" CssClass="hidden" />
                                        <asp:Image runat="server" ID="btnDetail" ImageUrl="/Design/Icons/png/16x16/link.png" CssClass="hidden" />

                                        <asp:RadioButtonList runat="server" ID="rblLookupsAdd" RepeatDirection="Vertical" CssClass="hidden" TextAlign="Right" CellPadding="10">
                                         <asp:ListItem Selected="True" Value="0">Select</asp:ListItem>
                                         <asp:ListItem Selected="False" Value="1">Text</asp:ListItem>
                                        </asp:RadioButtonList>
                                        <asp:TextBox ID="txtLookupsAdd" runat="server" CssClass="hidden" />
                                        <asp:DropDownList ID="ddlLookupsAdd" runat="server" CssClass="hidden" DataTextField="LookupType" DataValueField="LookupID"></asp:DropDownList>
                                        <asp:TextBox ID="txtValueAdd" runat="server" CssClass="hidden" Width="80"></asp:TextBox>
                                        <asp:CheckBox runat="server" ID="chkIsAttributeAdd" CssClass="hidden" />
                                        <asp:Image ID="btnSave" runat="server" CssClass="hidden" ImageUrl="/Design/Icons/png/16x16/save.png" />
                                    </div>
                                    <asp:GridView ID="grdvDetails" runat="server" AutoGenerateColumns="false" DataKeyNames="ID,ParentID,LookupID,LookupValue,ProdConfID,IsAttribute" OnRowDataBound="grdvproductConfigDetails_RowDataBound">
                                        <RowStyle CssClass="evenrow" />
                                        <AlternatingRowStyle CssClass="oddrow" />
                                    </asp:GridView>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                    <asp:Button runat="server" ID="btnDeleteAll" Text="Delete All" />
                </asp:Panel>
            </td>
            <td valign="top" style="vertical-align:top;border:0;padding:0px;margin:0px;">
                <asp:Label runat="server" ID="lblPCName" Visible="true">XML Name: </asp:Label><asp:TextBox runat="server" ID="txtPCName" Visible="true" Width="200px"></asp:TextBox>
                <asp:Button runat="server" ID="btnUpload" Visible="false" OnClick="btnUpload_Click" Text="Upload XML" /><br />
                <asp:Label runat="server" ID="lblXMLTitle">Test Station XML File Output:<br /></asp:Label>
                <asp:TextBox ID="txtXMLDisplay" runat="server"></asp:TextBox><br />
                <asp:GridView ID="grdVersion" runat="server" EmptyDataText="There were no versions found!" CssClass="FilterableTable" EnableViewState="true" AutoGenerateColumns="false">
                    <Columns>
                        <asp:BoundField DataField="VersionNum" HeaderText="Version" SortExpression="VersionNum" />
                        <asp:TemplateField HeaderText="XML" SortExpression="">
                            <ItemTemplate>
                                <asp:LinkButton ID="lbtnXML" runat="server" ToolTip="XML File" Text="<img src='\Design\Icons\png\24x24\xml_file.png'/>" CommandName="XML" CommandArgument='<%# Eval("PCXML") %>'></asp:LinkButton>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </td>
        </tr>
    </table>
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="rightSidebarContent" runat="Server">
</asp:Content>