/**
 * Created by adpel on 04/08/2025.
 */

import { LightningElement } from 'lwc';
import checkFlagColor from '@salesforce/apex/FlagCheckService.checkFlagColor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlagCheckToast extends LightningElement {
  
		runFlagCheck() {
				checkFlagColor()
						.then(flag => {
								console.log("getting flag..."+JSON.stringify(flag));
//								console.log("notification..."+notice);
								if(flag.Flag_Color__c.toLowerCase() == 'red'){
										this.showToast('Flag Check', `Flag color is: ${flag.Flag_Color__c} because ${flag.Notice__c}` , this.mapColorToVariant(flag.Flag_Color__c));
								}else{
										console.log('Flag Check', `Flag color is: ${flag.Flag_Color__c} because ${flag.Notice__c}`);
        				}
						})
						.catch(error => {
								this.showToast('Error', error.body?.message || 'Flag check failed.', 'error');
						});
		}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    mapColorToVariant(color) {
        switch (color?.toLowerCase()) {
            case 'green':
                return 'success';
            case 'yellow':
                return 'warning';
            case 'red':
                return 'error';
            default:
                return 'info';
        }
    }
}
