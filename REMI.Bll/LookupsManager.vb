Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Dal

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class LookupsManager
        Inherits REMIManagerBase

        Public Shared Function GetLookups(ByVal type As REMI.Contracts.LookupType, ByVal productID As Int32, ByVal parentID As Int32, Optional ByVal RemoveFirst As Int32 = 0) As DataTable
            Try
                'All Test Centers
                Dim dt As DataTable = LookupsDB.GetLookups(type, productID, parentID)

                If (type = Contracts.LookupType.TestCenter) Then
                    dt.Rows(0).Item("LookupType") = "All Test Centers"
                End If

                If RemoveFirst = 1 Then
                    dt.Rows(0).Delete()
                    dt.AcceptChanges()
                End If
                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Lookups")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function SaveLookup(ByVal lookupType As String, ByVal value As String, ByVal isActive As Int32, ByVal description As String, ByVal parentID As Int32) As Boolean
            Try
                Return LookupsDB.SaveLookup(lookupType, value, isActive, description, parentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e6", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLookupID(ByVal type As REMI.Contracts.LookupType, ByVal lookup As String, ByVal parentID As Int32) As Int32
            Try
                Return LookupsDB.GetLookupID(type, lookup, parentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e6", NotificationType.Errors, ex)
                Return -1
            End Try
        End Function

        ''' <summary>
        ''' Gets a list of Product Types from the database.
        ''' </summary>
        ''' <returns> A collection of products.</returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetOracleProductTypeList() As List(Of String)
            Try
                Return LookupsDB.GetOracleProductTypeList()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e6", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function

        ''' <summary>
        ''' Gets a list of AccessoryGroups from the database.
        ''' </summary>
        ''' <returns> A collection of Accessorys.</returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetOracleAccessoryGroupList() As List(Of String)
            Try
                Return LookupsDB.GetOracleAccessoryList()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e6", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function

        ''' <summary>
        ''' Gets a list of AccessoryGroups from the database.
        ''' </summary>
        ''' <returns> A collection of Accessorys.</returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetOracleTestCentersList() As List(Of String)
            Try
                Return LookupsDB.GetOracleTestCentersList()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e6", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function
    End Class
End Namespace