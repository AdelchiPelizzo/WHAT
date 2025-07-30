/**
 * Created by adpel on 01/07/2025.
 * AvailabilityBoard — live “airport board” of user availability
 */

import { LightningElement, wire, track, api } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import getUsersAvailability from '@salesforce/apex/AvailabilityService.getAvailabilityWithUser2';
import getAvailabilityByTeamId from '@salesforce/apex/AvailabilityService.getAvailabilityByTeamId2';
import getTeamNames from '@salesforce/apex/AvailabilityService.getTeamOptions';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

const CHANNEL  = '/data/adelwhat__User_Availability__ChangeEvent';   // keep namespace if object is namespaced
const DEBOUNCE = 100;
let call = 0;

export default class AvailabilityBoard extends NavigationMixin(LightningElement) {

    teamOptions = [];

    selectedTeamId = '';


    /** saved wire state so we can refreshApex() later */
    wiredRows;
    teamId = '';                                            // coalesce bursts
    @api teamName;
    /** raw rows from Apex (reactive thanks to @track) */
    @track availabilityRecords = []; // Make it reactive

    /* ───────────────────────── UI state ───────────────────────── */

    isPopout   = false;
    @track statusText = 'IN';          // for the standalone flip, if you keep it

    /* ───────────────────────── page params ────────────────────── */

    @wire(CurrentPageReference)
    getStateParameters(ref) {
        if (ref?.state?.c__popout === 'true') {
            this.isPopout = true;
        }
    }

    /* ───────────────────────── wire: initial query ────────────── */

		@track rows = [];

		get hasData() {
				return this.rows.length > 0;
		}


    @wire(getAvailabilityByTeamId, {teamId: '$selectedTeamId'})
    wiredRowsHandler(value) {
        call++;
        console.group(`⚡ wire call #${call}`);

        this.wiredRows = value;               // stash for refreshApex

        if (value.data) {
            // clone so later mutations don’t touch the wire cache
            this.rows = [...value.data];
        } else {
            this.rows = [];
        }
				console.log(' ✔️ '+JSON.stringify(this.rows));
        console.groupEnd();
    }

    @wire(getUsersAvailability)
    wiredAllRows(value) {
        if (!this.selectedTeamId) {
            this.wiredRows = value;
            if (value.data) this.rows = [...value.data];
            else this.rows = [];
        }
    }

    /* ───────────────────────── derived rows for template ──────── */

//		get processedRows() {
//				return this.rows.map(row => {
//						const status = row.Status || '';
//						const statusLabel = row.StatusLabel || status;
//
//						return {
//								...row,
//								status,
//								statusLabel,
//								statusLower: status.toLowerCase(),
//								statusClass: 'status-word ' + status.toLowerCase().replace(/\s/g, '-'),
//								rowKey: row.userRecordId + '-' + status // 👈 force re-key on status change
//						};
//				});
//		}

		get processedRows() {
				return this.rows.map(row => {
//						console.log('DEBUG row:', row);

						const status = row.Status || '';
						const statusLabel = row.StatusLabel || status;

						const statusClass = 'status-word ' + status.toLowerCase().replace(/\s/g, '-');

						console.log('→ Status value:', status);
						console.log('→ Computed class:', statusClass);

						return {
								...row,
								status,
								statusLabel,
								statusClass,
								rowKey: row.userRecordId + '-' + status
						};
				});
		}

    /* ───────────────────────── lifecycle: mount ───────────────── */

    connectedCallback() {

//        this._visibilityCheckInterval = setInterval(() => {
//            if (document.visibilityState === 'visible') {
//                console.log('Tab is visible (polling)');
//                this.scheduleRefresh();  // Your refresh logic here
//            }
//        }, 1000);
        this.registerErrorListener();
        this.subscribeToCdc();
        this.loadAvailability(null); // load all on start
        getTeamNames()
                .then(result => {
                    this.teamOptions = result.map(team => ({
                        label: team.Name,
                        value: team.Id
                    }));
                })
                .catch(error => { console.error('Error loading team options:', error); });
        // If the component is used outside Lightning (e.g., VF pop‑out)
        const urlParams = new URLSearchParams(window.location.search);
        this.isPopout = urlParams.get('c__popout') === 'true';
    }


		renderCount = 0;
    renderedCallback() {
				this.renderCount++;
				console.log(`renderedCallback ran [${this.renderCount}]`);
				if (this._status || this._statusLabel) {
					console.log('Rendered with class:', this.statusClass);
				}
    }

        // This is the helper method that calls Apex and updates availabilityRecords
    loadAvailability(teamId) {
        getAvailabilityByTeamId({ teamId: teamId })
            .then(result => {
                this.availabilityRecords = result;
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Called when user changes the team picklist selection
    handleTeamChange(event) {
        this.selectedTeamId = event.target.value || null;
        sessionStorage.setItem('selectedTeamId', this.selectedTeamId);
        this.loadAvailability();
        console.log('Selected teamId:', this.selectedTeamId);

        if (this.selectedTeamId) {
            getAvailabilityByTeamId({ teamId: this.selectedTeamId })
                .then(result => {
                    console.log('Filtered availability:', result);
                    this.availabilityRecords = result;
                })
                .catch(error => {
                    console.error('Error loading filtered availability:', error);
                });
        } else {
            // If no team selected, fall back to all records:
            getUsersAvailability()
                .then(result => {
                    this.availabilityRecords = [...result];
                })
                .catch(error => {
                    console.error('Error reloading all availability:', error);
                });
        }
    }

    /* ───────────────────────── CDC subscription ───────────────── */

    debounceHandle;
    scheduleRefresh() {
        clearTimeout(this.debounceHandle);
        this.debounceHandle = setTimeout(
            () => refreshApex(this.wiredRows),
            DEBOUNCE
        );
    }

    subscribeToCdc() {
        const handler = evt => {
            const type = evt?.data?.payload?.ChangeEventHeader?.changeType;
            if (type === 'CREATE' || type === 'UPDATE' || type === 'DELETE') {
                this.scheduleRefresh();
            }
        };

        subscribe(CHANNEL, -1, handler)
            .then(sub => { this.subscription = sub; console.log('✅ SUB', sub); })
            .catch(err => console.error('❌ SUB ERR', err));
    }

    registerErrorListener() {
        onError(error =>
            console.error('CDC error', JSON.stringify(error))
        );
    }

    /* ───────────────────────── lifecycle: unmount ─────────────── */

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {});
        }
        clearTimeout(this.debounceHandle);
        clearInterval(this._visibilityCheckInterval);
    }

    openPopout() {
        window.open(
            '/apex/adelwhat__AvailabilityPopoutBlinking',
            'AvailabilityBoardPopupWindow',
            'width=1000,height=700,resizable=yes,scrollbars=yes'
        );
    }

    openPopoutFiltered(event) {
        event.preventDefault();
        if (!this.selectedTeamId) {
            alert('Please select a team first.');
            return;
        }
        const teamParam = `&teamId=${encodeURIComponent(this.selectedTeamId)}`;
        console.log(teamParam);

        window.open(
            `/apex/adelwhat__AvailabilityPopout3?=${teamParam}`,
            'AvailabilityBoardPopupWindow',
            'width=1000,height=700,resizable=yes,scrollbars=yes'
        );
    }

    openPicklistSetup() {
      window.open('/lightning/setup/ObjectManager/01IgL000000sQqL/FieldsAndRelationships/00NgL000010uACH/view', '_blank');
    }

}
