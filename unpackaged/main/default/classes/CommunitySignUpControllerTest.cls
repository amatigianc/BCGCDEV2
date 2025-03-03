@IsTest
public class CommunitySignUpControllerTest {
  @TestSetup
  static void makeData() {
    Contact contact = ContactTestFactory.createContact();

    User user = TestUserProvisioner.getNewUser();
    user.ProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'BrightSpot Community Login User'
    ]
    .Id;
    user.ContactId = contact.Id;
    insert user;
  }

  @isTest
  static void testExceptions() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];

    Boolean formDataException = false;
    Boolean existingUsernameException = false;
    Boolean existingNicknameException = false;
    Boolean getCurrentUserInfoException = false;
    Boolean doesUserAcceptTandCException = false;
    Boolean updateExistingContactAndUserException = false;

    CommunitySignUpController.setTestExceptions(true);

    CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
    regData.firstName = 'John';
    regData.lastName = 'Pisano';
    regData.email = 'jpisano02@example.com';
    regData.myCompany = 'JP Industries LLC';
    regData.myRole = 'Developer';
    regData.nickname = 'John Pisano 123';
    regData.mailingCountry = 'US';
    regData.mailingState = 'Massachusetts';
    regData.relationshipToBrightcove = 'Customer';
    regData.agreedToTandC = System.now();

    String result;

    System.runAs(guestSiteUser) {
      result = CommunitySignUpController.registerUser(regData);
    }

    System.assertEquals(result, 'error', 'No Error when registering user');

    try {
      CommunitySignUpController.getFormData();
    } catch (Exception e) {
      formDataException = true;
    }

    try {
      CommunitySignUpController.doesUserExist('Fail');
    } catch (Exception e) {
      existingUsernameException = true;
    }

    try {
      CommunitySignUpController.doesUserNicknameExist('Fail');
    } catch (Exception e) {
      existingNicknameException = true;
    }

    try {
      CommunitySignUpController.getCurrentUserInfo();
    } catch (Exception e) {
      getCurrentUserInfoException = true;
    }

    try {
      CommunitySignUpController.doesUserAcceptTandC();
    } catch (Exception e) {
      doesUserAcceptTandCException = true;
    }

    try {
      CommunitySignUpController.updateExistingContactAndUser(regData);
    } catch (Exception e) {
      updateExistingContactAndUserException = true;
    }

    CommunitySignUpController.setTestExceptions(false);

    System.assert(
      formDataException,
      'An Exception was not thrown while getting form data'
    );
    System.assert(
      existingUsernameException,
      'An Exception was not thrown while checking for username'
    );
    System.assert(
      existingNicknameException,
      'An Exception was not thrown while checking for nickname'
    );
    System.assert(
      getCurrentUserInfoException,
      'An Exception was not thrown while checking current user info'
    );
    System.assert(
      doesUserAcceptTandCException,
      'An Exception was not thrown while checking for checking accepted T&Cs'
    );
    System.assert(
      updateExistingContactAndUserException,
      'An Exception was not thrown while checking for updating existing user and contact'
    );
  }

  @IsTest
  static void testNewAccountAndUser() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];

    CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
    regData.firstName = 'John';
    regData.lastName = 'Pisano';
    regData.email = 'jpisano02@example.com';
    regData.myCompany = 'JP Industries LLC';
    regData.myRole = 'Developer';
    regData.mailingCountry = 'US';
    regData.mailingState = 'Massachusetts';
    regData.relationshipToBrightcove = 'Customer';
    regData.agreedToTandC = System.now();

    String result;

    System.runAs(guestSiteUser) {
      result = CommunitySignUpController.registerUser(regData);
    }

    System.assertNotEquals(result, 'error', 'Error when registering user');

    Account newAccount = [
      SELECT Id, Name
      FROM Account
      WHERE Name = :regData.myCompany
      LIMIT 1
    ];

    System.assert(newAccount != null, 'Account not created successfully');
    System.assert(
      newAccount.Name == regData.myCompany,
      'Account not created with correct name'
    );

    Contact newContact = [
      SELECT Id, FirstName, LastName, Email, AccountId
      FROM Contact
      WHERE Email = :regData.email AND AccountId = :newAccount.Id
      LIMIT 1
    ];

    System.assert(newContact != null, 'Contact not created successfully');
    System.assert(
      newContact.Email == regData.email,
      'Contact not created with correct email'
    );
  }

  @IsTest
  static void testExistingContactAndUser() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];

    User userDataFirstPass;
    User userDataSecondPass;
    User userDataThirdPass;

    String userEmail =
      'testcontact' +
      DateTime.now().format('yyMMddHHmmssZ') +
      '@customeraccount.test';

    Account customerAccount = AccountTestFactory.createCustomer();
    customerAccount.Name = 'Customer Account';
    customerAccount.Email_Domain_Name__c = 'customeraccount.test';

    update customerAccount;

    Contact customerContact = ContactTestFactory.getContact(customerAccount);
    customerContact.FirstName = 'Test';
    customerContact.LastName = 'Contact';
    customerContact.Email = userEmail;

    insert customerContact;

    System.runAs(guestSiteUser) {
      Boolean existsResult = CommunitySignUpController.doesUserExist(
        customerContact.Email
      );
      System.assertEquals(false, existsResult);

      CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
      regData.email = customerContact.Email;
      regData.firstName = customerContact.FirstName;
      regData.lastName = customerContact.LastName;
      regData.password = 'Th1$_@w3$0m3_P@$$w0rd';
      regData.username = regData.email;
      regData.agreedToTandC = Datetime.now();
      regData.mailingCountry = 'US';
      regData.mailingState = 'New York';
      regData.myCompany = 'Test Company';
      regData.myRole = 'Developer';
      regData.relationshipToBrightcove = 'Customer';
      regData.userTimeZone = 'America/New_York';

      String registerResult = CommunitySignUpController.registerUser(regData);
      System.assertNotEquals(null, registerResult);
    }

    userDataFirstPass = [
      SELECT Id, Username, CompanyName, My_Role__c, State__c
      FROM User
      WHERE Username = :userEmail
    ];

    System.runAs(guestSiteUser) {
      Boolean existsResult = CommunitySignUpController.doesUserExist(
        customerContact.Email
      );
      System.assertEquals(true, existsResult);

      CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
      regData.email = customerContact.Email;
      regData.firstName = customerContact.FirstName;
      regData.lastName = customerContact.LastName;
      regData.password = 'Th1$_@w3$0m3_P@$$w0rd';
      regData.username = regData.email;
      regData.agreedToTandC = Datetime.now();
      regData.mailingCountry = 'US';
      regData.mailingState = 'Massachusetts';
      regData.myCompany = 'Another Test Company';
      regData.myRole = 'Administrator';
      regData.relationshipToBrightcove = 'Customer';
      regData.userTimeZone = 'America/New_York';

      String registerResult = CommunitySignUpController.registerUser(regData);
      System.assertNotEquals(null, registerResult);
    }

    userDataSecondPass = [
      SELECT Id, Username, CompanyName, My_Role__c, State__c
      FROM User
      WHERE Username = :userEmail
    ];

    System.runAs(userDataSecondPass) {
      Boolean acceptedTandC = CommunitySignUpController.doesUserAcceptTandC();
      User myUserInfo = CommunitySignUpController.getCurrentUserInfo();

      System.assert(
        acceptedTandC,
        'User has not accepted terms and conditions'
      );
      System.assert(
        myUserInfo.CompanyName == 'Another Test Company',
        'User info doesn\'t match expected'
      );

      CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
      regData.agreedToTandC = Datetime.now();
      regData.mailingCountry = 'US';
      regData.mailingState = 'Hawaii';
      regData.myCompany = 'A Third Test Company';
      regData.myRole = 'Developer';
      regData.nickname = 'The Terminator';
      regData.relationshipToBrightcove = 'Partner';

      CommunitySignUpController.updateExistingContactAndUser(regData);
    }

    userDataThirdPass = [
      SELECT Id, Username, CompanyName, My_Role__c, State__c
      FROM User
      WHERE Username = :userEmail
    ];

    List<Contact> contacts = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Email = :userEmail
    ];
    System.assertEquals(1, contacts.size());
    System.assertEquals(customerContact.Id, contacts[0].Id);
    System.assertEquals(customerContact.AccountId, contacts[0].AccountId);

    System.assert(
      userDataFirstPass.Username == userEmail,
      'Username doesn\'t match pass 1'
    );
    System.assert(
      userDataFirstPass.CompanyName == 'Test Company',
      'Company doesn\'t match pass 1'
    );
    System.assert(
      userDataFirstPass.State__c == 'New York',
      'State doesn\'t match pass 1'
    );

    System.assert(
      userDataSecondPass.Username == userEmail,
      'Username doesn\'t match pass 2'
    );
    System.assert(
      userDataSecondPass.CompanyName == 'Another Test Company',
      'Company doesn\'t match pass 2'
    );
    System.assert(
      userDataSecondPass.State__c == 'Massachusetts',
      'State doesn\'t match pass 2'
    );

    System.assert(
      userDataThirdPass.Username == userEmail,
      'Username doesn\'t match pass 3'
    );
    System.assert(
      userDataThirdPass.CompanyName == 'A Third Test Company',
      'Company doesn\'t match pass 3'
    );
    System.assert(
      userDataThirdPass.State__c == 'Hawaii',
      'State doesn\'t match pass 3'
    );
  }

  @IsTest
  static void testExistingCustomerAccount() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];

    String nickname = 'Testing Nickname';
    Account customerAccount = AccountTestFactory.createCustomer();
    customerAccount.Name = 'Customer Account 2';
    customerAccount.Email_Domain_Name__c = 'customeraccount2.test';
    customerAccount.Type = 'Customer';

    update customerAccount;

    Contact customerContact = ContactTestFactory.getContact(customerAccount);
    customerContact.FirstName = 'Test';
    customerContact.LastName = 'Contact';
    customerContact.Email =
      'testcontact' +
      DateTime.now().format('yyMMddHHmmssZ') +
      '@customeraccount2.test';

    //insert customerContact;

    Test.startTest();
    System.runAs(guestSiteUser) {
      Boolean existsResult = CommunitySignUpController.doesUserExist(
        customerContact.Email
      );
      Boolean existsNicknameResult = CommunitySignUpController.doesUserNicknameExist(
        nickname
      );
      System.assertEquals(false, existsResult);
      System.assertEquals(false, existsNicknameResult);

      CommunitySignUpController.RegistrationData regData = new CommunitySignUpController.RegistrationData();
      regData.email = customerContact.Email;
      regData.firstName = customerContact.FirstName;
      regData.lastName = customerContact.LastName;
      regData.username = regData.email;
      regData.agreedToTandC = Datetime.now();
      regData.mailingCountry = 'US';
      regData.mailingState = 'New York';
      regData.myCompany = 'Test Company';
      regData.myRole = 'Developer';
      regData.relationshipToBrightcove = 'Customer';
      regData.userTimeZone = 'America/New_York';
      regData.nickname = nickname;

      String registerResult = CommunitySignUpController.registerUser(regData);
      System.assertNotEquals(null, registerResult);
    }
    Test.stopTest();

    List<Contact> contacts = [
      SELECT Id, AccountId, Email, My_Role__c
      FROM Contact
      WHERE Email = :customerContact.Email
    ];
    System.assertEquals(1, contacts.size());
    System.assertEquals(customerContact.Email, contacts[0].Email);
    System.assertEquals(contacts[0].My_Role__c, 'Developer');
    System.assertEquals(customerAccount.Id, contacts[0].AccountId);
  }

  @IsTest
  static void testNewContact() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];
    Account account = AccountTestFactory.createCustomer();
    Contact customerContact = ContactTestFactory.getContact(account);
    customerContact.FirstName = 'Test';
    customerContact.LastName = 'Contact';
    customerContact.Email =
      'testcontact' +
      DateTime.now().format('yyMMddHHmmssZ') +
      '@customeraccount.test';

    Test.startTest();
    CommunitySignUpController.RegistrationData regData;
    System.runAs(guestSiteUser) {
      Boolean existsResult = CommunitySignUpController.doesUserExist(
        customerContact.Email
      );
      System.assertEquals(false, existsResult);

      regData = new CommunitySignUpController.RegistrationData();
      regData.email = customerContact.Email;
      regData.firstName = customerContact.FirstName;
      regData.lastName = customerContact.LastName;
      regData.username = regData.email;
      regData.agreedToTandC = Datetime.now();
      regData.mailingCountry = 'US';
      regData.mailingState = 'New York';
      regData.myCompany = 'Test Company';
      regData.myRole = 'Developer';
      regData.relationshipToBrightcove = 'Customer';
      regData.userTimeZone = 'America/New_York';

      String registerResult = CommunitySignUpController.registerUser(regData);
      System.assertNotEquals(null, registerResult);
    }
    Test.stopTest();

    List<Contact> contacts = [
      SELECT
        Id,
        Email,
        FirstName,
        LastName,
        MailingCountryCode,
        MailingState,
        Agreed_To_Terms_Conditions__c,
        AccountId,
        Company__c,
        My_Role__c,
        Relationship_with_Brightcove__c,
        Account.Name
      FROM Contact
      WHERE Email = :customerContact.Email
    ];
    System.assertEquals(1, contacts.size());
    System.assertEquals(regData.firstName, contacts[0].FirstName);
    System.assertEquals(regData.lastName, contacts[0].LastName);
    System.assertEquals(regData.email, contacts[0].Email);
    System.assertEquals(
      regData.agreedToTandC,
      contacts[0].Agreed_To_Terms_Conditions__c
    );
    System.assertEquals(regData.mailingCountry, contacts[0].MailingCountryCode);
    System.assertEquals(regData.mailingState, contacts[0].MailingState);
    //System.assertEquals(accountId, contacts[0].AccountId);
    System.assertEquals(regData.myCompany, contacts[0].Account.Name);
    System.assertEquals(regData.myRole, contacts[0].My_Role__c);
    System.assertEquals(
      regData.relationshipToBrightcove,
      contacts[0].Relationship_with_Brightcove__c
    );
  }

  @IsTest
  static void testGetFormData() {
    User guestSiteUser = [
      SELECT Id
      FROM User
      WHERE LastName = 'TestUserProvisioner'
      LIMIT 1
    ];
    CommunitySignUpController.FormData results;
    Test.startTest();
    System.runAs(guestSiteUser) {
      results = CommunitySignUpController.getFormData();
    }
    Test.stopTest();
    System.assertNotEquals(null, results);
    System.assertNotEquals(null, results.countryOptions);
    System.assertNotEquals(null, results.stateOptions);
    System.assertNotEquals(null, results.timeZoneOptions);
    System.assertNotEquals(null, results.roleOptions);
    System.assertNotEquals(null, results.relationshipOptions);
  }
}