@isTest
public with sharing class MyProfilePageControllerTest {
  @isTest
  static void testSave() {
    User currentUser = [
      SELECT
        Id,
        Title,
        FirstName,
        LastName,
        Email,
        Phone,
        MobilePhone,
        Fax,
        Street,
        City,
        State,
        Postalcode,
        Country
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    MyProfilePageController controller = new MyProfilePageController();
    System.assertEquals(
      currentUser.Id,
      controller.getUser().Id,
      'Did not successfully load the current user'
    );
    System.assertEquals(
      false,
      controller.getIsEdit(),
      'isEdit should default to false'
    );
    controller.edit();
    System.assertEquals(true, controller.getIsEdit());
    controller.cancel();
    System.assertEquals(false, controller.getIsEdit());

    System.assert(
      Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl())
    );
    Test.startTest();

    controller.edit();
    String randFax = Math.rint(Math.random() * 1000) + '5551234';
    controller.getUser().Fax = randFax;
    controller.save();
    Test.stopTest();

    currentUser = [SELECT Id, Fax FROM User WHERE Id = :currentUser.Id];
    System.assertEquals(randFax, currentUser.Fax);
  }
}