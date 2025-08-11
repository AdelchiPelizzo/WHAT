/**
 * Created by adpel on 04/08/2025.
 */

public without sharing class FlagCheckService {
    @AuraEnabled(cacheable=true)
    public static Flag_Status__c checkFlagColor() {
        try {
            if (!Schema.SObjectType.Flag_Status__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to read Flag Status.');
            }

            Flag_Status__c status = [
                    SELECT Id, Flag_Color__c, Notice__c
                    FROM Flag_Status__c WITH USER_MODE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            return status;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking flag: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getNamespacePrefix() {
        String fullName = FlagCheckService.class.getName(); // e.g. "adelwhat.FlagCheckService" or "FlagCheckService"
        if (fullName.contains('.')) {
            return fullName.split('\\.')[0] + '__';
        }
        return '';
    }




}