<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false"
    Inherits="Remi.Reports" Codebehind="Reports.aspx.vb" EnableEventValidation="false" %>
<%@ Register Assembly="System.Web.Ajax" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server">
    <link href="../Design/jQueryCSS/bootstrap-select.css" rel="Stylesheet" type="text/css" />
    <script type="text/javascript" src="../Design/scripts/jquery-1.4.2.js"></script>
    <script  type="text/javascript" src="../Design/scripts/bootstrap-select.js"></script>
    <script type="text/javascript" src="../Design/scripts/bootstrap.js"></script>
    <link href="../Design/jQueryCSS/bootstrap.css" rel="Stylesheet" type="text/css" />
    <script src="../Design/scripts/jquery.columnfilters.js" type="text/javascript"></script>
    <script type="text/javascript" src="../Design/scripts/ToolBox.js"></script>

    

    <script type="text/javascript">


        $('.selectpicker').selectpicker({
          style: 'btn-info',
          size: 4
        });
        

        $(document).ready(function () {
            var rtID = $('#<%=ddlRequestType.ClientID%>');
            //console.log(rtID[0].value);
            var temp = searchFields(rtID[0].value);
            console.log(temp);

            });

        function searchFields(rtID) {
            
            $.ajax({
                type: "POST",
                url: "Reports.aspx/Search",
                data: {requestTypeID: rtID},
                //data: 'requestTypeID: "' + rtID + '" }',
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    /*if (response.d == true) {
                        console.log(response.data);
                    }*/
                    alert("hi");
                },
                failure: function (response) {
                    console.log(response.data);
                }
            });


            //$.get("Reports.aspx/Search",'requestTypeID: "' + rtID + '" }',function(response) {
            //    console.log(response);
            //});
            
        }

    </script>


</asp:Content>



<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Reports</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:ToolkitScriptManager ID="AjaxScriptManager1" runat="server"></asp:ToolkitScriptManager>

        <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Request View</h3>
        <ul>
            <li>
                <br /><asp:DropDownList runat="server" ID="ddlRequestType" AppendDataBoundItems="false" AutoPostBack="true" DataTextField="RequestType" DataValueField="RequestTypeID"></asp:DropDownList>
            </li>
        </ul>
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
   
            <select id="bs_ddlSearchField" class="selectpicker show-tick" title="select a condiment" multiple data-selected-text-format="count">
                <option>Mustard</option>
                <option>Ketchup</option>
                <option>Relish</option>
            </select>

    
    <asp:DropDownList runat="server" ID="ddlSearchField" DataTextField="Name" DataValueField="ReqFieldSetupID" AppendDataBoundItems="false" EnableViewState="true"></asp:DropDownList>


    <asp:TextBox runat="server" ID="txtSearchTerm" ></asp:TextBox>
    <asp:Button runat="server" ID="btnSave" Text="Add" OnClick="btnSave_Click" />
    <br />
    <asp:DropDownList runat="server" ID="ddlTests" Width="150px" DataTextField="TestName" DataValueField="ID" AppendDataBoundItems="true"></asp:DropDownList>

    <br /><asp:ListBox runat="server" ID="lstSearchTerms"></asp:ListBox>

    <br />
    <asp:Button runat="server" ID="btnSearch" Text="Search" OnClick="btnSearch_Click" />

    <asp:GridView runat="server" ID="grdRequestSearch" AutoGenerateColumns="true"></asp:GridView>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>

