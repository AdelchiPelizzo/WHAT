/**
 * Created by adpel on 20/07/2025.
 */

@IsTest
private class FlagPostInstallTest {

    @IsTest
    static void testCatchBlockCoverage() {
        FlagPostInstall.forceErrorForTest = true;  // Enable error simulation
        FlagPostInstall handler = new FlagPostInstall();

        handler.onInstall(null);  // This triggers the catch block

        FlagPostInstall.forceErrorForTest = false; // Reset toggle
    }

    @IsTest
    static void testNormalInstall() {
        FlagPostInstall handler = new FlagPostInstall();
        handler.onInstall(null);

        System.assertEquals(1, [SELECT COUNT() FROM Flag_Status__c]);
    }
}
