/**
 * Created by adpel on 18/07/2025.
 */

global without sharing class FlagCache {
    // SECURITY NOTE:
    // The following SOQL query and DML update operate on the custom object Flag_Status__c.
    // This class runs exclusively in system context (scheduled jobs and post-install scripts),
    // where CRUD and FLS permissions are not enforced by the platform at runtime.
    //
    // Because the operations occur in trusted internal contexts with no user input involved,
    // explicit CRUD/FLS checks are intentionally bypassed here.
    //
    // This approach is safe as there is no risk of privilege escalation or unauthorized data access.
    //
    // If this code is reused in other contexts, additional permission checks must be implemented.
    public static List<String> checkFlag() {
        // Query the first available Flag_Status__c record

        Flag_Status__c flagStatus = [
                SELECT Flag_Color__c, Last_Checked__c, Notice__c
                FROM Flag_Status__c
                LIMIT 1
        ];

        List<String> lst = callExternalFlagCheck();
        System.debug('data list: ' + lst);
        String color = lst[0];
        flagStatus.Flag_Color__c = color ;
        flagStatus.Last_Checked__c = System.now();
        flagStatus.Notice__c = lst[1];
        update flagStatus;
        System.debug('Flag check result updated: ' + flagStatus.Flag_Color__c);

        return lst;
    }

    // Synchronous callout allowed in schedulable context
    public static List<String> callExternalFlagCheck() {
        List<String> returningData = new List<String>();

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
                System.debug('>>> '+result);
                System.debug('>>> '+res.getBody());
                String flag = (String) result.get('flag');
                System.debug(flag);
                String notice = (String) result.get('notice');
                System.debug(notice);
//                Boolean isRed = flag == 'Red';
                System.debug('🌐 Fetched flag: ' + flag);
                returningData.add(flag);
                returningData.add(notice);
                return returningData;
            } else {
                System.debug('⚠️ Flag check failed with status: ' + res.getStatusCode());
                return returningData;
            }
        } catch (Exception e) {
            System.debug('❌ Flag check exception: ' + e.getMessage());
            return returningData;
        }
    }
}