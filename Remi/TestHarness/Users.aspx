<%@ Page Language="VB" AutoEventWireup="false" Inherits="Remi.TestHarness_Users" Codebehind="Users.aspx.vb" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
       <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server">
           <Services>
                <asp:ServiceReference Path="~/WebService/AutoCompleteService.asmx" />
            </Services>
        </asp:ToolkitScriptManager>
       
        
 
        <asp:TextBox ID="txtUserName" runat="server" autocomplete="off"></asp:TextBox>
   
         <asp:AutoCompleteExtender ID="txtUserName_AutoCompleteExtender" runat="server" 
             Enabled="True" servicemethod="GetActiveDirectoryNames" ServicePath="~/WebService/AutoCompleteService.asmx" 
            TargetControlID="txtUserName" MinimumPrefixLength="1" EnableCaching="true" 
            CompletionSetCount="20"  >
        </asp:AutoCompleteExtender>
   
        <asp:Button ID="btnUserIsInAD"
            runat="server" Text="UserInAD" />
        <asp:Button ID="Button1" runat="server" Text="GetProperties" />
        <asp:Button ID="txtGetFullProperties" runat="server" Text="GetFull Props" /><asp:Button ID="btnSearch" runat="server" Text="SearchAD" />
        <br />
        <br />
    </div>
    <asp:TextBox ID="txtPassword" runat="server"></asp:TextBox>
    <asp:AutoCompleteExtender ID="txtPassword_AutoCompleteExtender" runat="server" 
         Enabled="True"   ServiceMethod="GetActiveDirectoryNames" 
        ServicePath="~/WebService/AutoCompleteService.asmx"  
        TargetControlID="txtPassword">
    </asp:AutoCompleteExtender>
    <asp:Button ID="btnValidateUser" runat="server" Text="Validate User" />
    </form>
</body>
</html>
