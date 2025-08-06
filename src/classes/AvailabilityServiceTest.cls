/**
 * Created by adpel on 31/07/2025.
 */

@isTest
private class AvailabilityServiceTest {

    static testMethod void testAvailabilityServiceMethods() {
        // Create mock team
        adelwhat__Team__c team = new adelwhat__Team__c(Name = 'Test Team');
        insert team;

        // Create test user (needs to be done via System.runAs)
        String uniqueUsername = 'testuser-' + String.valueOf(Datetime.now().getTime()) + '@example.com';
        User testUser = new User(
                Username = uniqueUsername,
                Alias = 'tuser',
                Email = 'testuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                FirstName = 'Test',
                LastName = 'User'
        );

        insert testUser;

        // Create availability status picklist metadata object
        adelwhat__Availability_Status__c statusMeta = new adelwhat__Availability_Status__c(
                adelwhat__Status_Code__c = 'ACTIVE',
                adelwhat__Display_Label__c = 'In Office'
        );
        insert statusMeta;

        // Create a User Availability record
        adelwhat__User_Availability__c availability = new adelwhat__User_Availability__c(
                adelwhat__Status__c = 'ACTIVE',
                adelwhat__User__c = testUser.Id,
                adelwhat__Team__c = team.Id
        );
        insert availability;

        Test.startTest();

        // Test getTeamOptions
        List<adelwhat__Team__c> teams = AvailabilityService.getTeamOptions();
        System.assertEquals(1, teams.size());
        System.assertEquals(team.Name, teams[0].Name);

        // Test getAvailabilityWithUser
        List<AvailabilityService.AvailabilityWrapper> wraps = AvailabilityService.getAvailabilityWithUser();
        System.assertEquals(1, wraps.size());

        // Test getAvailabilityWithUser2 (label mapping)
        List<AvailabilityService.AvailabilityWrapper> wraps2 = AvailabilityService.getAvailabilityWithUser2();
        System.assertEquals(1, wraps2.size());
        System.assert(wraps2[0].statusLetters.size() > 0);

        // Test getAvailabilityByTeamId2 with teamId
        List<AvailabilityService.AvailabilityWrapper2> wrap2WithId = AvailabilityService.getAvailabilityByTeamId2(team.Id);
        System.assertEquals(1, wrap2WithId.size());

        // Test getAvailabilityByTeamId2 with blank teamId
        List<AvailabilityService.AvailabilityWrapper2> wrap2All = AvailabilityService.getAvailabilityByTeamId2(null);
        System.assertEquals(1, wrap2All.size());

        // Test findCurrentUserAvailability using runAs
        System.runAs(testUser) {
            adelwhat__User_Availability__c found = AvailabilityService.findCurrentUserAvailability();
            System.assertEquals(availability.Id, found.Id);
        }

        // Test getStatuses
        List<adelwhat__Availability_Status__c> statusList = AvailabilityService.getStatuses();
        System.assertEquals(1, statusList.size());
        System.assertEquals('In Office', statusList[0].adelwhat__Display_Label__c);

        // Test upsertStatus with JSON payload
        String jsonPayload = JSON.serialize(new List<Map<String, Object>>{
                new Map<String, Object>{
                        'Id' => statusMeta.Id,
                        'adelwhat__Display_Label__c' => 'Remote'
                }
        });
        AvailabilityService.upsertStatus(jsonPayload);
        adelwhat__Availability_Status__c updated = [SELECT adelwhat__Display_Label__c FROM adelwhat__Availability_Status__c WHERE Id = :statusMeta.Id];
        System.assertEquals('Remote', updated.adelwhat__Display_Label__c);

        Test.stopTest();
    }
}
