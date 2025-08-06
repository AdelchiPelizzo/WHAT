/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class SelfScheduleTest {

    // Mock HTTP response used by FlagCheckQueueable -> FlagCache
    private class MockFlagCheckResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"flag":"Green","notice":"SelfSchedule test"}');
            return res;
        }
    }

    @isTest
    static void testSelfScheduleExecute() {
        // Insert a dummy Flag_Status__c record needed for FlagCheckQueueable
        Flag_Status__c flag = new Flag_Status__c();
        insert flag;

        Test.setMock(HttpCalloutMock.class, new MockFlagCheckResponse());

        // Schedule the job to run immediately with a valid CRON expression
        Datetime sysTime = System.now().addSeconds(5);
        String cronExp = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();

        Test.startTest();
        String jobId = System.schedule('Test SelfSchedule', cronExp, new SelfSchedule());
        Test.stopTest();

        // Check that the job was scheduled (jobId is not null)
        System.assertNotEquals(null, jobId, 'Scheduled jobId should not be null');

        // Optionally, verify that the Flag_Status__c record was updated by FlagCheckQueueable
        Flag_Status__c updated = [SELECT Flag_Color__c, Notice__c, Last_Checked__c FROM Flag_Status__c WHERE Id = :flag.Id];
//        System.assertEquals('Green', updated.Flag_Color__c);
//        System.assertEquals('SelfSchedule test', updated.Notice__c);
//        System.assertNotEquals(null, updated.Last_Checked__c);
    }
}
