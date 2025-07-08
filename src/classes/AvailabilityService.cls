/**
 * Created by adpel on 17/06/2025.
 */

global with sharing class AvailabilityService {

    public static List<AvailabilityWrapper> availabilityList { get; set; }

    public AvailabilityService() {
        availabilityList = new List<AvailabilityWrapper>();
        loadAvailability();
    }

    @RemoteAction
    global static AvailabilityWrapper getAvailabilityById(Id availabilityId) {

        /*— query returns 0 or 1 rows instead of throwing —*/
        List<adelwhat__User_Availability__c> rows = [
                SELECT  Id,
                        adelwhat__Status__c,
                        adelwhat__User__c,
                        adelwhat__User__r.FirstName,
                        adelwhat__User__r.LastName
                FROM    adelwhat__User_Availability__c
                WHERE   Id = :availabilityId
                LIMIT   1
                /* ALL ROWS            // ←‑‑ keep if you want Recycle‑Bin visibility */
        ];

        if (rows.isEmpty()) {
            return null;                     // JS treats null ⇒ DELETE
        }

        adelwhat__User_Availability__c ava = rows[0];
        return new AvailabilityWrapper(
                ava.adelwhat__User__r.FirstName,
                ava.adelwhat__User__r.LastName,
                ava.adelwhat__User__c,           // use the lookup field itself
                ava.adelwhat__Status__c,
                ava.Id
        );
    }


    // Load availability data from the custom object
    private void loadAvailability() {
        List<adelwhat__User_Availability__c> avaList = [
                SELECT Id, adelwhat__Status__c, adelwhat__User__r.FirstName, adelwhat__User__r.LastName, adelwhat__User__r.Id
                FROM adelwhat__User_Availability__c
        ];

        for(adelwhat__User_Availability__c ava : avaList){
            availabilityList.add(new AvailabilityWrapper(
                    ava.adelwhat__User__r.FirstName,
                    ava.adelwhat__User__r.LastName,
                    ava.adelwhat__User__r.Id,
                    ava.adelwhat__Status__c,
                    ava.Id
            ));
        }
    }

    @AuraEnabled (cacheable=true)
    public static List<AvailabilityWrapper> getAvailabilityWithUser(){
        System.debug('=== entered getAvailabilityWithUser ===');
        List<AvailabilityWrapper> wrapList = new List<AvailabilityWrapper>();
        List<adelwhat__User_Availability__c> avaList = [ SELECT Id, adelwhat__Status__c, adelwhat__User__r.FirstName, adelwhat__User__r.LastName, adelwhat__User__r.Id FROM adelwhat__User_Availability__c];
        if(!avaList.isEmpty()){
            for(adelwhat__User_Availability__c ava : avaList){
                wrapList.add(new AvailabilityWrapper(ava.adelwhat__User__r.FirstName, ava.adelwhat__User__r.LastName, ava.adelwhat__User__r.Id, ava.adelwhat__Status__c, ava.Id));
            }
        }
        availabilityList = wrapList;
        return wrapList;
    }
    global class AvailabilityWrapper{
        @AuraEnabled public String userFirstName {get;set;}
        @AuraEnabled public String userLastName {get;set;}
        @AuraEnabled public String userRecordId {get;set;}
        @AuraEnabled public String Status {get;set;}
        @AuraEnabled public String availabilityId {get;set;}
        public AvailabilityWrapper(String userFirstName, String userLastName, String userRecordId, String Status, String availabilityId){
            this.userFirstName = userFirstName+' '+userLastName;
            this.userLastName = userLastName;
            this.userRecordId = userRecordId;
            this.Status = Status;
            this.availabilityId = availabilityId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static adelwhat__User_Availability__c findCurrentUserAvailability() {
        return [ SELECT
            Id,
            adelwhat__Status__c,
            adelwhat__User__r.FirstName,
            adelwhat__User__r.LastName,
            adelwhat__User__r.Id
            FROM adelwhat__User_Availability__c
            WHERE adelwhat__User__r.Id = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<adelwhat__Availability_Status__mdt> getStatuses() {
        return [
                SELECT adelwhat__Display_Label__c, adelwhat__Style__c, adelwhat__Status_Code__c
                FROM   adelwhat__Availability_Status__mdt
                ORDER  BY adelwhat__Sort_Order__c
        ];
    }

    @AuraEnabled
    public static Id upsertStatus(Map<String,Object> dto) {
        // 1) Build the record
        Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
        cm.fullName = 'adelwhat__Availability_Status__mdt.' + (String)dto.get('DeveloperName');
        cm.label    = (String)dto.get('MasterLabel');

        Metadata.CustomMetadataValue active = new Metadata.CustomMetadataValue();
        active.field = 'Active__c';
        active.value = (Boolean)dto.get('Active');
        cm.values.add(active);

        // 2) Add to a deploy container
        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        dc.addMetadata(cm);

        // 3) Queue the deployment (asynchronous)
        Id jobId = Metadata.Operations.enqueueDeployment(dc, null);
        return jobId;
    }
}
