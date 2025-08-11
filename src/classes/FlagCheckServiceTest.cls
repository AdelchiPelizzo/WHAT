/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class FlagCheckServiceTest {

    @isTest
    static void testCheckFlagColorReturnsLatest() {
        // Arrange: Insert two flag records
        Flag_Status__c olderFlag = new Flag_Status__c(Flag_Color__c = 'Red', Notice__c = 'Old notice');
        insert olderFlag;

        // Simulate time difference
        Test.setCreatedDate(olderFlag.Id, DateTime.now().addMinutes(-5));

        Flag_Status__c newerFlag = new Flag_Status__c(Flag_Color__c = 'Green', Notice__c = 'Newer notice');
        insert newerFlag;

        // Act
        Test.startTest();
        Flag_Status__c result = FlagCheckService.checkFlagColor();
        Test.stopTest();

        // Assert: Should return the newer one
        System.assertEquals(newerFlag.Id, result.Id, 'Should return the most recently created flag');
        System.assertEquals('Green', result.Flag_Color__c);
        System.assertEquals('Newer notice', result.Notice__c);
    }

    @isTest
    static void testCheckFlagColorThrowsExceptionIfNoRecords() {
        // Ensure no Flag_Status__c records exist
        Test.startTest();
        try {
            FlagCheckService.checkFlagColor();
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
//            System.assert(e.getMessage().startsWith('Error checking flag'), 'Expected wrapped AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetNamespacePrefix() {
        // Act
        String ns = FlagCheckService.getNamespacePrefix();

        // Assert — in dev/unmanaged org this should be empty, in managed it should end with '__'
        if (Test.isRunningTest()) {
            if (ns != null && ns != '') {
                System.assert(ns.endsWith('__'), 'Namespace should end with "__" when present');
            } else {
                System.assertEquals('', ns, 'Expected empty namespace in unmanaged context');
            }
        }
    }
}