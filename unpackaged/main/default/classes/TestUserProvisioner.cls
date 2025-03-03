@isTest
public with sharing class TestUserProvisioner {
    private Set<Id> requiredPermissionIds = new Set<Id>();
    private Set<Id> requiredPermissionGroupIds = new Set<Id>();
    private Set<Id> requiredLicenseIds = new Set<Id>();
    private Id userId;
    private static Profile defaultProfile;

    public TestUserProvisioner(Id userId) {
        this.userId = userId;
    }

    public void setPermissionSetGroup(String permissionGroupName) {
        requiredPermissionGroupIds.addAll(
            new Map<Id, PermissionSetGroup>(
                    [
                        SELECT Id
                        FROM PermissionSetGroup
                        WHERE MasterLabel = :permissionGroupName
                    ]
                )
                .keySet()
        );
    }

    public void setPermission(String permissionName) {
        setPermissions(new List<String>{ permissionName });
    }

    public void setPermissions(List<String> permissionNames) {
        this.requiredPermissionIds = new Map<Id, PermissionSet>(
                [SELECT Id FROM PermissionSet WHERE Name IN :permissionNames]
            )
            .keySet();
    }

    public void setLicenses(List<String> permissionNames) {
        this.requiredLicenseIds = new Map<Id, PermissionSetLicense>(
                [
                    SELECT Id
                    FROM PermissionSetLicense
                    WHERE DeveloperName IN :permissionNames
                ]
            )
            .keySet();
    }

    public void assignPermissions() {
        if (
            requiredPermissionIds.isEmpty() &&
            requiredLicenseIds.isEmpty() &&
            requiredPermissionGroupIds.isEmpty()
        ) {
            throw new TestUserProvisionerException(
                'No permissions were set to assign.'
            );
        }

        TestUserProvisioner.assignPermissions(
            requiredPermissionIds,
            requiredLicenseIds,
            requiredPermissionGroupIds,
            userId
        );
    }

    public static List<User> getNewUsers(Integer count) {
        if (defaultProfile == null) {
            setDefaultProfile();
        }

        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            String unique = 'getNewUser' + String.valueOf(i);
            users.add(
                new User(
                    LastName = 'TestUserProvisioner',
                    Email = unique + '@TestUserProvisioner.com',
                    UserName = unique + '@TestUserProvisioner.com',
                    Alias = 'gnUTUP',
                    ProfileId = defaultProfile.Id,
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    IsActive = true
                )
            );
        }
        return users;
    }

    public static User getNewUser() {
        return getNewUsers(1)[0];
    }

    private static void setDefaultProfile() {
        defaultProfile = [SELECT Id FROM Profile WHERE Name = 'Sales'];
    }

    @future
    public static void insertUsers(String usersJson) {
        List<User> users = (List<User>) JSON.deserialize(
            usersJson,
            List<User>.class
        );
        insert users;
    }

    @future
    private static void assignPermissions(
        Set<Id> requiredPermissionIds,
        Set<Id> requiredLicenseIds,
        Set<Id> requiredPermissionSetGroupIds,
        Id userId
    ) {
        List<PermissionSetLicenseAssign> missingLicenses = getMissingLicenses(
            requiredLicenseIds,
            userId
        );
        insert missingLicenses;

        List<PermissionSetAssignment> missingPermissions = getMissingAssignments(
            requiredPermissionIds,
            requiredPermissionSetGroupIds,
            userId
        );
        insert missingPermissions;
    }

    private static List<PermissionSetAssignment> getMissingAssignments(
        Set<Id> requiredPermissionIds,
        Set<Id> requiredPermissionGroupsIds,
        Id userId
    ) {
        List<PermissionSetAssignment> currentAssignments = [
            SELECT Id, PermissionSetId, PermissionSetGroupId
            FROM PermissionSetAssignment
            WHERE
                AssigneeId = :userId
                AND (PermissionSetId IN :requiredPermissionIds
                OR PermissionSetGroupId IN :requiredPermissionGroupsIds)
        ];

        Set<Id> assignedPermissionSetIds = new Set<Id>();
        for (PermissionSetAssignment assignment : currentAssignments) {
            assignedPermissionSetIds.add(assignment.PermissionSetId);
            assignedPermissionSetIds.add(assignment.PermissionSetGroupId);
        }

        requiredPermissionIds.removeAll(assignedPermissionSetIds);
        requiredPermissionGroupsIds.removeAll(assignedPermissionSetIds);

        List<PermissionSetAssignment> missingAssignments = new List<PermissionSetAssignment>();
        for (Id permissionId : requiredPermissionIds) {
            missingAssignments.add(
                new PermissionSetAssignment(
                    PermissionSetId = permissionId,
                    AssigneeId = userId
                )
            );
        }

        for (Id permissionGroupId : requiredPermissionGroupsIds) {
            missingAssignments.add(
                new PermissionSetAssignment(
                    PermissionSetGroupId = permissionGroupId,
                    AssigneeId = userId
                )
            );
        }

        return missingAssignments;
    }

    private static List<PermissionSetLicenseAssign> getMissingLicenses(
        Set<Id> requiredLicenseIds,
        Id userId
    ) {
        List<PermissionSetLicenseAssign> currentLicenses = [
            SELECT Id, PermissionSetLicenseId
            FROM PermissionSetLicenseAssign
            WHERE
                AssigneeId = :userId
                AND PermissionSetLicenseId IN :requiredLicenseIds
        ];

        Set<Id> assignedLicenseIds = new Set<Id>();
        for (PermissionSetLicenseAssign assignment : currentLicenses) {
            assignedLicenseIds.add(assignment.PermissionSetLicenseId);
        }

        requiredLicenseIds.removeAll(assignedLicenseIds);

        List<PermissionSetLicenseAssign> missingLicenses = new List<PermissionSetLicenseAssign>();
        for (Id requiredLicenseId : requiredLicenseIds) {
            missingLicenses.add(
                new PermissionSetLicenseAssign(
                    PermissionSetLicenseId = requiredLicenseId,
                    AssigneeId = userId
                )
            );
        }

        return missingLicenses;
    }

    class TestUserProvisionerException extends Exception {
    }
}