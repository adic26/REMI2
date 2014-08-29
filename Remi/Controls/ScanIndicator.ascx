<%@ Control Language="VB" AutoEventWireup="false" Inherits="Remi.Controls_ScanIndicator" Codebehind="ScanIndicator.ascx.vb" %>
  <asp:Panel ID="pnlSuccessScan" runat="server" CssClass="ScanPass" Visible="false">
                   <asp:Literal ID="litScanPass" runat="server" Text="Scan Successful"></asp:Literal>   
    </asp:Panel>  <asp:Panel ID="pnlFailScan" runat="server" CssClass="ScanFail" Visible="false">
        <asp:Literal ID="litScanFail" runat="server" Text="Scan Failed"></asp:Literal>
    </asp:Panel>
     <asp:Panel ID="pnlInformation" runat="server" CssClass="ScanFailInfo" Visible="false">
     <asp:Literal ID="litScanInfo" runat="server" Text="Scan Failed"></asp:Literal>
    </asp:Panel>