/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class ProtectFlagStatusTest {

    @isTest
    static void testUpdateBlockedByDefault() {
        // Arrange: Insert a test record
        Flag_Status__c flag = new Flag_Status__c(
                Last_Checked__c = System.now()
        );
        insert flag;
        try {
            update flag;
            System.assert(false, 'Expected error was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('This record is protected'), 'Expected protection error');
        }
    }

    @isTest
    static void testDeleteBlockedByDefault() {
        // Arrange
        Flag_Status__c flag = new Flag_Status__c(
                Last_Checked__c = System.now()
        );
        insert flag;

        // Act + Assert: Try deleting it (should fail by default)
        try {
            delete flag;
            System.assert(false, 'Expected error was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('This record is protected'), 'Expected protection error');
        }
    }

    @isTest
    static void testUpdateAllowedWithBypass() {
        // Arrange
        Flag_Status__c flag = new Flag_Status__c(
                Last_Checked__c = System.now()
        );
        insert flag;

        // Act: Set bypass and try update
        FlagProtectionBypass.bypass = true;
        Test.startTest();
        update flag;
        Test.stopTest();

    }

    @isTest
    static void testDeleteAllowedWithBypass() {
        // Arrange
        Flag_Status__c flag = new Flag_Status__c(
                Last_Checked__c = System.now()
        );
        insert flag;

        // Act: Set bypass and delete
        FlagProtectionBypass.bypass = true;

        Test.startTest();
        delete flag;
        Test.stopTest();

        // Assert: Ensure it's deleted
        System.assertEquals(0, [SELECT COUNT() FROM Flag_Status__c WHERE Id = :flag.Id]);
    }
}
