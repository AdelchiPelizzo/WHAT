/**
 * Created by adpel on 20/07/2025.
 */

@IsTest
private class FlagPostInstallTest {

    // Helper method to abort existing scheduled jobs by name, preventing duplicates errors in tests
    private static void clearScheduledJobs() {
        for (CronTrigger ct : [
                SELECT Id FROM CronTrigger
                WHERE CronJobDetail.Name IN ('SelfSchedule_Job1', 'SelfSchedule_Job2')
        ]) {
            System.abortJob(ct.Id);
        }
    }

    // Helper method to delete Flag_Status__c records to start tests fresh
    private static void deleteFlagStatusRecords() {
        delete [SELECT Id FROM Flag_Status__c];
    }

    @IsTest
    static void testOnInstallNormalFlow() {
        clearScheduledJobs();
        deleteFlagStatusRecords();

        Test.startTest();
        new FlagPostInstall().onInstall(null);
        Test.stopTest();

        // Verify a Flag_Status__c record was created with expected values
        List<Flag_Status__c> flags = [SELECT Id, Flag_Color__c, Notice__c FROM Flag_Status__c];
        System.assertEquals(1, flags.size(), 'One Flag_Status__c record should be created');
        System.assertEquals(null, flags[0].Flag_Color__c);
        System.assertEquals('Regular', flags[0].Notice__c);

        // Verify both scheduled jobs exist
        Integer countJob1 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job1'];
        Integer countJob2 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job2'];
        System.assertEquals(1, countJob1);
        System.assertEquals(1, countJob2);
    }

    @IsTest
    static void testOnInstallForceError() {
        FlagPostInstall.forceErrorForTest = true;
        Test.startTest();
        new FlagPostInstall().onInstall(null);
        Test.stopTest();
        // No exception escapes, just logs, so test passes if no uncaught exception thrown
        FlagPostInstall.forceErrorForTest = false; // Reset flag for other tests
    }

    @IsTest
    static void testDoInstallSchedulesAndInserts() {
        clearScheduledJobs();
        deleteFlagStatusRecords();

        Test.startTest();
        FlagPostInstall.doInstall();
        Test.stopTest();

        List<Flag_Status__c> flags = [SELECT Id FROM Flag_Status__c];
        System.assert(flags.size() > 0, 'Flag_Status__c should be inserted');

        Integer countJob1 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job1'];
        Integer countJob2 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job2'];
        System.assertEquals(1, countJob1);
        System.assertEquals(1, countJob2);
    }

    @IsTest
    static void testScheduleDailyFlagCheckDoesNotDuplicate() {
        clearScheduledJobs();

        // Manually schedule job1 first to simulate it already existing
        System.schedule('SelfSchedule_Job1', '0 0 6 * * ?', new SelfSchedule());

        Test.startTest();
        FlagPostInstall.scheduleDailyFlagCheck();
        Test.stopTest();

        // Job1 count should stay 1, job2 should be scheduled as it was missing
        Integer countJob1 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job1'];
        Integer countJob2 = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SelfSchedule_Job2'];

        System.assertEquals(1, countJob1, 'Job1 should not be duplicated');
        System.assertEquals(1, countJob2, 'Job2 should be scheduled because it was missing');
    }

    @IsTest
    static void testUpdateExternalFlagCallout() {
        Test.startTest();
        FlagPostInstall.updateExternalFlag('green');
        Test.stopTest();
        // No asserts needed here, just coverage and to ensure no exceptions
    }

    @IsTest
    static void testDoInstallSchedulesOneTimeRetryJob() {
        clearScheduledJobs();
        deleteFlagStatusRecords();

        Test.startTest();
        FlagPostInstall.doInstall();
        Test.stopTest();

        // Check that the one-time retry job was scheduled
        List<CronTrigger> retryJobs = [
                SELECT Id, CronJobDetail.Name, CronExpression
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'PostInstallExternalFlagRetry_%'
        ];

        System.assertEquals(1, retryJobs.size(), 'Exactly one one-time retry job should be scheduled');

        CronTrigger retryJob = retryJobs[0];
        System.assert(retryJob.CronJobDetail.Name.startsWith('PostInstallExternalFlagRetry_'),
                'Scheduled job name should start with PostInstallExternalFlagRetry_');

        // Validate that cron expression is well formed (basic check)
        // Format expected: sec min hour day month ? year (7 parts)
        List<String> cronParts = retryJob.CronExpression.split(' ');
        System.assertEquals(7, cronParts.size(), 'Cron expression should have 7 parts');

        // The seconds, minutes, and hour fields should be within expected ranges
        Integer sec = Integer.valueOf(cronParts[0]);
        Integer min = Integer.valueOf(cronParts[1]);
        Integer hour = Integer.valueOf(cronParts[2]);

        System.assert(sec >= 0 && sec < 60, 'Seconds part of cron expression should be valid');
        System.assert(min >= 0 && min < 60, 'Minutes part of cron expression should be valid');
        System.assert(hour >= 0 && hour < 24, 'Hour part of cron expression should be valid');
    }

    @IsTest
    static void testOnUninstallCancelsJobs() {
        // Schedule a dummy job matching the uninstall pattern
        Datetime dt = System.now().addMinutes(1);
        String cronExp = FlagPostInstall.buildOneTimeCron(dt);
        String jobName = 'PostInstallExternalFlagRetry_' + dt.getTime();
        System.schedule(jobName, cronExp, new ExternalFlagUpdateScheduler());

        // Verify job exists
        List<CronTrigger> scheduledJobs = [
                SELECT Id, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
        ];
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');

        // Call onUninstall
        Test.startTest();
        FlagOnUninstall unInstall = new FlagOnUninstall();
        unInstall.onUninstall(null); // context not used
        Test.stopTest();

        // Assert job is aborted
        List<CronTrigger> remainingJobs = [
                SELECT Id, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
        ];
        System.assertEquals(0, remainingJobs.size(), 'Job should be aborted by uninstall');
    }

}