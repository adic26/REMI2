<%@ Control Language="VB" AutoEventWireup="false" Inherits="Remi.Controls_TestStageProcessView" Codebehind="TestStageProcessView.ascx.vb" %>
                <asp:Repeater ID="rptProcessLinks" runat="server"  >
                <ItemTemplate>
                    <asp:HiddenField ID="hdnTestStageID" runat="server" 
                        Value='<%# Eval("Value") %>' />
                    <asp:Image ID="imgTestStageComplete" runat="server" 
                        ImageUrl="../Design/Icons/png/16x16/accept.png" />
                    <br />
                </ItemTemplate>
                </asp:Repeater>

