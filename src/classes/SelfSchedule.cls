/**
 * Created by adpel on 06/08/2025.
 */
global class SelfSchedule implements schedulable
{
    global void execute( SchedulableContext SC )
    {

        // do whatever it is you want to do here

        System.enqueueJob(new FlagCheckQueueable());
        SelfSchedule.start();

        // abort me and start again
        System.abortJob( SC.getTriggerId() );
    }

    public static void start()
    {
        // start keepalive again in 5 mins
        Datetime sysTime = System.now().addSeconds( 300 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule( 'SelfSchedule ' + sysTime, chronExpression, new SelfSchedule() );
    }

}
