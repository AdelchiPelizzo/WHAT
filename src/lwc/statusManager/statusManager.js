/**
 * Created by adpel on 08/07/2025.
 */
import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';


import getStatuses   from '@salesforce/apex/AvailabilityService.getStatuses';
import upsertStatus  from '@salesforce/apex/AvailabilityService.upsertStatus';

export default class StatusManager extends LightningElement {
    // ▸ datatable column‑set (editable)
    columns = [
        { label: 'Status', fieldName: 'adelwhat__Display_Label__c', type: 'text', editable: true },
        { label: 'Type', fieldName: 'adelwhat__Status_Code__c', type: 'text' }
    ];

    @track records ;      // array rendered in the table
    wiredResponse;                // holds the @wire result for refreshApex
		@api recordId;
		draftValues = [];
    /** ─────────────────────────────────────────────────────────────
     * READ  — cacheable Apex call via @wire
     * ──────────────────────────────────────────────────────────── */
		@track error;

		@wire(getStatuses)
		wiredStatuses(result) {
				this.wiredResponse = result;
    		console.log(result);

				if (result.data) {
						this.records = result.data;
						this.error = undefined;
				} else if (result.error) {
						this.records = [];
						this.error = result.error;
				}
		}




    /** ─────────────────────────────────────────────────────────────
     * SAVE — fires when the datatable’s “Save” button is clicked
     * event.detail.draftValues is an array of modified rows
     * ──────────────────────────────────────────────────────────── */
		async handleSave(event) {
    		console.log(event.detail);
				// Convert datatable draft values into record objects
				const records = event.detail.draftValues.map(draft => {
						return {
								fields: {
										Id: draft.Id,  // required
										adelwhat__Display_Label__c: draft.adelwhat__Display_Label__c  // only allow editing the label
								}
						};
				});

				// Clear all datatable draft values
				this.draftValues = [];

				try {
						// Update all records in parallel thanks to the UI API
						const recordUpdatePromises = records.map((record) => updateRecord(record));
						await Promise.all(recordUpdatePromises);
						this.dispatchEvent(
								new ShowToastEvent({
										title: "Success",
										message: "Status updated",
										variant: "success"
								})
						);

						// Display fresh data in the datatable
						await refreshApex(this.wiredResponse);
				} catch (error) {
						console.error('⚠️ Full error object:', JSON.stringify(error, null, 2));

						let message = 'Unknown error occurred';

						try {
								if (Array.isArray(error.body)) {
										message = error.body.map(e => e.message).join(', ');
								} else if (error.body && typeof error.body.message === 'string') {
										message = error.body.message;
								} else if (typeof error.message === 'string') {
										message = error.message;
								} else {
										message = JSON.stringify(error);
								}
						} catch (parseError) {
								message = 'An unexpected error occurred, and the message could not be parsed.';
						}

						this.dispatchEvent(
								new ShowToastEvent({
										title: 'Error updating records',
										message,
										variant: 'error'
								})
						);
				}


		}
}