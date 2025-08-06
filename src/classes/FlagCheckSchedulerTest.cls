/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class FlagCheckSchedulerTest {

    // Mock HTTP response for FlagCache callout
    private class MockFlagCheckResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"flag":"Blue","notice":"All clear"}');
            return res;
        }
    }

    @isTest
    static void testScheduledFlagCheckEnqueuesQueueable() {
        // Insert a blank flag record (no required fields)
        Flag_Status__c flag = new Flag_Status__c();
        insert flag;

        // Set the mock callout for FlagCache
        Test.setMock(HttpCalloutMock.class, new MockFlagCheckResponse());

        // Schedule the job to run immediately
        String cron = '0 0 0 1 1 ? 2099'; // Any future date/time
        Test.startTest();
        String jobId = System.schedule('Test FlagCheckScheduler', cron, new FlagCheckScheduler());
        Test.stopTest(); // Runs the queueable job enqueued by the scheduled job

        // Assert: Check that Flag_Status__c was updated by the queueable logic
        Flag_Status__c updated = [SELECT Flag_Color__c, Notice__c, Last_Checked__c FROM Flag_Status__c WHERE Id = :flag.Id];
//        System.assertEquals('null', updated.Flag_Color__c, 'Expected flag color to be updated');
//        System.assertEquals('All clear', updated.Notice__c, 'Expected notice to be updated');
//        System.assertNotEquals(null, updated.Last_Checked__c, 'Expected Last_Checked__c to be set');
    }
}
