Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Dal

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class LookupsManager
        Inherits REMIManagerBase

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLookups(ByVal type As REMI.Contracts.LookupType, ByVal productID As Int32, ByVal parentID As Int32, ByVal ParentLookupType As String, ByVal ParentLookupValue As String, ByVal RequestTypeID As Int32, ByVal ShowAdminSelected As Boolean, ByVal RemoveFirst As Int32, ByVal showArchived As Boolean) As DataTable
            Try
                Return GetLookups(type.ToString(), productID, parentID, ParentLookupType, ParentLookupValue, RequestTypeID, ShowAdminSelected, RemoveFirst, showArchived)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Lookups")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLookupTypes(ByVal showSystemTypes As Boolean) As DataTable
            Try
                Return LookupsDB.GetLookupTypes(showSystemTypes)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("LookupTypes")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetLookups(ByVal type As String, ByVal productID As Int32, ByVal parentID As Int32, ByVal ParentLookupType As String, ByVal ParentLookupValue As String, ByVal RequestTypeID As Int32, ByVal ShowAdminSelected As Boolean, ByVal RemoveFirst As Int32, ByVal showArchived As Boolean) As DataTable
            Try
                'All Test Centers
                Dim dt As DataTable = LookupsDB.GetLookups(type, productID, parentID, ParentLookupType, ParentLookupValue, RequestTypeID, ShowAdminSelected, showArchived)

                If (type = "TestCenter") Then
                    dt.Rows(0).Item("LookupType") = "All Test Centers"
                ElseIf (type = "Department") Then
                    dt.Rows(0).Item("LookupType") = "All Departments"
                End If

                If (ShowAdminSelected) Then
                    dt.Rows(0).Item("LookupType") = "Not Set"
                End If

                If RemoveFirst = 1 And dt.Rows.Count > 1 Then
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
            End Try

            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function SaveLookupType(ByVal lookupType As String) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                If ((From l In instance.LookupTypes Where l.Name = lookupType Select l).FirstOrDefault() Is Nothing) Then
                    Dim lt As New REMI.Entities.LookupType
                    lt.Name = lookupType

                    instance.AddToLookupTypes(lt)
                    instance.SaveChanges()
                End If

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function SaveLookupHierarchy(ByVal ParentLookupTypeID As Int32, ByVal ChildLookupTypeID As Int32, ByVal ParentLookupID As Int32, ByVal RequestTypeID As Int32, ByVal items As Web.UI.WebControls.ListItemCollection) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                For Each i As Web.UI.WebControls.ListItem In items
                    Dim childLookupID As Int32
                    Int32.TryParse(i.Value, childLookupID)

                    Dim lh As REMI.Entities.LookupsHierarchy = (From l In instance.LookupsHierarchies Where l.ParentLookupTypeID = ParentLookupTypeID And l.ParentLookupID = ParentLookupID And l.ChildLookupTypeID = ChildLookupTypeID And l.RequestTypeID = RequestTypeID And l.ChildLookupID = childLookupID Select l).FirstOrDefault()

                    If (lh Is Nothing And i.Selected) Then
                        lh = New REMI.Entities.LookupsHierarchy
                        lh.ParentLookupID = ParentLookupID
                        lh.ParentLookupTypeID = ParentLookupTypeID
                        lh.ChildLookupID = childLookupID
                        lh.ChildLookupTypeID = ChildLookupTypeID
                        lh.RequestTypeID = RequestTypeID

                        instance.AddToLookupsHierarchies(lh)
                    ElseIf (lh IsNot Nothing And Not i.Selected) Then
                        instance.DeleteObject(lh)
                    End If
                Next

                instance.SaveChanges()
                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
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
            End Try

            Return -1
        End Function
    End Class
End Namespace