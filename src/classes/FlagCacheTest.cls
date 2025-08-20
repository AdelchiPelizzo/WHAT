/**
 * Created by adpel on 06/08/2025.
 */

@isTest
private class FlagCacheTest {

    // Mock HTTP response for the external flag check
    private class MockFlagCheckResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"flag":"Green","notice":"All systems operational"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testCheckFlag_WithBypass_AllowsUpdate() {
        // Arrange: Insert a blank Flag_Status__c record
        Flag_Status__c flag = new Flag_Status__c();
        insert flag;

        // Bypass protection to allow update by FlagCache
        FlagProtectionBypass.bypass = true;

        // Inject mock callout response
        Test.setMock(HttpCalloutMock.class, new MockFlagCheckResponse());

        Test.startTest();
        List<String> result = FlagCache.checkFlag();
        Test.stopTest();

        // Assert: Method returned expected values
        System.assertEquals(3, result.size(), 'Expected 2 elements in result');
        System.assertEquals('Green', result[0], 'Expected flag color');
        System.assertEquals('All systems operational', result[1], 'Expected notice');

        // Assert: Flag_Status__c record was updated
        Flag_Status__c updated = [SELECT Flag_Color__c, Notice__c, Last_Checked__c FROM Flag_Status__c WHERE Id = :flag.Id];
        System.assertEquals('Green', updated.Flag_Color__c);
        System.assertEquals('All systems operational', updated.Notice__c);
        System.assertNotEquals(null, updated.Last_Checked__c);
    }
}