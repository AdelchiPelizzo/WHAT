/**
 * Created by adpel on 31/07/2025.
 */

@isTest
private class AvailabilityVFControllerTest {

    @isTest
    static void testAvailabilityVFControllerWithTeamId() {
        // Create a test Team
        adelwhat__Team__c team = new adelwhat__Team__c(Name = 'Test Team');
        insert team;

        // Create a test user
        String uniqueUsername = 'testuser-' + DateTime.now().getTime() + '@test.com';
        User user = new User(
                Username = uniqueUsername,
                Alias = 'tuser',
                Email = 'test@example.com',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                FirstName = 'Test',
                LastName = 'User'
        );
        insert user;

        // Get a valid status picklist value
        Schema.DescribeFieldResult statusField = adelwhat__User_Availability__c.adelwhat__Status__c.getDescribe();
        String validStatus = statusField.getPicklistValues()[0].getValue();

        // Create User Availability
        adelwhat__User_Availability__c availability = new adelwhat__User_Availability__c(
                adelwhat__User__c = user.Id,
                adelwhat__Team__c = team.Id,
                adelwhat__Status__c = validStatus
        );
        insert availability;

        Test.startTest();

        // Set the teamId param in the current page
        ApexPages.currentPage().getParameters().put('teamId', team.Id);

        // Instantiate the controller
        AvailabilityVFController ctrl = new AvailabilityVFController();

        // Assertions
        System.assertEquals(team.Id, ctrl.teamId);
        System.assertEquals('Test Team', ctrl.teamName);
        System.assertNotEquals(null, ctrl.availabilities);
        System.assertEquals(1, ctrl.availabilities.size());

        AvailabilityVFController.AvailabilityWrapper2 wrap = ctrl.availabilities[0];
        System.assertEquals('Test', wrap.userFirstName);
        System.assertEquals(validStatus, wrap.Status);
        System.assert(wrap.statusLetters != null && wrap.statusLetters.size() > 0);

        Test.stopTest();
    }

    @isTest
    static void testAvailabilityVFControllerWithoutTeamId() {
        Test.startTest();

        // No teamId parameter set
        AvailabilityVFController ctrl = new AvailabilityVFController();

        // Should not throw errors, but data will be empty
        System.assertEquals(null, ctrl.teamId);
        System.assert(ctrl.teamName == null || ctrl.teamName == 'Unknown');
        System.assertNotEquals(null, ctrl.availabilities);
        Test.stopTest();
    }
}
