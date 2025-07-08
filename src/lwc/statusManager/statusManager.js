/**
 * Created by adpel on 08/07/2025.
 */
import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getStatuses   from '@salesforce/apex/AvailabilityService.getStatuses';
import upsertStatus  from '@salesforce/apex/AvailabilityService.upsertStatus';

export default class StatusManager extends LightningElement {
    // ▸ datatable column‑set (editable)
    columns = [
        { label: 'Status', fieldName: 'adelwhat__Display_Label__c', type: 'text', editable: true },
        { label: 'Type', fieldName: 'adelwhat__Status_Code__c', type: 'text', editable: true },
        { label: 'Style', fieldName: 'adelwhat__Style__c', type: 'text',  editable: true }
    ];

    @track draftValues = [];      // holds dirty rows while user edits
    @track records     = [];      // array rendered in the table
    wiredResponse;                // holds the @wire result for refreshApex

    /** ─────────────────────────────────────────────────────────────
     * READ  — cacheable Apex call via @wire
     * ──────────────────────────────────────────────────────────── */
    @wire(getStatuses)
    wiredStatuses(result) {
        this.wiredResponse = result || {};

        const { data, error } = result || {};
        if (data) {
            console.log('>>> !! results >> ',data);
            this.records = data;
            this.error = undefined;
        } else if (error) {
            this.records = [];
            this.error = error;
        }
    }


    /** ─────────────────────────────────────────────────────────────
     * SAVE — fires when the datatable’s “Save” button is clicked
     * event.detail.draftValues is an array of modified rows
     * ──────────────────────────────────────────────────────────── */
    async handleSave(event) {
        const updatedRows = event.detail.draftValues;   // [{MasterLabel:'In', …}, …]

        // Call Apex (imperative) — pass JSON string or List<Map> as your method expects
        try {
            await upsertStatus({ payload: JSON.stringify(updatedRows) });

            this.showToast('Success', 'Status metadata updated.', 'success');
            this.draftValues = [];          // clear table draft state

            // refresh the @wire to pull the latest records from server cache
            await refreshApex(this.wiredResponse);

        } catch (err) {
            const msg = (err.body && err.body.message) ? err.body.message : err.message;
            this.showToast('Error updating metadata', msg, 'error');
        }
    }

    /** helper to fire Lightning toast */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
