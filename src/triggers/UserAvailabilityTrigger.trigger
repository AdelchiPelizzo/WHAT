/**
 * Created by adpel on 14/08/2025.
 */

trigger UserAvailabilityTrigger on adelwhat__User_Availability__c (before insert, before update) {
    Set<Id> userIds = new Set<Id>();
    for (adelwhat__User_Availability__c rec : Trigger.new) {
        if (rec.adelwhat__User__c != null && rec.adelwhat__Team__c != null) {
            userIds.add(rec.adelwhat__User__c);
        }
    }

    if (userIds.isEmpty()) {
        return;
    }

    // Query existing records for same user/team
    Map<String, adelwhat__User_Availability__c> existingMap = new Map<String, adelwhat__User_Availability__c>();
    if (!Schema.sObjectType.adelwhat__User_Availability__c.isAccessible() ||
            !Schema.sObjectType.adelwhat__User_Availability__c.fields.adelwhat__User__c.isAccessible() ||
            !Schema.sObjectType.adelwhat__User_Availability__c.fields.adelwhat__Team__c.isAccessible()) {
        return;
    }

    for (adelwhat__User_Availability__c ex : [
            SELECT Id, Name, adelwhat__User__c, adelwhat__Team__c, adelwhat__Team__r.Name
            FROM adelwhat__User_Availability__c
            WHERE adelwhat__User__c IN :userIds WITH USER_MODE
    ]) {
        String key = ex.adelwhat__User__c + '|' + ex.adelwhat__Team__c;
        existingMap.put(key, ex);
    }

    for (adelwhat__User_Availability__c rec : Trigger.new) {
        if (rec.adelwhat__User__c != null && rec.adelwhat__Team__c != null) {
            String key = rec.adelwhat__User__c + '|' + rec.adelwhat__Team__c;

            if (existingMap.containsKey(key)) {
                adelwhat__User_Availability__c existingRec = existingMap.get(key);

                // Skip if editing the same record
                if (Trigger.isUpdate && existingRec.Id == rec.Id) {
                    continue;
                }

                rec.adelwhat__User__c.addError(
                        'Duplicate exists for this user in team "' + existingRec.adelwhat__Team__r.Name + '". ' +
                                'View existing: /' + existingRec.Id
                );
            }
        }
    }
}



