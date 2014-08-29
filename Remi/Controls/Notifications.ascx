<%@ Control EnableViewState="false" Language="VB" AutoEventWireup="false" Inherits="Remi.Controls_Notifications" Codebehind="Notifications.ascx.vb" %>

  


<asp:Repeater ID="rptErrorList" runat="server" EnableViewState="false">
	<HeaderTemplate>
       <ul class="ErrorMessage" >
	</HeaderTemplate>
	<FooterTemplate>
		</ul>	
	</FooterTemplate>
	<ItemTemplate>
		<li><asp:Literal EnableViewState="false" ID="Label1" runat="server" Text='<%# Container.DataItem %>'></asp:Literal></li>
	</ItemTemplate>
</asp:Repeater>
<asp:Repeater ID="rptWarningList" runat="server">
	<HeaderTemplate>
          	<ul class="WarningMessage">
	</HeaderTemplate>
	<FooterTemplate>
		</ul>
	</FooterTemplate>
	<ItemTemplate>
		<li><asp:Literal EnableViewState="false" ID="Label1" runat="server" Text='<%# Container.DataItem %>'></asp:Literal></li>
	</ItemTemplate>
</asp:Repeater>
<asp:Repeater ID="rptInformation" runat="server" EnableViewState="false">
	<HeaderTemplate>
      	<ul class="InformationMessage" >
	</HeaderTemplate>
	<FooterTemplate>
		</ul>
	</FooterTemplate>
	<ItemTemplate>
		<li ><asp:Literal EnableViewState="false"  ID="Label1" runat="server" Text='<%# Container.DataItem %>'></asp:Literal></li>
	</ItemTemplate>
</asp:Repeater>
