@IsTest(isparallel=true)
public class updatedSupportCtrlTest {
  @IsTest
  static void testGetCaseDetails() {
    Account account = AccountTestFactory.createCustomer();
    Case newCase = new Case(
      Subject = 'test',
      Origin = 'Email',
      AccountId = account.Id
    );
    insert newCase;
    Contact contact = ContactTestFactory.createContact(account);
    newCase.ContactId = contact.Id;
    update newCase;

    updatedSupportCtrl.getSearchCases('test');
  }
}