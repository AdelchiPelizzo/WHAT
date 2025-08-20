/**
 * Created by adpel on 17/06/2025.
 */

global with sharing class AvailabilityService {

    public static List<AvailabilityWrapper> availabilityList { get; set; }
//    public String teamId { get; set; }
//    public String teamName { get; set; }
//
//    public AvailabilityService() {
//        availabilityList = new List<AvailabilityWrapper>();
//        teamId = ApexPages.currentPage().getParameters().get('teamId');
//        loadAvailability(teamId);
//        teamName = [SELECT Name FROM adelwhat__Team__c WHERE Id =: teamId LIMIT 1].Name;
//    }

    @AuraEnabled(cacheable=true)
    public static List<adelwhat__Team__c> getTeamOptions() {
        // Check object read access before querying
        if (!Schema.SObjectType.adelwhat__Team__c.isAccessible()) {
            return new List<adelwhat__Team__c>();
        }

        List<adelwhat__Team__c> lsTeam =  [
                SELECT Id, Name
                FROM adelwhat__Team__c WITH USER_MODE
        ];
        // Enforce CRUD/FLS automatically using WITH USER_MODE
        lsTeam.sort();
        return lsTeam;
    }


    @AuraEnabled(cacheable=true)
    public static String getNamespacePrefix() {
        String fullName = AvailabilityService.class.getName(); // e.g. "adelwhat.FlagCheckService" or "FlagCheckService"
        if (fullName.contains('.')) {
            return fullName.split('\\.')[0] + '__';
        }
        return '';
    }

//    @AuraEnabled
//    public static String def(){
//        return [SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'adelwhat__User_Availability__c' LIMIT 1].DurableId;
//    }

    // Load availability data from the custom object
//    private static void loadAvailability(String teamId) {
//        System.debug('Loading Filtered Data');
//        List<adelwhat__User_Availability__c> avaList = [
//                SELECT Id, adelwhat__Status__c, adelwhat__User__r.FirstName, adelwhat__User__r.LastName, adelwhat__User__r.SmallPhotoUrl, adelwhat__User__r.Id, adelwhat__Team__r.Name
//                FROM adelwhat__User_Availability__c
//                WHERE adelwhat__Team__c =: teamId
//        ];
//
//        for(adelwhat__User_Availability__c ava : avaList){
//            availabilityList.add(new AvailabilityWrapper(
//                    ava.adelwhat__User__r.FirstName,
//                    ava.adelwhat__User__r.LastName,
//                    ava.adelwhat__User__r.SmallPhotoUrl,
//                    ava.adelwhat__User__r.Id,
//                    ava.adelwhat__Status__c,
//                    ava.Id,
//                    ava.adelWhat__Team__r.Name
//            ));
//        }
//    }
//31.07
//    @AuraEnabled(cacheable=true)
//    public static List<AvailabilityWrapper> getAvailabilityByTeamId(String teamId){
//        System.debug('=== getAvailabilityByTeamId ===');
//        System.debug('=== TeamId ===  '+teamId);
//        List<AvailabilityWrapper> wrapList = new List<AvailabilityWrapper>();
//
//        List<adelwhat__User_Availability__c> avaList;
//        if(String.isBlank(teamId)) {
//            // No filter: get all
//            avaList = [
//                    SELECT Id,
//                            adelwhat__Status__c,
//                            adelwhat__User__r.FirstName,
//                            adelwhat__User__r.LastName,
//                            adelwhat__User__r.SmallPhotoUrl,
//                            adelwhat__User__r.Id,
//                            adelwhat__Team__r.Name
//                    FROM adelwhat__User_Availability__c
//            ];
//        } else {
//            // Filter by team
//            avaList = [
//                    SELECT Id,
//                            adelwhat__Status__c,
//                            adelwhat__User__r.FirstName,
//                            adelwhat__User__r.LastName,
//                            adelwhat__User__r.SmallPhotoUrl,
//                            adelwhat__User__r.Id,
//                            adelwhat__Team__r.Name
//                    FROM adelwhat__User_Availability__c
//                    WHERE adelwhat__Team__c = :teamId
//            ];
//        }
//
//        for(adelwhat__User_Availability__c ava : avaList){
//            wrapList.add(new AvailabilityWrapper(
//                    ava.adelwhat__User__r.FirstName,
//                    ava.adelwhat__User__r.LastName,
//                    ava.adelwhat__User__r.SmallPhotoUrl,
//                    ava.adelwhat__User__r.Id,
//                    ava.adelwhat__Status__c,
//                    ava.Id,
//                    ava.adelwhat__Team__r.Name
//            ));
//        }
//
//        availabilityList = wrapList;
//        System.debug(availabilityList.size());
//        System.debug(availabilityList);
//        return wrapList;
//    }

    @AuraEnabled (cacheable=true)
    public static List<AvailabilityWrapper> getAvailabilityWithUser2() {
        System.debug('=== entered getAvailabilityWithUser ===');

        // Map picklist values to labels
        Map<String, String> statusLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult dfr = adelwhat__User_Availability__c.adelwhat__Status__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            statusLabelMap.put(entry.getValue(), entry.getLabel());
        }

        List<AvailabilityWrapper> wrapList = new List<AvailabilityWrapper>();

        List<adelwhat__User_Availability__c> avaList = [
                SELECT Id,
                        adelwhat__Status__c,
                        adelwhat__User__r.FirstName,
                        adelwhat__User__r.LastName,
                        adelwhat__User__r.SmallPhotoUrl,
                        adelwhat__User__r.Id,
                        adelwhat__Team__r.Name
                FROM adelwhat__User_Availability__c WITH USER_MODE
        ];

        if (!avaList.isEmpty()) {
            for (adelwhat__User_Availability__c ava : avaList) {
                String statusLabel = statusLabelMap.get(ava.adelwhat__Status__c);
                wrapList.add(new AvailabilityWrapper(
                        ava.adelwhat__User__r.FirstName,
                        ava.adelwhat__User__r.LastName,
                        ava.adelwhat__User__r.SmallPhotoUrl,
                        ava.adelwhat__User__r.Id,
                        statusLabel, // use label instead of value
                        ava.Id,
                        ava.adelwhat__Team__r.Name
                ));
            }
        }

        availabilityList = wrapList;
        return wrapList;
    }


    @AuraEnabled (cacheable=true)
    public static List<AvailabilityWrapper> getAvailabilityWithUser(){
        System.debug('=== entered getAvailabilityWithUser ===');
        List<AvailabilityWrapper> wrapList = new List<AvailabilityWrapper>();
        List<adelwhat__User_Availability__c> avaList = [
                SELECT Id,
                adelwhat__Status__c,
                adelwhat__User__r.FirstName,
                adelwhat__User__r.LastName,
                adelwhat__User__r.SmallPhotoUrl,
                adelwhat__User__r.Id,
                adelwhat__Team__r.
                FROM adelwhat__User_Availability__c WITH USER_MODE ];
        if(!avaList.isEmpty()){
            for(adelwhat__User_Availability__c ava : avaList){
                wrapList.add(new AvailabilityWrapper(ava.adelwhat__User__r.FirstName, ava.adelwhat__User__r.LastName, ava.adelwhat__User__r.SmallPhotoUrl, ava.adelwhat__User__r.Id, ava.adelwhat__Status__c, ava.Id, ava.adelwhat__Team__r.Name ));
            }
        }
        availabilityList = wrapList;
        return wrapList;
    }

    global class AvailabilityWrapper {
        @AuraEnabled public String userFirstName { get; set; }
        @AuraEnabled public String userLastName { get; set; }
        @AuraEnabled public String photo { get; set; }
        @AuraEnabled public String userRecordId { get; set; }
        @AuraEnabled public String Status { get; set; }
        @AuraEnabled public String availabilityId { get; set; }
        @AuraEnabled public String teamName { get; set; }

        @AuraEnabled public List<String> statusLetters { get; set; } // NEW: List of single characters

        public AvailabilityWrapper(String userFirstName, String userLastName, String photoURL, String userRecordId, String Status, String availabilityId, String teamName) {
            this.userFirstName = userFirstName;
            this.userLastName = userLastName;
            this.photo = photoURL;
            this.userRecordId = userRecordId;
            this.Status = Status;
            this.availabilityId = availabilityId;
            this.statusLetters = splitStatus(Status);
            this.teamName = teamName;
        }

        private List<String> splitStatus(String input) {
            List<String> letters = new List<String>();
            if (String.isNotBlank(input)) {
                for (Integer i = 0; i < input.length(); i++) {
                    letters.add(String.valueOf(input.substring(i, i + 1)));
                }
            }
            return letters;
        }
    }

    global class AvailabilityWrapper2 {
        @AuraEnabled public String userFirstName { get; set; }
        @AuraEnabled public String userLastName { get; set; }
        @AuraEnabled public String photo { get; set; }
        @AuraEnabled public String userRecordId { get; set; }
        @AuraEnabled public String Status { get; set; }
        @AuraEnabled public String StatusLabel { get; set; }
        @AuraEnabled public String availabilityId { get; set; }
        @AuraEnabled public String teamName { get; set; }
        @AuraEnabled public String aboutMe { get; set; }

        @AuraEnabled public List<String> statusLetters { get; set; } // NEW: List of single characters

        public AvailabilityWrapper2(String userFirstName, String userLastName, String photoURL, String userRecordId, String Status, String StatusLabel, String availabilityId, String teamName, String aboutMe) {
            this.userFirstName = userFirstName;
            this.userLastName = userLastName;
            this.photo = photoURL;
            this.userRecordId = userRecordId;
            this.Status = Status;
            this.StatusLabel = StatusLabel;
            this.availabilityId = availabilityId;
            this.statusLetters = splitStatus(Status);
            this.teamName = teamName;
            this.aboutMe = aboutMe;
        }

        private List<String> splitStatus(String input) {
            List<String> letters = new List<String>();
            if (String.isNotBlank(input)) {
                for (Integer i = 0; i < input.length(); i++) {
                    letters.add(String.valueOf(input.substring(i, i + 1)));
                }
            }
            return letters;
        }
    }

    private static String getStatusLabel( String statLab){

        Map<String, String> statusLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult dfr = adelwhat__User_Availability__c.adelwhat__Status__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            statusLabelMap.put(entry.getValue(), entry.getLabel());
        }

        return statusLabelMap.get(statLab);
    }

    @AuraEnabled(cacheable=true)
    public static List<AvailabilityWrapper2> getAvailabilityByTeamId2(String teamId){
        System.debug('=== getAvailabilityByTeamId ===');
        System.debug('=== TeamId ===  '+teamId);

        List<AvailabilityWrapper2> wrapList = new List<AvailabilityWrapper2>();

        // Step 1: Build picklist value-to-label map
        Map<String, String> statusLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult dfr = adelwhat__User_Availability__c.adelwhat__Status__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            statusLabelMap.put(entry.getValue(), entry.getLabel());
        }

        // Step 2: Query records
        List<adelwhat__User_Availability__c> avaList;
        if (String.isBlank(teamId)) {
            // No filter: get all
            avaList = [
                    SELECT Id,
                            adelwhat__Status__c,
                            adelwhat__User__r.FirstName,
                            adelwhat__User__r.LastName,
                            adelwhat__User__r.SmallPhotoUrl,
                            adelwhat__User__r.Id,
                            adelwhat__User__r.AboutMe,
                            adelwhat__Team__r.Name
                    FROM adelwhat__User_Availability__c WITH USER_MODE
            ];
        } else {
            // Filter by team
            avaList = [
                    SELECT Id,
                            adelwhat__Status__c,
                            adelwhat__User__r.FirstName,
                            adelwhat__User__r.LastName,
                            adelwhat__User__r.SmallPhotoUrl,
                            adelwhat__User__r.Id,
                            adelwhat__User__r.AboutMe,
                            adelwhat__Team__r.Name
                    FROM adelwhat__User_Availability__c
                    WHERE adelwhat__Team__c = :teamId WITH USER_MODE
            ];
        }

        // Step 3: Build wrapper list with label
        for (adelwhat__User_Availability__c ava : avaList) {
            String statusValue = ava.adelwhat__Status__c;
            String statusLabel = getStatusLabel(statusValue);
//            String statusLabel = statusLabelMap.get(statusValue); // map API value to label

            wrapList.add(new AvailabilityWrapper2(
                    ava.adelwhat__User__r.FirstName,
                    ava.adelwhat__User__r.LastName,
                    ava.adelwhat__User__r.SmallPhotoUrl,
                    String.valueOf(ava.adelwhat__User__r.Id), // <-- Pass label here
                    statusValue,
                    statusLabel,
                    String.valueOf(ava.Id),
                    ava.adelwhat__Team__r.Name,
                    ava.adelwhat__User__r.AboutMe
            ));
        }

        System.debug(wrapList.size());
        System.debug(wrapList);
        return wrapList;
    }


    @AuraEnabled(cacheable=true)
    public static adelwhat__User_Availability__c findCurrentUserAvailability() {
        return [ SELECT
            Id,
            adelwhat__Status__c,
            adelwhat__User__r.FirstName,
            adelwhat__User__r.LastName,
            adelwhat__User__r.Id
            FROM adelwhat__User_Availability__c W
            WHERE adelwhat__User__r.Id = :UserInfo.getUserId() WITH USER_MODE
            ORDER BY CreatedDate DESC LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<adelwhat__Availability_Status__c> getStatuses() {
        List<adelwhat__Availability_Status__c> lst = [ SELECT adelwhat__Display_Label__c, adelwhat__Status_Code__c FROM  adelwhat__Availability_Status__c WITH USER_MODE ];
        return lst;
    }

    @AuraEnabled
    public static void upsertStatus(String payload) {
        System.debug('payload >>> ' + payload);
        if (String.isBlank(payload)) {
            throw new AuraHandledException('No data received.');
        }

        if (!Schema.sObjectType.adelwhat__Availability_Status__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update Availability Status records.');
        }
        if (!Schema.sObjectType.adelwhat__Availability_Status__c.fields.adelwhat__Display_Label__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update the Display Label field.');
        }

        List<Object> rawList = (List<Object>) JSON.deserializeUntyped(payload);
        System.debug(rawList);
        List<adelwhat__Availability_Status__c> toUpdate = new List<adelwhat__Availability_Status__c>();

        for (Object item : rawList) {
            Map<String, Object> row = (Map<String, Object>) item;

            if (row == null || !row.containsKey('Id')) continue;

            String id    = (String) row.get('Id');
            String label = (String) row.get('adelwhat__Display_Label__c');

            if (String.isNotBlank(id)) {
                toUpdate.add(new adelwhat__Availability_Status__c(
                        Id = id,
                        adelwhat__Display_Label__c = label
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }


}