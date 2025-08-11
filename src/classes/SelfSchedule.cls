/**
 * Created by adpel on 06/08/2025.
 */

global without sharing class SelfSchedule implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Main work
        System.enqueueJob(new FlagCheckQueueable());

        // Reschedule this job with the same name & cron expression

        // Suppress ApexCRUDViolation: CronTrigger is a system object, no CRUD/FLS enforcement needed, internal use only
        try {
            CronTrigger ct = [
                    SELECT CronExpression, CronJobDetail.Name
                    FROM CronTrigger
                    WHERE Id = :sc.getTriggerId()
                    LIMIT 1
            ];

            // Abort current job to avoid duplicates
            System.abortJob(sc.getTriggerId());

            // Reschedule itself
            System.schedule(ct.CronJobDetail.Name, ct.CronExpression, new SelfSchedule());
        } catch (Exception e) {
            System.debug('⚠️ Self-schedule rescheduling failed: ' + e.getMessage());
        }

        // Ensure both main jobs are alive
        FlagPostInstall.scheduleDailyFlagCheck();
    }
}


//global class SelfSchedule implements Schedulable {
//
//    global void execute(SchedulableContext sc) {
//        System.enqueueJob(new FlagCheckQueueable());
//
//        // Query job details BEFORE aborting
//        CronTrigger ct = [SELECT CronExpression, CronJobDetail.Name FROM CronTrigger WHERE Id = :sc.getTriggerId() LIMIT 1];
//
//        // Abort current job to avoid duplicates
//        System.abortJob(sc.getTriggerId());
//
//        // Reschedule with retrieved jobName and cron expression
//        SelfSchedule.reschedule(ct.CronJobDetail.Name, ct.CronExpression);
//    }
//
//    public static void reschedule(String jobName, String cronExpr) {
//        // Abort any existing jobs with this name before scheduling fresh
//        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
//            System.abortJob(ct.Id);
//        }
//
//        // Schedule again with the same name and cron expression
//        System.schedule(jobName, cronExpr, new SelfSchedule());
//    }

    // Called from post install - schedules both jobs if missing
//    public static void scheduleIfMissing() {
//        String job1Name = 'SelfSchedule_Job1';
//        String job2Name = 'SelfSchedule_Job2';
//
//        Boolean job1Exists = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :job1Name] > 0;
//        Boolean job2Exists = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :job2Name] > 0;
//
//        if (!job1Exists) {
//            // Schedule job1 at 6:00 AM daily
//            System.schedule(job1Name, '0 0 6 * * ?', new SelfSchedule());
//        }
//        if (!job2Exists) {
//            // Schedule job2 at 6:02 AM daily (2 minutes later)
//            System.schedule(job2Name, '0 2 6 * * ?', new SelfSchedule());
//        }
//    }
//}