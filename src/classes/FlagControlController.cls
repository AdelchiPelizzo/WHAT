/**
 * Created by adpel on 20/07/2025.
 */

public with sharing class FlagControlController {

    @AuraEnabled(cacheable=true)
    public static List<adelwhat__Flag_Control__c> getFlagControls() {
        return [
                SELECT Id, adelwhat__Ord_Id__c, adelwhat__App_Name__c, adelwhat__Flag_Color__c
                FROM adelwhat__Flag_Control__c
                LIMIT 50
        ];
    }

    @AuraEnabled
    public static void updateFlagColor(Id recordId, String newColor) {
        // Step 1: Update local Flag_Control__c
        adelwhat__Flag_Control__c record = [
                SELECT Id, adelwhat__Flag_Color__c, adelwhat__Ord_Id__c, adelwhat__App_Name__c
                FROM adelwhat__Flag_Control__c
                WHERE Id = :recordId
                LIMIT 1
        ];
        record.adelwhat__Flag_Color__c = newColor;
        update record;

        // Step 2: Send update to Render server
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://flagcheck.onrender.com/api/updateFlag');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, String> body = new Map<String, String>{
                'orgId' => record.adelwhat__Ord_Id__c,
                'appName' => record.adelwhat__App_Name__c,
                'flagColor' => newColor
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Render response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Failed to notify Render: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void syncFlagsFromRender() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://flagcheck.onrender.com/api/allFlags'); // Your GET endpoint
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<Object> flags = (List<Object>) JSON.deserializeUntyped(res.getBody());
            List<adelwhat__Flag_Control__c> upserts = new List<adelwhat__Flag_Control__c>();

            for (Object obj : flags) {
                Map<String, Object> record = (Map<String, Object>) obj;

                String orgId = (String) record.get('orgId');
                String appName = (String) record.get('appName');
                String flagColor = (String) record.get('flagColor');

                // Check if record exists
                List<adelwhat__Flag_Control__c> existing = [
                        SELECT Id FROM adelwhat__Flag_Control__c
                        WHERE adelwhat__Ord_Id__c = :orgId AND adelwhat__App_Name__c = :appName
                        LIMIT 1
                ];

                if (existing.isEmpty()) {
                    upserts.add(new adelwhat__Flag_Control__c(
                            adelwhat__Ord_Id__c = orgId,
                            adelwhat__App_Name__c = appName,
                            adelwhat__Flag_Color__c = flagColor
                    ));
                } else {
                    adelwhat__Flag_Control__c rec = existing[0];
                    rec.adelwhat__Flag_Color__c = flagColor;
                    upserts.add(rec);
                }
            }

            if (!upserts.isEmpty()) {
                upsert upserts;
            }
        } else {
            throw new AuraHandledException('Failed to sync flags from Render: ' + res.getStatus());
        }
    }

}

