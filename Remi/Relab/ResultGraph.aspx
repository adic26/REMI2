<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.ResultGraph" Codebehind="ResultGraph.aspx.vb" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server">
    <h1>Graph Results</h1><br />
</asp:Content>
<asp:Content ID="leftcolumn" ContentPlaceHolderID="leftSidebarContent" runat="server">
    <asp:Panel ID="pnlLeftMenuActions" runat="server">
        <h3>Actions</h3>
        <ul>
            <li>
                <asp:Image ImageUrl="../Design/Icons/png/24x24/refresh.png" ID="imgCancelAction" ToolTip="Go Back to Overview" runat="server" />
                <asp:HyperLink ID="hypCancel" runat="server">Results</asp:HyperLink>
            </li>
        </ul>
    </asp:Panel>
    <asp:Panel ID="pnlLeftMenuFilter" runat="server">
        <h3>Filter</h3>
        <ul>
            <li>
                <asp:CheckBox runat="server" ID="chkShowUpperLower" Text="Upper Lower Limits" Checked="true" /><br />
                <asp:CheckBox runat="server" ID="chkShowArchived" Text="Include Archived" Checked="false" /><br />
                <asp:CheckBox runat="server" ID="chkShowOnlyFailValue" Text="Fail Options Only" Checked="false" AutoPostBack="true" />
            </li>
            <li>
                <asp:DropDownList runat="server" ID="ddlYear" CausesValidation="true" AutoPostBack="true" style="width:150px;"><asp:ListItem Selected="True" Text="Select A Year" Value="0"></asp:ListItem></asp:DropDownList>
                
                <div style="OVERFLOW-Y:scroll; WIDTH:150px; HEIGHT:200px">
                    <asp:CheckBoxList runat="server" ID="chklBatches" CausesValidation="true" CssClass="removeStyleWithLeft" AppendDataBoundItems="true" DataTextField="BatchUnitNumber" DataValueField="BatchUnitNumber" style="width:150px;" AutoPostBack="true">
                    </asp:CheckBoxList>
                </div>
                <asp:DropDownList ID="ddlTests" runat="server" DataTextField="TName" DataValueField="TestID" AutoPostBack="true" style="width:150px;" CausesValidation="true" AppendDataBoundItems="true"><asp:ListItem Selected="True" Text="Select A Test" Value="0"></asp:ListItem></asp:DropDownList>
                <asp:DropDownList runat="server" style="width:150px;" ID="ddlMeasurementType" Visible="false" CausesValidation="true" AutoPostBack="true" DataTextField="Measurement" AppendDataBoundItems="true" DataValueField="MeasurementTypeID" ><asp:ListItem Selected="True" Text="Select A Measurement" Value="0"></asp:ListItem></asp:DropDownList>
                <asp:DropDownList runat="server" style="width:150px;" ID="ddlParameter" Visible="false" CausesValidation="true" AutoPostBack="true" DataTextField="ParameterName" AppendDataBoundItems="true" DataValueField="ParameterName"><asp:ListItem Selected="True" Text="Select A Parameter" Value="0"></asp:ListItem></asp:DropDownList>
                <asp:DropDownList runat="server" ID="ddlParameterValue" style="width:150px;" Visible="false" CausesValidation="true" AutoPostBack="true" DataTextField="ParameterName" AppendDataBoundItems="true" DataValueField="ParameterName"><asp:ListItem Selected="True" Text="Select A Value" Value="0"></asp:ListItem></asp:DropDownList>
            </li>
            <li>
                <asp:Panel runat="server" ID="pnlUnits" CssClass="ChecboxList">
                    <asp:CheckBoxList runat="server" ID="chklUnits" CausesValidation="true" CssClass="removeStyleWithLeft" AppendDataBoundItems="true" DataTextField="Name" DataValueField="ID">
                    </asp:CheckBoxList>
                </asp:Panel>
            </li>
            <li>
                <asp:Panel runat="server" ID="pnlTestStage" CssClass="ChecboxList2">
                     <asp:CheckBoxList runat="server" ID="chklTestStages" CssClass="removeStyleWithLeft" AutoPostBack="false" CausesValidation="true" DataTextField="Name" DataValueField="ID" AppendDataBoundItems="true"></asp:CheckBoxList>
                </asp:Panel>
            </li>
            <li>
                X-Axis:
                <asp:DropDownList runat="server" ID="ddlXAxis" CausesValidation="true" style="width:150px;">
                    <asp:ListItem Selected="True" Text="Units" Value="0"></asp:ListItem>
                    <asp:ListItem Text="Stages" Value="1"></asp:ListItem>                    
                    <asp:ListItem Text="Parameter" Value="2"></asp:ListItem>
                </asp:DropDownList>
                Plot Value:
                <asp:DropDownList runat="server" ID="ddlGraphValue" CausesValidation="true" style="width:150px;">
                    <asp:ListItem Selected="True" Text="Units" Value="0"></asp:ListItem>
                    <asp:ListItem Text="Stages" Value="1"></asp:ListItem>
                </asp:DropDownList>
            </li>
            <li>
                <asp:Button ID="btnGenerateReport" runat="server" Text="Generate Graph" />
                <asp:Button runat="server" ID="btnExport" Text="Export Image" />
            </li>
        </ul>    
    </asp:Panel>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
<asp:HiddenField runat="server" Value="" ID="hdnBatchID" />

<asp:DropDownList runat="server" ID="ddlChartType">
    <asp:ListItem Value="3" Text="Line" Selected="True"/>
    <asp:ListItem Value="0" Text="Point"/>
    <asp:ListItem Value="2" Text="Bubble"/>
    <asp:ListItem Value="28" Text="BoxPlot" />
    <asp:ListItem Value="4" Text="Spline" />
    <asp:ListItem Value="24" Text="RangeColumn" />
</asp:DropDownList>

<br /><asp:Label runat="server" ID="lblErrorMessage" Visible="false" />

<asp:Chart runat="server" ID="chtGraph" Width="1200px" Height="800px"></asp:Chart>

<br /><br />
<asp:Panel ID="pnlData" runat="server" Visible="true"></asp:Panel>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>