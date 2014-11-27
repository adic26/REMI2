Imports REMI.Validation
Imports System.Web.Security
Imports System.DirectoryServices.ActiveDirectory
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities
    ''' <summary>
    ''' <para>The user class allows permanent user information to be stored such as the user's role </para>
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class User
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _ldapName As String
        Private _productGroups As DataTable
        Private _userDetails As DataTable
        Private _productGroupsNames As List(Of String)
        Private _roles As List(Of String)
        Private _detailsNames As List(Of String)
        Private _badgeNumber As Integer
        Private _isActive As Int32
        Private _byPassProduct As Int32
        Private _jobTitle As String
        Private _fullName As String
        Private _emailAddress As String
        Private _defaultPage As String
        Private _extension As String
        Private _existsInREMI As Boolean
        Private _canDelete As Int32
        Private _training As DataTable
        Private _services As DataTable
        Private _requestTypes As DataTable
        Private _trainingNames As List(Of String)
#End Region

#Region "Constructor"
        Public Sub New()
            _productGroups = New DataTable("ProductGroups")
            _services = New DataTable("Services")
            _productGroupsNames = New List(Of String)
            _training = New DataTable("Training")
            _userDetails = New DataTable("UserDetails")
            _requestTypes = New DataTable("RequestTypes")
            _trainingNames = New List(Of String)
            _detailsNames = New List(Of String)
            _roles = New List(Of String)
            _ldapName = String.Empty
            _jobTitle = String.Empty
            _fullName = String.Empty
            _emailAddress = String.Empty
            _extension = String.Empty
            _isActive = 1
            _byPassProduct = 1
            _defaultPage = "ScanForInfo/default.aspx"
        End Sub
#End Region

#Region "Public Properties"
        <XmlIgnore()> _
        Public Property ExistsInREMI() As Boolean
            Get
                Return _existsInREMI
            End Get
            Set(ByVal value As Boolean)
                _existsInREMI = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property RequiresSuppAuth() As Boolean
            Get
                Dim ex1 As Boolean
                'check if the user is set up in remi and has been set to require a badge scan
                If Not String.IsNullOrEmpty(_ldapName) Then
                    ex1 = Roles.IsUserInRole(_ldapName, "SupplementaryAuthenticationRequired")
                Else
                    ex1 = True
                End If

                'or check if the user does not have permission to access remi. 
                Return ex1
            End Get
        End Property

        Public Property BadgeNumber() As Integer
            Get
                Return _badgeNumber
            End Get
            Set(ByVal value As Integer)
                _badgeNumber = value
            End Set
        End Property

        Public Property ByPassProduct() As Int32
            Get
                Return _byPassProduct
            End Get
            Set(value As Int32)
                _byPassProduct = value
            End Set
        End Property

        Public Property IsActive() As Int32
            Get
                Return _isActive
            End Get
            Set(ByVal value As Int32)
                _isActive = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property CanDelete() As Int32
            Get
                Return _canDelete
            End Get
            Set(ByVal value As Int32)
                _canDelete = value
            End Set
        End Property

        Public Property DefaultPage() As String
            Get
                Return _defaultPage
            End Get
            Set(ByVal value As String)
                _defaultPage = value
            End Set
        End Property

        Public ReadOnly Property TestCentre() As String
            Get
                Return If(UserDetails Is Nothing, String.Empty, (From ud In UserDetails.AsEnumerable() Where ud.Field(Of String)("Name") = "TestCenter" And ud.Field(Of Boolean)("IsDefault") = True Select ud.Field(Of String)("Values")).FirstOrDefault())
            End Get
        End Property

        Public ReadOnly Property TestCentreID() As Int32
            Get
                Return If(UserDetails Is Nothing, 0, (From ud In UserDetails.AsEnumerable() Where ud.Field(Of String)("Name") = "TestCenter" And ud.Field(Of Boolean)("IsDefault") = True Select ud.Field(Of Int32)("LookupID")).FirstOrDefault())
            End Get
        End Property

        Public ReadOnly Property Department() As String
            Get
                Return If(UserDetails Is Nothing, String.Empty, (From ud In UserDetails.AsEnumerable() Where ud.Field(Of String)("Name") = "Department" And ud.Field(Of Boolean)("IsDefault") = True Select ud.Field(Of String)("Values")).FirstOrDefault())
            End Get
        End Property

        Public ReadOnly Property DepartmentID() As Int32
            Get
                Return If(UserDetails Is Nothing, 0, (From ud In UserDetails.AsEnumerable() Where ud.Field(Of String)("Name") = "Department" And ud.Field(Of Boolean)("IsDefault") = True Select ud.Field(Of Int32)("LookupID")).FirstOrDefault())
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the LDAP username of the user.
        ''' </summary>
        <NotNullOrEmpty(Message:="The LDAP Name must be set. ")> _
        <ValidStringLength(Message:="The LDAP name must be less than 255 characters.", MaxLength:=255)> _
        Public Property LDAPName() As String
            Get
                If _ldapName.StartsWith("RIMNET\") Then
                    Return _ldapName.Remove(0, 7)
                Else
                    Return _ldapName
                End If
            End Get
            Set(ByVal value As String)
                _ldapName = value
            End Set
        End Property

        Public ReadOnly Property UserName() As String
            Get
                If _ldapName.StartsWith("RIMNET\") Then
                    Return _ldapName.Remove(0, 7)
                Else
                    Return _ldapName
                End If
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the list of productgroups the user is managing.
        ''' </summary>
        Public Property ProductGroups() As DataTable
            Get
                Return _productGroups
            End Get
            Set(ByVal value As DataTable)
                If value IsNot Nothing Then
                    _productGroups = value
                End If
            End Set
        End Property

        Public Property RequestTypes() As DataTable
            Get
                Return _requestTypes
            End Get
            Set(ByVal value As DataTable)
                If value IsNot Nothing Then
                    _requestTypes = value
                End If
            End Set
        End Property

        Public Property Services() As DataTable
            Get
                Return _services
            End Get
            Set(ByVal value As DataTable)
                If value IsNot Nothing Then
                    _services = value
                End If
            End Set
        End Property

        Public Property UserDetails() As DataTable
            Get
                Return _userDetails
            End Get
            Set(ByVal value As DataTable)
                If value IsNot Nothing Then
                    _userDetails = value
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property DetailsNames() As List(Of String)
            Get
                Return _detailsNames
            End Get
            Set(ByVal value As List(Of String))
                If value IsNot Nothing Then
                    _detailsNames = value
                End If
            End Set
        End Property

        Public Property Training() As DataTable
            Get
                Return _training
            End Get
            Set(ByVal value As DataTable)
                If value IsNot Nothing Then
                    _training = value
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property TrainingNames() As List(Of String)
            Get
                Return _trainingNames
            End Get
            Set(ByVal value As List(Of String))
                If value IsNot Nothing Then
                    _trainingNames = value
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property ProductGroupsNames() As List(Of String)
            Get
                Return _productGroupsNames
            End Get
            Set(ByVal value As List(Of String))
                If value IsNot Nothing Then
                    _productGroupsNames = value
                End If
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the list of roles that the user is a member of.
        ''' </summary>
        <XmlIgnore()> _
        Public Property RolesList() As List(Of String)
            Get
                Return _roles
            End Get
            Set(ByVal value As List(Of String))
                _roles = value
            End Set
        End Property

        Public Property EmailAddress() As String
            Get
                Return _emailAddress
            End Get
            Set(ByVal value As String)
                _emailAddress = value
            End Set
        End Property

        Public Property FullName() As String
            Get
                Return _fullName
            End Get
            Set(ByVal value As String)
                _fullName = value
            End Set
        End Property

        Public Property Extension() As String
            Get
                Return _extension
            End Get
            Set(ByVal value As String)
                _extension = value
            End Set
        End Property

        Public Property JobTitle() As String
            Get
                Return _jobTitle
            End Get
            Set(ByVal value As String)
                _jobTitle = value
            End Set
        End Property

        ''' <summary>
        ''' Overrides the default tostring to return the LDAP name of the user.
        ''' </summary>
        ''' <returns>The LDAP name of the user</returns>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(_ldapName) Then
                Return String.Empty
            Else
                Return _ldapName
            End If
        End Function
#End Region

#Region "User Access"
        ''' <summary>
        ''' Checks if the user has the authority to perform certain actions in the system. mostly to do with setting result reviews and such.
        ''' </summary>
        Public Function HasRetestAuthority(ByVal ProductGroupName As String) As Boolean
            Return CheckPermission("HasRetestAuthority", ProductGroupName, 0)
        End Function

        Public Function HasFALowTestingAuthority(ByVal productGroupName As String) As Boolean
            Return CheckPermission("HasFALowTestingAuthority", productGroupName, 0)
        End Function

        Public Function HasFAHighTestingAuthority(ByVal productGroupName As String) As Boolean
            Return CheckPermission("HasFAHighTestingAuthority", productGroupName, 0)
        End Function

        Public Function HasFATestingAuthority(ByVal ProductGroupName As String) As Boolean
            Return HasFAHighTestingAuthority(ProductGroupName) Or HasFALowTestingAuthority(ProductGroupName)
        End Function

        Public Function HasLastScanLocationOverride() As Boolean
            Return CheckPermission("HasLastScanLocationOverride", String.Empty, 0)
        End Function

        Public Function HasAdjustPriorityAuthority() As Boolean
            Return CheckPermission("HasAdjustPriorityAuthority", String.Empty, 0)
        End Function

        Public Function HasEditBatchCommentsAuthority(ByVal batchDepartmentID As Int32) As Boolean
            Return CheckPermission("HasEditBatchCommentsAuthority", String.Empty, batchDepartmentID)
        End Function

        Public Function HasTaskAssignmentAuthority() As Boolean
            Return CheckPermission("HasTaskAssignmentAuthority", String.Empty, 0)
        End Function

        Public Function HasFAAssignmentAuthority() As Boolean
            Return CheckPermission("HasFAAssignmentAuthority", String.Empty, 0)
        End Function

        Public Function HasOverrideCompletedTestAuthority() As Boolean
            Return CheckPermission("HasOverrideCompletedTestAuthority", String.Empty, 0)
        End Function

        Public Function HasScanForTestAuthority(ByVal batchDepartmentID As Int32) As Boolean
            If Roles.IsUserInRole(_ldapName, "SupplementaryAuthenticationRequired") Then
                Return True
            Else
                Return CheckPermission("HasScanForTestAuthority", String.Empty, batchDepartmentID)
            End If
        End Function

        Public Function HasEditItemAuthority(ByVal productGroup As String, ByVal batchDepartmentID As Int32) As Boolean
            Return CheckPermission("HasEditItemAuthority", productGroup, batchDepartmentID)
        End Function

        Public Function HasUploadConfigXML() As Boolean
            Return CheckPermission("HasUploadConfigXML", String.Empty, 0)
        End Function

        Public Function HasDocumentAuthority() As Boolean
            Return CheckPermission("HasDocumentAuthority", String.Empty, 0)
        End Function

        Public Function HasAdminReadOnlyAuthority() As Boolean
            Return CheckPermission("HasAdminReadOnlyAuthority", String.Empty, 0)
        End Function

        Public Function HasRelabAuthority() As Boolean
            Return CheckPermission("HasRelabAuthority", String.Empty, 0)
        End Function

        Public Function HasBatchSetupAuthority(ByVal batchDepartmentID As Int32) As Boolean
            Return CheckPermission("HasBatchSetupAuthority", String.Empty, batchDepartmentID)
        End Function
#End Region

#Region "HAS ROLE"
        <XmlIgnore()> _
        Public ReadOnly Property IsAdmin() As Boolean
            Get
                Return RolesList.Contains("Administrator")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsIncomingSpecialist() As Boolean
            Get
                Return RolesList.Contains("IncomingSpecialist")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsMaterialsManagementSpecialist() As Boolean
            Get
                Return RolesList.Contains("MaterialsManagementSpecialist")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsLabTestCoordinator() As Boolean
            Get
                Return RolesList.Contains("LabTestCoordinator")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsLabTechOpsManager() As Boolean
            Get
                Return RolesList.Contains("LabTechOpsManager")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsProjectManager() As Boolean
            Get
                Return RolesList.Contains("ProjectManager")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsDeveloper() As Boolean
            Get
                Return RolesList.Contains("Developer")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property HasRelabAccess() As Boolean
            Get
                Return RolesList.Contains("Relab")
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsTestCenterAdmin() As Boolean
            Get
                Return RolesList.Contains("TestCenterAdmin")
            End Get
        End Property
#End Region

        Private Function CheckPermission(ByVal Permission As String, ByVal productGroupName As String, ByVal batchDepartmentID As Int32) As Boolean
            Dim roles As DataTable = REMIAppCache.GetRolesByPermission(Permission)
            Dim hasPerm As Boolean = False

            If (roles Is Nothing) Then
                roles = GetRolesByPermission(Permission)
                REMIAppCache.SetRolesByPermission(Permission, roles)
            End If

            For Each role As DataRow In roles.Rows
                hasPerm = RolesList.Contains(role.Item("RoleName").ToString())
                Dim hasProductCheck As Boolean = False
                Boolean.TryParse(role.Item("hasProductCheck").ToString(), hasProductCheck)

                If (hasProductCheck And ByPassProduct = 0) Then
                    Dim product = (From p In ProductGroups _
                                    Where p.Item("ProductGroupName").ToString() = productGroupName _
                                    Select productGroup = p.Item("ProductGroupName").ToString())
                    If (Not (product.Contains(productGroupName))) Then
                        hasPerm = False
                    End If
                End If

                If (hasPerm) Then
                    Dim departments As List(Of Int32) = (From ud In UserDetails.AsEnumerable() Where ud.Field(Of String)("Name") = "Department" Select ud.Field(Of Int32)("LookupID")).ToList()

                    If (batchDepartmentID > 0) Then
                        If (Not (departments.Contains(batchDepartmentID)) And Not IsAdmin And Not IsTestCenterAdmin) Then
                            hasPerm = False
                        End If
                    End If

                    Exit For
                End If
            Next

            Return hasPerm
        End Function

        Private Shared Function GetRolesByPermission(ByVal permissionName As String) As DataTable
            Dim dt As New DataTable("Roles")

            Using myConnection As New SqlClient.SqlConnection(Core.REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlClient.SqlCommand("aspnet_GetRolesByPermission", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ApplicationName", "/")
                    myCommand.Parameters.AddWithValue("@PermissionName", permissionName)
                    myConnection.Open()
                    Dim da As SqlClient.SqlDataAdapter = New SqlClient.SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Roles"
                End Using
            End Using

            Return dt
        End Function
    End Class
End Namespace