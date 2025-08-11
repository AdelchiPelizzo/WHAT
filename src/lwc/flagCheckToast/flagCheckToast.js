/**
 * Created by adpel on 04/08/2025.
 */

import { LightningElement } from 'lwc';
import checkFlagColor from '@salesforce/apex/FlagCheckService.checkFlagColor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getNamespacePrefix from '@salesforce/apex/FlagCheckService.getNamespacePrefix';

export default class FlagCheckToast extends LightningElement {
  
		runFlagCheck() {
			getNamespacePrefix()
				.then(ns => {
					console.log('Namespace is:', ns);
					this.ns = ns; // assign namespace to this.ns so you can reuse later
					return checkFlagColor();
				})
				.then(flag => {
					console.log("getting flag...", JSON.stringify(flag));

					// Now use this.ns
					const color = flag[`${this.ns}Flag_Color__c`]?.toLowerCase();
					const notice = flag[`${this.ns}Notice__c`];

					if (color === 'red') {
						this.showToast(
							'Flag Check',
							`Flag color is: ${flag[`${this.ns}Flag_Color__c`]} because ${notice}`,
							this.mapColorToVariant(flag[`${this.ns}Flag_Color__c`])
						);
					} else {
						console.log('Flag Check', `Flag color is: ${flag[`${this.ns}Flag_Color__c`]} because ${notice}`);
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