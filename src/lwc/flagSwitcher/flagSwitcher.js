//import flagcolorcell from 'c/flagcolorcell';
import { LightningElement, track } from 'lwc';

console.log('⚡ FlagSwitcher JS loaded Again');

export default class FlagSwitcher extends LightningElement {
  @track records = [];
  @track draftValues = [];

//	customTypes = {
//			flagcolorcell
//	};


		columns = [
				{ label: 'Org Id', fieldName: 'orgId' },
				{ label: 'App Name', fieldName: 'appName', editable: true },
				{ label: 'Flag Color', fieldName: 'flagColor', editable: true},
//            type: 'flagcolorcell',
//            editable: true,
//            typeAttributes: {
//                value: { fieldName: 'flagColor' },
//                rowId: { fieldName: 'id' }
//            }
//        }
		];


  handleCellChange(event) {
      console.log('✏️ Cell changed:', JSON.stringify(event.detail.draftValues, null, 2));
  }

//  handleCellChange(event) {
//		const { value, rowId } = event.detail;
//
//		// Update draftValues
//		let draft = this.draftValues.find(d => d.id === rowId);
//		if (draft) {
//			draft.flagColor = value;
//		} else {
//			this.draftValues = [...this.draftValues, { id: rowId, flagColor: value }];
//		}
//
//		// Update records array to reflect change immediately
//		const index = this.records.findIndex(r => r.id === rowId);
//		if (index !== -1) {
//			this.records[index] = { ...this.records[index], flagColor: value };
//			this.records = [...this.records]; // refresh reactive array
//		}
//	}

	handleValueChange(event) {
		const { rowId, value } = event.detail;
		const recordIndex = this.records.findIndex(r => r.id === rowId);
		if (recordIndex !== -1) {
			this.records[recordIndex].flagColor = value;
			this.records = [...this.records]; // trigger reactivity
		}
	}

  connectedCallback() {
    fetch('https://flagcheck.onrender.com/flag')
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then(data => {
        console.log("✅ Fetched data:", data);

        // Map backend data to camelCase props
        this.records = data;
//        .map(record => ({
//          id: record._id,
//          orgId: record.orgId,          // camelCase as is
//          appName: record.appName,     // snake_case → camelCase
//          flagColor: record.flagColor, // snake_case → camelCase
//          timestamp: record.timestamp
//        }));
      })
      .catch(error => {
        console.error('❌ Fetch error:', error);
      });
  }

		handleSave(event) {
				const updates = event.detail.draftValues;
				console.log('📝 Draft updates:', JSON.stringify(updates, null, 2));

				// Build new records array with merged updates
				const updatedRecords = this.records.map(record => {
						const update = updates.find(u => u.id === record.id);
						return update
								? {
										...record,
										flagColor: update.flagColor !== undefined ? update.flagColor : record.flagColor,
										appName: update.appName !== undefined ? update.appName : record.appName
								}
								: record;
				});

				this.records = [...updatedRecords]; // Replace array immutably
				this.draftValues = [];              // Clear draft values ASAP

				// Server sync (non-blocking)
				Promise.all(
						updates.map(update =>
								fetch(`https://flagcheck.onrender.com/flag/${update.id}`, {
										method: 'PUT',
										headers: { 'Content-Type': 'application/json' },
										body: JSON.stringify({
												flagColor: update.flagColor,
												appName: update.appName
										})
								}).then(res => {
										if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
										return res.json();
								})
						)
				)
				.then(data => {
						console.log('✅ Updates complete', data);
						return this.refreshData?.(); // Optional
				})
				.catch(error => {
						console.error('❌ Error updating flags:', error);
				});
		}

  refreshData() {
    console.log('📡 refreshData() called');
    return fetch('https://flagcheck.onrender.com/flag')
      .then(res => {
        if (!res.ok) {
          throw new Error('Network response was not ok');
        }
        return res.json();
      })
      .then(data => {
        console.log('🔄 Refreshed data:', data);

        // Map again on refresh
        this.records = data;
//        .map(record => ({
//          id: record._id,
//          orgId: record.orgId,
//          appName: record.app_name,
//          flagColor: record.flag_color,
//          timestamp: record.timestamp
//        }));
      })
      .catch(error => {
        console.error('❌ Error refreshing data:', error);
      });
  }
}
