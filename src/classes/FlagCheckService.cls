/**
 * Created by adpel on 04/08/2025.
 */

public class FlagCheckService {
    @AuraEnabled(cacheable=true)
    public static Flag_Status__c checkFlagColor() {
        try {
            Flag_Status__c status = [
                    SELECT Id, Flag_Color__c, Notice__c
                    FROM Flag_Status__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

//            String color = status.Flag_Color__c;
//            String notice = 'status.Notice__c';
//            String notice = status.Notice__c;
//            System.debug('⚑ Flag color for Team Manager is: ' + color);
//            System.debug('⚑ Notice is: ' + notice);

            return status;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking flag: ' + e.getMessage());
        }
    }
}

