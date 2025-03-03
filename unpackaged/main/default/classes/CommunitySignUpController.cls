/**
 * Apex controller for CommunitySignUp LWC
 * Created By OpFocus (Brock Barlow)
 * Created 3/11/2022
 */
public without sharing class CommunitySignUpController {
    public static Boolean testExceptions = false;

    public static void setTestExceptions(Boolean value) {
        testExceptions = value;
    }

    @AuraEnabled
    public static FormData getFormData() {
        try {
            system.debug('testExceptions' + testExceptions);
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }

            FormData data = new FormData();
            // Populate role data TODO: Connect to the correct field
            data.roleOptions = getPicklistValues('Contact', 'Role');
            // Populate country data
            data.countryOptions = getPicklistValues('User', 'Country__c');
            // Populate state data
            data.stateOptions = getPicklistValues('User', 'State__c');
            // Populate relationship data TODO: Connect to the correct field
            data.relationshipOptions = getPicklistValues(
                'Contact',
                'Relationship'
            );
            // Populate time zone data
            data.timeZoneOptions = getPicklistValues('User', 'TimeZoneSidKey');
            // Populate registration data
            data.regData = new RegistrationData();

            return data;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<DropDownOption> getPicklistValues(
        String objectName,
        String fieldName
    ) {
        List<DropDownOption> options = new List<DropDownOption>();
        if (fieldName == 'Relationship') {
            options.add(new DropDownOption('Customer', 'Customer'));
            options.add(new DropDownOption('Partner', 'Partner'));
            options.add(
                new DropDownOption(
                    'Non-customer / Fan / Advocate / Prospect',
                    'Non-customer / Fan / Advocate / Prospect'
                )
            );
            options.add(
                new DropDownOption('Brightcove employee', 'Brightcove employee')
            );
        } else if (fieldName == 'Role') {
            options.add(new DropDownOption('Developer', 'Developer'));
            options.add(new DropDownOption('Administrator', 'Administrator'));
            options.add(new DropDownOption('Architect', 'Architect'));
            options.add(
                new DropDownOption(
                    'Sales Representative / Manager ',
                    'Sales Representative / Manager '
                )
            );
            options.add(new DropDownOption('Marketer', 'Marketer'));
            options.add(
                new DropDownOption('Creative Director', 'Creative Director')
            );
            options.add(new DropDownOption('Executive', 'Executive'));
            options.add(new DropDownOption('Producer', 'Producer'));
            options.add(new DropDownOption('Consultant', 'Consultant'));
            options.add(
                new DropDownOption(
                    'Business Operations Manager ',
                    'Business Operations Manager '
                )
            );
            options.add(new DropDownOption('Designer', 'Designer'));
            options.add(new DropDownOption('Educator', 'Educator'));
            options.add(new DropDownOption('Student', 'Student'));
        } else {
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(
                new List<String>{ objectName }
            );
            List<PicklistEntry> values = results[0]
                .fields.getMap()
                .get(fieldName)
                .getDescribe()
                .getPicklistValues();
            for (PicklistEntry pe : values) {
                options.add(new DropDownOption(pe));
            }
        }
        return options;
    }

    @AuraEnabled
    public static boolean doesUserExist(String username) {
        try {
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }

            List<User> userList = [
                SELECT Id, Name
                FROM User
                WHERE Username = :username OR Email = :username
            ];

            return !userList.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean doesUserNicknameExist(String nickname) {
        try {
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }

            List<User> userList = [
                SELECT Id, Name, CommunityNickname
                FROM User
                WHERE CommunityNickname = :nickname
            ];

            return !userList.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String registerUser(RegistrationData regData) {
        String[] emailInfo = regData.email.split('@');
        //we assume a formatted email
        String emailDomain = emailInfo[1];

        User accountOwner = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'api@brightcove.com%' AND IsActive = TRUE
            LIMIT 1
        ];

        Account myAccount = getAccount(regData, emailDomain, accountOwner);
        Contact myContact = getContact(myAccount, regData, accountOwner);
        User myUser;

        //we should at this point do a final sanity check and make sure there isnt a user record that already exists
        List<User> users = [
            SELECT Id, FirstName, LastName, Username, Email
            FROM User
            WHERE Username = :regData.email
        ];

        if (users.isEmpty()) {
            //get our profile Id
            Id profileId = [
                SELECT Id
                FROM Profile
                WHERE Name = :Label.BrightSpotProfileName
                LIMIT 1
            ]
            .Id;
            //no user, so lets make one
            myUser = new User(
                FirstName = regData.firstName,
                LastName = regData.lastName,
                Email = regData.email,
                Username = regData.email,
                Alias = regData.firstName.toLowerCase().left(2) +
                    regData.lastName.toLowerCase().left(4),
                ContactId = myContact.Id,
                EmailEncodingKey = 'UTF-8',
                CompanyName = regData.myCompany,
                My_Role__c = regData.myRole,
                Relationship_to_Brightcove__c = regData.relationshipToBrightcove,
                Country__c = regData.mailingCountry,
                State__c = regData.mailingState,
                CommunityNickname = regData.nickname,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = profileId
            );

            insert myUser;
        } else {
            //grab the first user and update it from the form
            myUser = users[0];
            myUser.CompanyName = regData.myCompany;
            myUser.My_Role__c = regData.myRole;
            myUser.Relationship_to_Brightcove__c = regData.relationshipToBrightcove;
            myUser.Country__c = regData.mailingCountry;
            myUser.State__c = regData.mailingState;

            update myUser;
        }

        if (Test.isRunningTest() && testExceptions) {
            myUser = null;
        }

        if (myUser?.Id != null) {
            PageReference page = new PageReference(
                '/login/CheckPasswordResetEmail'
            );
            page.setRedirect(true);
            return page.getUrl();
        }

        return 'error';
    }

    private static Account getAccount(
        RegistrationData regData,
        String emailDomain,
        User accountOwner
    ) {
        Account myAccount;

        List<Account> matchingAccounts = [
            SELECT Id, Name, Type, LastActivityDate, OwnerId
            FROM Account
            WHERE
                Email_Domain_Name__c = :emailDomain
                OR Name = :regData.myCompany
            ORDER BY LastActivityDate DESC
        ];

        //no matches, create a new account
        if (matchingAccounts.isEmpty()) {
            myAccount = new Account(
                Name = regData.myCompany,
                Email_Domain_Name__c = emailDomain,
                Master_Record__c = false,
                BillingCountryCode = regData.mailingCountry,
                BillingState = regData.mailingState,
                AccountSource = 'CX Community',
                OwnerId = accountOwner.Id
            );

            insert myAccount;

            return myAccount;
        }

        //matches
        Boolean hasCustomerAccount = false;
        Date latestActivityDate = null;

        //check if any are of type = 'customer' and use that
        for (Account thisAccount : matchingAccounts) {
            if (thisAccount.Type == 'Customer') {
                myAccount = thisAccount;
                hasCustomerAccount = true;
            }
        }

        //no customer type records, use the one with the latest lastactivitydate
        if (!hasCustomerAccount) {
            for (Account thisAccount : matchingAccounts) {
                if (
                    latestActivityDate == null ||
                    thisAccount.LastActivityDate > latestActivityDate
                ) {
                    latestActivityDate = thisAccount.LastActivityDate;
                    myAccount = thisAccount;
                    hasCustomerAccount = true;
                }
            }
        }

        return myAccount;
    }

    private static Contact getContact(
        Account myAccount,
        RegistrationData regData,
        User accountOwner
    ) {
        Boolean createContact = false;
        Contact myContact;

        //check for contact records on this account
        List<Contact> myContacts = [
            SELECT
                Id,
                FirstName,
                LastName,
                Email,
                My_Role__c,
                Relationship_with_Brightcove__c,
                MailingCountryCode,
                MailingState
            FROM Contact
            WHERE AccountId = :myAccount.Id AND Email = :regData.email
        ];

        if (myContacts.isEmpty()) {
            createContact = true;
        } else {
            myContact = myContacts[0];
            myContact.My_Role__c = regData.myRole;
            myContact.Relationship_with_Brightcove__c = regData.relationshipToBrightcove;
            myContact.Agreed_To_Terms_Conditions__c = regData.agreedToTandC;
            myContact.MailingCountryCode = regData.mailingCountry;
            myContact.MailingState = regData.mailingState;

            update myContact;
        }

        if (createContact) {
            //create a new contact if we need to
            myContact = new Contact(
                FirstName = regData.firstName,
                LastName = regData.lastName,
                Email = regData.email,
                Communication_Opt_Out__c = true,
                AccountId = myAccount.Id,
                LeadSource = 'CX Community',
                My_Role__c = regData.myRole,
                Relationship_with_Brightcove__c = regData.relationshipToBrightcove,
                Agreed_To_Terms_Conditions__c = regData.agreedToTandC,
                MailingCountryCode = regData.mailingCountry,
                MailingState = regData.mailingState,
                OwnerId = myAccount.OwnerId
            );

            insert myContact;
        }

        return myContact;
    }

    @AuraEnabled
    public static Boolean doesUserAcceptTandC() {
        try {
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }
            User myUser = [
                SELECT Id, Name, Agreed_to_Bright_Spot_T_C__c, UserType
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            if (
                myUser.UserType == 'Standard' ||
                myUser.Name == 'The Bright Spot Site Guest User'
            ) {
                return true;
            }

            return myUser.Agreed_to_Bright_Spot_T_C__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static User getCurrentUserInfo() {
        try {
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }
            return [
                SELECT Id, CommunityNickname, CompanyName, My_Role__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer updateExistingContactAndUser(
        RegistrationData regData
    ) {
        try {
            if (Test.isRunningTest() && testExceptions) {
                throw new CommunitySignUpControllerException();
            }

            List<sObject> recordsToUpdate = new List<sObject>();
            User myUser = [
                SELECT Id, ContactId, Agreed_to_Bright_Spot_T_C__c, UserType
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
            Contact myContact = [
                SELECT Id
                FROM Contact
                WHERE Id = :myUser.ContactId
            ];

            if (myUser != null) {
                myUser.CompanyName = regData.myCompany;
                myUser.My_Role__c = regData.myRole;
                myUser.Relationship_to_Brightcove__c = regData.relationshipToBrightcove;
                myUser.Country__c = regData.mailingCountry;
                myUser.State__c = regData.mailingState;
                myUser.CommunityNickname = regData.nickname;

                recordsToUpdate.add(myUser);
            }

            if (myContact != null) {
                myContact.My_Role__c = regData.myRole;
                myContact.Relationship_with_Brightcove__c = regData.relationshipToBrightcove;
                myContact.Agreed_To_Terms_Conditions__c = regData.agreedToTandC;
                myContact.MailingCountryCode = regData.mailingCountry;
                myContact.MailingState = regData.mailingState;

                recordsToUpdate.add(myContact);
            }

            update recordsToUpdate;

            return 0;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CommunitySignUpControllerException extends Exception {
    }

    public class RegistrationData {
        @AuraEnabled
        public String firstName { get; set; }
        @AuraEnabled
        public String lastName { get; set; }
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String nickname { get; set; }
        @AuraEnabled
        public String password { get; set; }
        @AuraEnabled
        public String username { get; set; }
        @AuraEnabled
        public String mailingState { get; set; }
        @AuraEnabled
        public String mailingCountry { get; set; }
        @AuraEnabled
        public String myRole { get; set; }
        @AuraEnabled
        public String userTimeZone { get; set; }
        @AuraEnabled
        public String myCompany { get; set; }
        @AuraEnabled
        public String relationshipToBrightcove { get; set; }
        @AuraEnabled
        public DateTime agreedToTandC { get; set; }
    }

    public class FormData {
        @AuraEnabled
        public RegistrationData regData { get; set; }
        @AuraEnabled
        public List<DropDownOption> roleOptions { get; set; }
        @AuraEnabled
        public List<DropDownOption> countryOptions { get; set; }
        @AuraEnabled
        public List<DropDownOption> stateOptions { get; set; }
        @AuraEnabled
        public List<DropDownOption> timeZoneOptions { get; set; }
        @AuraEnabled
        public List<DropDownOption> relationshipOptions { get; set; }
    }

    public class DropDownOption {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }

        public DropDownOption(PickListEntry pe) {
            value = pe.getValue();
            label = pe.getLabel();
        }

        public DropDownOption(String label, String value) {
            this.value = value;
            this.label = label;
        }
    }
}