/**
 * Created by adpel on 14/08/2025.
 */

@IsTest
private class UserAvailabilityTrigger_Test {

    @IsTest
    static void test_NoDuplicate_AllowsInsert() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        adelwhat__Team__c team = new adelwhat__Team__c(Name = 'Team A');
        insert team;

        adelwhat__User_Availability__c ua = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team.Id
        );

        Test.startTest();
        insert ua;
        Test.stopTest();

        System.assertNotEquals(null, ua.Id);
    }

    @IsTest
    static void test_Duplicate_BlocksInsert() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        adelwhat__Team__c team = new adelwhat__Team__c(Name = 'Team B');
        insert team;

        adelwhat__User_Availability__c ua1 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team.Id
        );
        insert ua1;

        adelwhat__User_Availability__c ua2 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team.Id
        );

        Test.startTest();
        try {
            insert ua2;
            System.assert(false, 'Expected DMLException for duplicate');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate exists'), 'Should show duplicate error message');
            System.assert(e.getMessage().contains('/' + ua1.Id), 'Should include link to existing record');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_SameUser_DifferentTeam_AllowsInsert() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        adelwhat__Team__c team1 = new adelwhat__Team__c(Name = 'Team C');
        adelwhat__Team__c team2 = new adelwhat__Team__c(Name = 'Team D');
        insert new List<adelwhat__Team__c>{ team1, team2 };

        adelwhat__User_Availability__c ua1 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team1.Id
        );
        insert ua1;

        adelwhat__User_Availability__c ua2 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team2.Id
        );

        Test.startTest();
        insert ua2;
        Test.stopTest();

        System.assertNotEquals(null, ua2.Id);
    }

    @IsTest
    static void test_UpdateSameRecord_SkipsDuplicateCheck() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        adelwhat__Team__c team = new adelwhat__Team__c(Name = 'Team E');
        insert team;

        adelwhat__User_Availability__c ua = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = team.Id
        );
        insert ua;

        // Update the same record — should NOT throw duplicate error
        ua.adelwhat__Team__c = team.Id; // keep same team
        Test.startTest();
        update ua;
        Test.stopTest();

        System.assertEquals(team.Id, ua.adelwhat__Team__c);
    }

    @IsTest
    static void test_UpdateTriggersDuplicateCheck() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        adelwhat__Team__c teamA = new adelwhat__Team__c(Name = 'Team A');
        adelwhat__Team__c teamB = new adelwhat__Team__c(Name = 'Team B');
        insert new List<adelwhat__Team__c>{ teamA, teamB };

        // Record 1 - User in Team A
        adelwhat__User_Availability__c ua1 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = teamA.Id
        );
        // Record 2 - User in Team B
        adelwhat__User_Availability__c ua2 = new adelwhat__User_Availability__c(
                adelwhat__User__c = u.Id,
                adelwhat__Team__c = teamB.Id
        );
        insert new List<adelwhat__User_Availability__c>{ ua1, ua2 };

        // Now update record 2 to match record 1's team
        ua2.adelwhat__Team__c = teamA.Id;

        Test.startTest();
        try {
            update ua2;
            System.assert(false, 'Expected duplicate error on update');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Team A'), 'Should include correct team name in message');
            System.assert(e.getMessage().contains('/' + ua1.Id), 'Should include link to existing record');
        }
        Test.stopTest();
    }

}

