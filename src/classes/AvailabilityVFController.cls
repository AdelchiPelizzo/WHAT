/**
 * Created by adpel on 27/07/2025.
 */

public with sharing class AvailabilityVFController {
    public String teamId { get; set; }
    public String teamName { get; private set; }
    public List<AvailabilityWrapper2> availabilities { get; set; }

    // Constructor
    public AvailabilityVFController() {
        // Get teamId param safely
        String rawTeamId = ApexPages.currentPage().getParameters().get('teamId');
        if (rawTeamId != null) {
            rawTeamId = String.escapeSingleQuotes(rawTeamId).escapeXml();
        }
        // Validate format: only Salesforce Id characters, length 15 or 18
        if (String.isNotBlank(rawTeamId) && Pattern.matches('^[a-zA-Z0-9]{15,18}$', rawTeamId)) {
            teamId = rawTeamId;
        } else {
            teamId = null; // invalid input handled
        }

        if (String.isNotBlank(teamId) && Schema.SObjectType.Team__c.isAccessible()) {
            try {
                teamName = [
                        SELECT Name
                        FROM Team__c
                        WHERE Id = :teamId
                        LIMIT 1
                ].Name;
            } catch (Exception e) {
                teamName = 'Unknown';
            }
        } else {
            teamName = 'Unknown';
        }

        availabilities = getAvailabilityByTeamId(teamId);
    }

    // Method to get availability records wrapped in AvailabilityWrapper2
    public List<AvailabilityWrapper2> getAvailabilityByTeamId(String teamId) {
        List<AvailabilityWrapper2> wrapList = new List<AvailabilityWrapper2>();

        // Only proceed if object and required fields are accessible
        if (!Schema.sObjectType.User_Availability__c.isAccessible() ||
                !Schema.sObjectType.User_Availability__c.fields.Status__c.isAccessible()) {
            return wrapList;
        }

        // Map picklist values to labels
        Map<String, String> statusLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult dfr = User_Availability__c.Status__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            statusLabelMap.put(entry.getValue(), entry.getLabel());
        }

        List<User_Availability__c> avaList = new List<User_Availability__c>();
        if (String.isBlank(teamId)) {
            avaList = [
                    SELECT Id, Status__c, User__r.FirstName, User__r.LastName,
                            User__r.SmallPhotoUrl, User__r.Id, User__r.AboutMe, Team__r.Name
                    FROM User_Availability__c
            ];
        } else if (Schema.sObjectType.Team__c.isAccessible()) {
            avaList = [
                    SELECT Id, Status__c, User__r.FirstName, User__r.LastName,
                            User__r.SmallPhotoUrl, User__r.Id, User__r.AboutMe, Team__r.Name
                    FROM User_Availability__c
                    WHERE Team__c = :teamId
            ];
        }

        for (User_Availability__c ava : avaList) {
            String statusValue = ava.Status__c;
            String statusLabel = statusLabelMap.get(statusValue);

            wrapList.add(new AvailabilityWrapper2(
                    ava.User__r.FirstName,
                    ava.User__r.LastName,
                    ava.User__r.SmallPhotoUrl,
                    String.valueOf(ava.User__r.Id),
                    statusValue,
                    statusLabel,
                    ava.User__r.AboutMe,
                    String.valueOf(ava.Id),
                    ava.Team__r.Name
            ));
        }
        return wrapList;
    }

    // AvailabilityWrapper2 class without AuraEnabled
    public class AvailabilityWrapper2 {
        public String userFirstName { get; set; }
        public String userLastName { get; set; }
        public String photo { get; set; }
        public String userRecordId { get; set; }
        public String Status { get; set; }
        public String StatusLabel { get; set; }
        public String aboutMe { get; set; }
        public String availabilityId { get; set; }
        public String teamName { get; set; }
        public List<String> statusLetters { get; set; }

        public AvailabilityWrapper2(String userFirstName, String userLastName, String photoURL,
                String userRecordId, String Status, String StatusLabel,
                String aboutMe, String availabilityId, String teamName) {
            this.userFirstName = userFirstName;
            this.userLastName = userLastName;
            this.photo = photoURL;
            this.userRecordId = userRecordId;
            this.Status = Status;
            this.StatusLabel = StatusLabel;
            this.aboutMe = aboutMe;
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
}