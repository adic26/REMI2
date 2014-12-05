Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Dal

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class LookupsManager
        Inherits REMIManagerBase

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLookups(ByVal type As REMI.Contracts.LookupType, ByVal productID As Int32, ByVal parentID As Int32, ByVal ParentLookupType As String, ByVal ParentLookupValue As String, ByVal RequestTypeID As Int32, Optional ByVal RemoveFirst As Int32 = 0) As DataTable
            Try
                Return GetLookups(type.ToString(), productID, parentID, ParentLookupType, ParentLookupValue, RequestTypeID, RemoveFirst)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Lookups")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetLookups(ByVal type As String, ByVal productID As Int32, ByVal parentID As Int32, ByVal ParentLookupType As String, ByVal ParentLookupValue As String, ByVal RequestTypeID As Int32, Optional ByVal RemoveFirst As Int32 = 0) As DataTable
            Try
                'All Test Centers
                Dim dt As DataTable = LookupsDB.GetLookups(type, productID, parentID, ParentLookupType, ParentLookupValue, RequestTypeID)

                If (type = "TestCenter") Then
                    dt.Rows(0).Item("LookupType") = "All Test Centers"
                ElseIf (type = "Department") Then
                    dt.Rows(0).Item("LookupType") = "All Departments"
                End If

                If RemoveFirst = 1 Then
                    dt.Rows(0).Delete()
                    dt.AcceptChanges()
                End If
                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Lookups")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function SaveLookup(ByVal lookupType As String, ByVal value As String, ByVal isActive As Int32, ByVal description As String, ByVal parentID As Int32) As Boolean
            Try
                Return LookupsDB.SaveLookup(lookupType, value, isActive, description, parentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLookupID(ByVal type As REMI.Contracts.LookupType, ByVal lookup As String, ByVal parentID As Int32) As Int32
            Return GetLookupID(type.ToString(), lookup, parentID)
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetLookupID(ByVal type As String, ByVal lookup As String, ByVal parentID As Int32) As Int32
            Try
                Return LookupsDB.GetLookupID(type, lookup, parentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return -1
            End Try
        End Function
    End Class
End Namespace