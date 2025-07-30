/**
 * Created by adpel on 22/07/2025.
 */

global class FlagCheckScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        System.debug('⏰ Scheduled flag check started');
        System.enqueueJob(new FlagCheckQueueable());
        System.debug('🚀 Flag check job enqueued');
    }
}
