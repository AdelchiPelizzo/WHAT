/**
 * EmployeeAvailability – Screen Quick Action
 * Shows a radio‑button picker and saves the user’s status immediately.
 */
import { LightningElement, track, wire, api } from 'lwc';
import { createRecord, updateRecord }         from 'lightning/uiRecordApi';
import { CloseActionScreenEvent }             from 'lightning/actions';
import { ShowToastEvent }                     from 'lightning/platformShowToastEvent';

import USER_ID                                from '@salesforce/user/Id';
import getAvailabilityWithUser                from '@salesforce/apex/AvailabilityService.getAvailabilityWithUser';

import USER_AVAIL_OBJECT                      from '@salesforce/schema/User_Availability__c';
import ID_FIELD                               from '@salesforce/schema/User_Availability__c.Id';
import STATUS_FLD                             from '@salesforce/schema/User_Availability__c.Status__c';
import USER_FLD                               from '@salesforce/schema/User_Availability__c.User__c';

export default class EmployeeAvailability extends LightningElement {
    /* ------------ reactive state ------------ */
    @api   recordId;         // not used here but handy if ever needed
    @track selectedStatus;
    @track userName   = 'there';
    @track availId;          // existing Availability record Id (if any)
    @track isSaving   = false;
    @track saveError  = false;

    /* ------------ radio‑button options ------------ */
    statusOptions = [
        { label: 'Active',   value: 'In' },
        { label: 'Paused',   value: 'At Lunch' },
        { label: 'Inactive', value: 'OOO' }
    ];

    /* ------------ load current availability ------------ */
    @wire(getAvailabilityWithUser)
    wiredWrapper({ data, error }) {
        if (data?.length) {
            const mine = data.find(w => w.userRecordId === USER_ID);
            if (mine) {
                this.selectedStatus = mine.Status;
                this.userName       = mine.userFirstName;
                this.availId        = mine.availabilityId ?? mine.Id ?? null;
            }
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Availability load error', error);
        }
    }

    /* ------------ modal: click outside to close ------------ */

    connectedCallback() {
        this._outsideHandler = (e) => {
            // the modal container the user can click inside
            const modalContainer = document.querySelector('.slds-modal__container');
            if (!modalContainer) return;           // modal not rendered yet

            if (!modalContainer.contains(e.target)) {
                // click landed outside the modal – close it
                this.close();
            }
        };
        document.addEventListener('mousedown', this._outsideHandler, true);
    }

    disconnectedCallback() {
        document.removeEventListener('mousedown', this._outsideHandler, true);
    }

    /* ------------ computed greeting ------------ */
    get greeting() {
        return `Hello ${this.userName}`;
    }

    /* ------------ radio change → save instantly ------------ */
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        return this.save();                 // return promise so QA waits
    }

    /* ------------ create / update logic ------------ */
    async save() {
        this.isSaving  = true;
        this.saveError = false;

        const fields = {
            [STATUS_FLD.fieldApiName]: this.selectedStatus,
            [USER_FLD.fieldApiName]:   USER_ID
        };

        try {
            const result = this.availId
                ? await updateRecord({
                      fields: { ...fields, [ID_FIELD.fieldApiName]: this.availId }
                  })
                : await createRecord({
                      apiName: USER_AVAIL_OBJECT.objectApiName,
                      fields
                  });

            if (result?.id) this.availId = result.id;

            /* toast while panel is alive */
            this.dispatchEvent(
                new ShowToastEvent({
                    title:   'Status Updated',
                    message: 'Your availability has been saved.',
                    variant: 'success',
                    mode:    'dismissable'
                })
            );

            /* keep the panel up for ~2 s so toast is visible */
            await new Promise((r) => setTimeout(r, 2000));

            /* now close deliberately */
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.saveError = true;
            // eslint-disable-next-line no-console
            console.error('Save failed', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title:   'Save Failed',
                    message: error.body?.message || 'Could not update your status.',
                    variant: 'error',
                    mode:    'sticky'
                })
            );
        } finally {
            this.isSaving = false;
        }
    }

    /* ------------ helper ------------ */
    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
