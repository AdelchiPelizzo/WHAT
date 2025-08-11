/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class FlagCheckQueueableTest {

    // Mock callout response
    private class MockFlagCheckResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"flag":"Yellow","notice":"Maintenance scheduled"}');
            return res;
        }
    }

    @isTest
    static void testQueueableFlagCheck() {
        // Insert a blank Flag_Status__c record (no required fields)
        Flag_Status__c flag = new Flag_Status__c();
        insert flag;

        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new MockFlagCheckResponse());

        Test.startTest();
        System.enqueueJob(new FlagCheckQueueable());
        Test.stopTest(); // Runs the queueable

        // Assert that the record was updated correctly
        Flag_Status__c updated = [SELECT Flag_Color__c, Notice__c, Last_Checked__c FROM Flag_Status__c WHERE Id = :flag.Id];
        System.assertEquals('Yellow', updated.Flag_Color__c, 'Flag color should be updated to Yellow');
        System.assertEquals('Maintenance scheduled', updated.Notice__c, 'Notice should be updated');
        System.assertNotEquals(null, updated.Last_Checked__c, 'Last_Checked__c should be populated');
    }
}