/**
 * Created by adpel on 19/08/2025.
 */

global without sharing class FlagOnUninstall implements UninstallHandler {

    global void onUninstall(UninstallContext  context) {
        try {
            // Find any scheduled jobs created by this package
            List<CronTrigger> jobs = [
                    SELECT Id, CronJobDetail.Name
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE 'PostInstallExternalFlagRetry%'
            ];

            // Cancel each one
            for (CronTrigger job : jobs) {
                System.abortJob(job.Id);
            }

        } catch (Exception e) {
            // Defensive catch so uninstall doesn’t error out
            System.debug('Team Manager uninstall cleanup failed: ' + e.getMessage());
        }
    }

}