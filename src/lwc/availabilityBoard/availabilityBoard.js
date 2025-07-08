/**
 * Created by adpel on 01/07/2025.
 */
/**
 * AvailabilityBoard — live “airport board” of user availability
 */

import { LightningElement, wire, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import getUsersAvailability from '@salesforce/apex/AvailabilityService.getAvailabilityWithUser';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

const CHANNEL = '/data/adelwhat__User_Availability__ChangeEvent'; // keep namespace if object is namespaced
const DEBOUNCE = 100;      // 🆕 wait 100 ms to coalesce bursts

let call = 0;
export default class AvailabilityBoard extends NavigationMixin(LightningElement) {
    /** @type {import('lwc').WireAdapterConfig} */
    wiredRows;              // saved wire state for refreshApex()
    @track rows = [];       // what the template renders

    // 1️⃣ initial query (cacheable=true in Apex keeps this fast)

//    connectedCallback() {
//        this.registerErrorListener();
//        this.subscribeToCdc();
//    }

    isPopout = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__popout === 'true') {
            this.isPopout = true;
        }
    }

    openPopout() {
        const width = 800;
        const height = 600;
        const left = (window.screen.width / 2) - (width / 2);
        const top = (window.screen.height / 2) - (height / 2);
        window.open(
            '/apex/AvailabilityBoardPopup',
            'AvailabilityPanel',
            `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`
        );
    }

   @wire(getUsersAvailability)
   wiredRowsHandler(value) {
       call++;
       console.group(`⚡ wire call #${call}`);

       console.log('value.data:', value.data);
       console.log('value.data type:', typeof value.data);
       console.log('value.data instanceof Array:', value.data instanceof Array);
       console.log('value.data length:', value.data?.length ?? 'undefined');

       this.wiredRows = value;

       if (value.data) {
           // Try all three assignments, comment/uncomment each time to test
           this.rows = value.data;
           // this.rows = [...value.data];
           // this.rows = JSON.parse(JSON.stringify(value.data));
       } else {
           this.rows = [];
       }

       console.log('this.rows:', this.rows);
       console.log('this.rows type:', typeof this.rows);
       console.log('this.rows instanceof Array:', this.rows instanceof Array);
       console.log('this.rows length:', this.rows?.length ?? 'undefined');

       console.groupEnd();
   }

    get processedRows() {
      return this.rows.map(row => {
        return {
          ...row,
          statusClass: 'status-badge ' + row.Status.toLowerCase().replace(/\s/g, '-')
        };
      });
    }


    // 2️⃣ subscribe once the component is inserted in the DOM
    connectedCallback() {
        this.registerErrorListener();
        this.subscribeToCdc();

        // Optional safety net: re‑query every 60 s if socket silently drops
//        this.refreshTimer = setInterval(
//            () => refreshApex(this.wiredRows),
//            60000
//        );
        const urlParams = new URLSearchParams(window.location.search);
        this.isPopout = urlParams.get('c__popout') === 'true';
    }

    // 🆕 debounce helpers
    debounceHandle;
    scheduleRefresh() {
        console.log('scheduling refresh');
        clearTimeout(this.debounceHandle);
        this.debounceHandle = setTimeout(
            () => refreshApex(this.wiredRows),
            DEBOUNCE
        );
    }

    // 3️⃣ CDC subscription
    subscribeToCdc() {
        const messageCallback = (evt) => {
            console.log('🔔 CDC', evt);
            // 🆕 only refresh on CREATE or UPDATE, ignore deletes/undeletes
            const changeType = evt?.data?.payload?.ChangeEventHeader?.changeType;
            console.log('🛈 changeType =', changeType);
            if (changeType === 'CREATE' || changeType === 'UPDATE' || changeType === 'DELETE') {
                this.scheduleRefresh();
            }
        };

        subscribe(CHANNEL, -1, (evt) => {
            console.log('🔔 EVENT', evt);                 // 1
            const type = evt?.data?.ChangeEventHeader?.changeType;
            console.log('🛈 changeType =', type);         // 2
            if (type === 'CREATE' || type === 'UPDATE') {
                this.scheduleRefresh();
            }
        }).then(sub => console.log('✅ SUB', sub))
          .catch(err => console.error('❌ SUB ERR', err));


        subscribe(CHANNEL, -1, messageCallback).then((resp) => {
            this.subscription = resp;
            console.log('✅ SUB', resp);
        });
    }

    registerErrorListener() {
        onError((error) =>
            // eslint-disable-next-line no-console
            console.error('CDC error', JSON.stringify(error))
        );
    }


    // 4️⃣ clean‑up
    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {});
        }
        clearInterval(this.refreshTimer);
        clearTimeout(this.debounceHandle);   // 🆕
    }
}
