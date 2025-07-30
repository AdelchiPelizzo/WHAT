/**
 * Created by adpel on 18/07/2025.
 */

global class FlagCache {

    public static Boolean checkFlag() {
        // Query the first available Flag_Status__c record
        Flag_Status__c flagStatus = [
                SELECT Flag_Color__c, Last_Checked__c
                FROM Flag_Status__c
                LIMIT 1
        ];

        Boolean isRed;
        isRed = callExternalFlagCheck();
        System.debug('isRed: ' + isRed);
        flagStatus.Flag_Color__c = isRed ? 'Red' : 'Green';
        flagStatus.Last_Checked__c = System.now();
        update flagStatus;
        System.debug('Flag check result updated: ' + flagStatus.Flag_Color__c);

        return isRed;
    }

    // Synchronous callout allowed in schedulable context
    public static Boolean callExternalFlagCheck() {

        System.debug('calling external ::::: ');
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://flagcheck.onrender.com/flag/'+UserInfo.getOrganizationId());
            req.setMethod('GET');
//            req.setTimeout(5000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String flag = (String) result.get('flag');
                Boolean isRed = flag == 'Red';
                System.debug('🌐 Fetched flag: ' + flag);
                return isRed;
            } else {
                System.debug('⚠️ Flag check failed with status: ' + res.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            System.debug('❌ Flag check exception: ' + e.getMessage());
            return false;
        }
    }
}
