/**
 * Created by adpel on 05/08/2025.
 */

trigger ProtectFlagStatus on Flag_Status__c (before update, before delete) {
    for (Flag_Status__c rec : Trigger.isDelete ? Trigger.old : Trigger.new) {
        if (!FlagProtectionBypass.bypass && UserInfo.getUserType() != 'System') {
            rec.addError('This record is protected and cannot be edited or deleted.');
        }
    }
}

