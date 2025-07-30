/**
 * Created by adpel on 20/07/2025.
 */

import { LightningElement, api } from 'lwc';

export default class FlagColorcell extends LightningElement {
    @api value;
    @api rowId;

    get options() {
        return [
            { label: 'Green', value: 'green' },
            { label: 'Red', value: 'red' },
            { label: 'Yellow', value: 'yellow' }
        ];
    }

    handleChange(event) {
        const newValue = event.detail.value;
        this.dispatchEvent(new CustomEvent('cellchange', {
            detail: {
                draftValues: [
                    {
                        id: this.rowId,
                        flagColor: newValue
                    }
                ]
            },
            bubbles: true,
            composed: true
        }));
    }
}




