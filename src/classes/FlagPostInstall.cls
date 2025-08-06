/**
 * Created by adpel on 20/07/2025.
 */
global class FlagPostInstall implements InstallHandler {

    // Test toggle: if true, run error method to test catch
    @TestVisible
    private static Boolean forceErrorForTest = false;

    global void onInstall(InstallContext context) {
        try {
            if (forceErrorForTest) {
                doInstallWithError();
            } else {
                doInstall();
            }
        } catch (Exception e) {
            System.debug('FlagPostInstall error: ' + e.getMessage());
        }
    }

    @TestVisible
    public static void doInstall() {
        // Ensure at least one Flag_Status__c record exists
        List<Flag_Status__c> existing = [SELECT Id FROM Flag_Status__c LIMIT 1];
        if (existing.isEmpty()) {
            Flag_Status__c flag = new Flag_Status__c();
            flag.Flag_Color__c = 'green';
            flag.Last_Checked__c = System.now();
            flag.Notice__c = 'Regular';
            insert flag;
        }

        // Schedule the daily flag check at 6:00 AM if not already scheduled
        scheduleDailyFlagCheck();

        // Call external API to update external flag for this org
        updateExternalFlag('green');
    }

    public static void scheduleDailyFlagCheck() {
        String cronExpr = '0 0 6 * * ?'; // Every day at 6 AM
        String cronExpr1 = '0 5 6 * * ?'; // Every day at 6 AM
        String jobName = 'Daily_FlagCheck1';
        String jobName1 = 'Daily_FlagCheck2';

        try {
            // Remove any existing jobs with the same name
            for (CronTrigger job : [
                    SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName
            ]) {
                System.abortJob(job.Id);
            }
            for (CronTrigger job : [
                    SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName1
            ]) {
                System.abortJob(job.Id);
            }

            System.schedule(jobName, cronExpr, new FlagCheckScheduler());
            System.schedule(jobName1, cronExpr1, new FlagCheckScheduler());
            System.debug('✅ Scheduled job 1 : ' + jobName);
            System.debug('✅ Scheduled job 2 : ' + jobName1);
        } catch (Exception e) {
            System.debug('❌ Failed to schedule job: ' + e.getMessage());
        }
    }

    @Future(Callout=true)
    public static void updateExternalFlag(String flagColor) {
        try {
            HttpRequest req = new HttpRequest();

            // Replace with your actual endpoint URL
            String endpoint = 'https://flagcheck.onrender.com/flag';

            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            // JSON body with flag and orgId
            Map<String, Object> payload = new Map<String, Object>{
                    'flagColor' => flagColor,
                    'orgId' => UserInfo.getOrganizationId(),
                    'notice' => 'Regular'
            };
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('External flag update response status: ' + res.getStatusCode());
            if (res.getStatusCode() != 200) {
                System.debug('External flag update failed: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error during external flag update callout: ' + e.getMessage());
        }
    }

    @TestVisible
    private static void doInstallWithError() {
        throw new CustomException('Forced exception');
    }

    public class CustomException extends Exception {}
}
