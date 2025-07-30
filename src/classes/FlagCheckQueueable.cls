/**
 * Created by adpel on 22/07/2025.
 */

public class FlagCheckQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        try {
            Boolean isRed = FlagCache.checkFlag();
            System.debug('Flag check result (from queueable): ' + isRed);
        } catch (Exception e) {
            System.debug('Flag check failed in queueable: ' + e.getMessage());
            // Optionally store in custom object for monitoring
        }
    }
}