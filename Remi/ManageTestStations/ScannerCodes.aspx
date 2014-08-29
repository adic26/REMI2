<%@ Page Title="" Language="VB"  AutoEventWireup="false" Inherits="Remi.ManageTestStations_ScannerCodes" Codebehind="ScannerCodes.aspx.vb" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>REMI</title>

    <link href="../Design/style.css" rel="stylesheet" type="text/css"/>
 
</head>
<body>

    <form id="form1" runat="server">
    <h2>
        Program for
        <asp:Label ID="lblTrackingLocationName" runat="server" Text="Label"></asp:Label></h2>
        <br />
        <asp:Repeater ID="rptBarcode" runat="server">
        <ItemTemplate><asp:Image ID="imgBarcode" runat="server" ImageUrl='<%# Container.Dataitem %>'/><br /><br /><br /></ItemTemplate>
                </asp:Repeater>

    
</form>
</body>
</html>


