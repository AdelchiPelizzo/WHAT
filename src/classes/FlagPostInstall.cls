/**
 * Created by adpel on 20/07/2025.
 */

global class FlagPostInstall implements InstallHandler {

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
        // Existing code to insert Flag_Status__c if none exists
        List<Flag_Status__c> existing = [SELECT Id FROM Flag_Status__c LIMIT 1];
        if (existing.isEmpty()) {
            Flag_Status__c flag = new Flag_Status__c();
            flag.Flag_Color__c = 'green';
            flag.Last_Checked__c = System.now();
            flag.Notice__c = 'Regular';
            insert flag;
        }

        // Schedule daily flag check and watchdog
        scheduleDailyFlagCheck();
        scheduleWatchdogJob();

        // Immediate call to external server
        updateExternalFlag('green');

        // Schedule one-time retry call 1 minute after install
        Datetime oneMinuteLater = System.now().addMinutes(1);
        String cronExp = buildOneTimeCron(oneMinuteLater);
        System.schedule('PostInstallExternalFlagRetry_' + oneMinuteLater.getTime(), cronExp, new ExternalFlagUpdateScheduler());
    }

// Helper to build a cron expression for one-time scheduled Apex
    private static String buildOneTimeCron(Datetime dt) {
        Integer sec = dt.second();
        Integer min = dt.minute();
        Integer hour = dt.hour();
        Integer day = dt.day();
        Integer month = dt.month();

        // Format: sec min hour day month ? year
        return String.format('{0} {1} {2} {3} {4} ? {5}',
                new List<Object>{sec, min, hour, day, month, dt.year()});
    }

    public static void scheduleDailyFlagCheck() {
        String jobName1 = 'SelfSchedule_Job1';
        String jobName2 = 'SelfSchedule_Job2';

        String cronExpr1 = '0 0 6 * * ?'; // 6:00 AM
        String cronExpr2 = '0 2 6 * * ?'; // 6:02 AM

        try {
            Set<String> existingJobs = new Set<String>();

            for (CronTrigger ct : [
                    SELECT CronJobDetail.Name
                    FROM CronTrigger
                    WHERE CronJobDetail.Name IN :new List<String>{ jobName1, jobName2 }
            ]) {
                existingJobs.add(ct.CronJobDetail.Name);
            }

            if (!existingJobs.contains(jobName1)) {
                System.schedule(jobName1, cronExpr1, new SelfSchedule());
                System.debug('✅ Scheduled missing job: ' + jobName1);
            }
            if (!existingJobs.contains(jobName2)) {
                System.schedule(jobName2, cronExpr2, new SelfSchedule());
                System.debug('✅ Scheduled missing job: ' + jobName2);
            }
        } catch (Exception e) {
            System.debug('❌ Error scheduling daily flag check jobs: ' + e.getMessage());
        }
    }

    public static void scheduleWatchdogJob() {
        String jobName = 'ScheduledJobSafe';
        String cronExpr = '0 0 7 * * ?'; // 7:00 AM daily

        try {
            Boolean exists = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name = :jobName
            ] > 0;

            if (!exists) {
                System.schedule(jobName, cronExpr, new ScheduledJobSafe());
                System.debug('✅ Watchdog scheduled.');
            }
        } catch (Exception e) {
            System.debug('❌ Error scheduling watchdog job: ' + e.getMessage());
        }
    }

    @Future(Callout=true)
    public static void updateExternalFlag(String flagColor) {
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://flagcheck.onrender.com/flag';
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

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


//global class FlagPostInstall implements InstallHandler {
//
//    // Test toggle: if true, run error method to test catch
//    @TestVisible
//    private static Boolean forceErrorForTest = false;
//
//    global void onInstall(InstallContext context) {
//        try {
//            if (forceErrorForTest) {
//                doInstallWithError();
//            } else {
//                doInstall();
//            }
//        } catch (Exception e) {
//            System.debug('FlagPostInstall error: ' + e.getMessage());
//        }
//    }
//
//    @TestVisible
//    public static void doInstall() {
//        // Ensure at least one Flag_Status__c record exists
//        List<Flag_Status__c> existing = [SELECT Id FROM Flag_Status__c LIMIT 1];
//        if (existing.isEmpty()) {
//            Flag_Status__c flag = new Flag_Status__c();
//            flag.Flag_Color__c = 'green';
//            flag.Last_Checked__c = System.now();
//            flag.Notice__c = 'Regular';
//            insert flag;
//        }
//
//        // Schedule the daily flag check at 6:00 AM if not already scheduled
//        scheduleDailyFlagCheck();
//
//        // Call external API to update external flag for this org
//        updateExternalFlag('green');
//    }
//
//    public static void scheduleDailyFlagCheck() {
//        String jobName1 = 'SelfSchedule_Job1';
//        String jobName2 = 'SelfSchedule_Job2';
//
//        String cronExpr1 = '0 0 6 * * ?';   // 6:00 AM daily
//        String cronExpr2 = '0 2 6 * * ?';   // 6:02 AM daily
//
//        try {
//            // Abort existing jobs for job1
//            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName1]) {
//                System.abortJob(ct.Id);
//            }
//            // Abort existing jobs for job2
//            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName2]) {
//                System.abortJob(ct.Id);
//            }
//
//            // Now schedule both jobs fresh
//            System.schedule(jobName1, cronExpr1, new SelfSchedule());
//            System.schedule(jobName2, cronExpr2, new SelfSchedule());
//
//            System.debug('✅ Scheduled jobs: ' + jobName1 + ', ' + jobName2);
//        } catch (Exception e) {
//            System.debug('❌ Failed to schedule self-schedule jobs: ' + e.getMessage());
//        }
//    }
//
//    @Future(Callout=true)
//    public static void updateExternalFlag(String flagColor) {
//        try {
//            HttpRequest req = new HttpRequest();
//
//            // Replace with your actual endpoint URL
//            String endpoint = 'https://flagcheck.onrender.com/flag';
//
//            req.setEndpoint(endpoint);
//            req.setMethod('POST');
//            req.setHeader('Content-Type', 'application/json');
//
//            // JSON body with flag and orgId
//            Map<String, Object> payload = new Map<String, Object>{
//                    'flagColor' => flagColor,
//                    'orgId' => UserInfo.getOrganizationId(),
//                    'notice' => 'Regular'
//            };
//            req.setBody(JSON.serialize(payload));
//
//            Http http = new Http();
//            HttpResponse res = http.send(req);
//
//            System.debug('External flag update response status: ' + res.getStatusCode());
//            if (res.getStatusCode() != 200) {
//                System.debug('External flag update failed: ' + res.getBody());
//            }
//        } catch (Exception e) {
//            System.debug('Error during external flag update callout: ' + e.getMessage());
//        }
//    }
//
//    @TestVisible
//    private static void doInstallWithError() {
//        throw new CustomException('Forced exception');
//    }
//
//    public class CustomException extends Exception {}
//}