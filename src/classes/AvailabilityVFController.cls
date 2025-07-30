/**
 * Created by adpel on 27/07/2025.
 */

public with sharing class AvailabilityVFController {
    public String teamId { get; set; }
    public String teamName { get; private set; }
    public List<AvailabilityWrapper2> availabilities { get; set; }

    // Constructor
    public AvailabilityVFController() {
        // Get teamId from URL params (if any)
        teamId = ApexPages.currentPage().getParameters().get('teamId');
        if (String.isNotBlank(teamId)) {
            try {
                teamName = [SELECT Name FROM adelwhat__Team__c WHERE Id = :teamId LIMIT 1].Name;
            } catch (Exception e) {
                teamName = 'Unknown';
            }
        }
        availabilities = getAvailabilityByTeamId(teamId);
    }

    // Method to get availability records wrapped in AvailabilityWrapper2
    public List<AvailabilityWrapper2> getAvailabilityByTeamId(String teamId) {
        List<AvailabilityWrapper2> wrapList = new List<AvailabilityWrapper2>();

        // Map picklist values to labels
        Map<String, String> statusLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult dfr = adelwhat__User_Availability__c.adelwhat__Status__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            statusLabelMap.put(entry.getValue(), entry.getLabel());
        }

        List<adelwhat__User_Availability__c> avaList;
        if (String.isBlank(teamId)) {
            avaList = [SELECT Id, adelwhat__Status__c, adelwhat__User__r.FirstName, adelwhat__User__r.LastName, adelwhat__User__r.SmallPhotoUrl, adelwhat__User__r.Id, adelwhat__User__r.AboutMe, adelwhat__Team__r.Name FROM adelwhat__User_Availability__c];
        } else {
            avaList = [SELECT Id, adelwhat__Status__c, adelwhat__User__r.FirstName, adelwhat__User__r.LastName, adelwhat__User__r.SmallPhotoUrl, adelwhat__User__r.Id, adelwhat__User__r.AboutMe, adelwhat__Team__r.Name FROM adelwhat__User_Availability__c WHERE adelwhat__Team__c = :teamId];
        }

        for (adelwhat__User_Availability__c ava : avaList) {
            String statusValue = ava.adelwhat__Status__c;
            String statusLabel = statusLabelMap.get(statusValue);

            wrapList.add(new AvailabilityWrapper2(
                    ava.adelwhat__User__r.FirstName,
                    ava.adelwhat__User__r.LastName,
                    ava.adelwhat__User__r.SmallPhotoUrl,
                    String.valueOf(ava.adelwhat__User__r.Id),
                    statusValue,
                    statusLabel,
                    ava.adelwhat__User__r.AboutMe,
                    String.valueOf(ava.Id),
                    ava.adelwhat__Team__r.Name
            ));
        }
        return wrapList;
    }

    // AvailabilityWrapper2 class without AuraEnabled (nested or separate global class)
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

        public AvailabilityWrapper2(String userFirstName, String userLastName, String photoURL, String userRecordId, String Status, String StatusLabel, String aboutMe, String availabilityId, String teamName) {
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
