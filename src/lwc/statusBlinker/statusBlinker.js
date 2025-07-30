/**
 * Created by adpel on 13/07/2025.
 */

import { LightningElement, api, track } from 'lwc';

export default class StatusBlinker extends LightningElement {
  @track _status;
  @track _statusLabel;

  @track blinking = false;
  initialized = false;
  blinkTimer;

  	connectedCallback() {
      this.initialized = false;
      setTimeout(() => {
        this.initialized = true;
      }, 500); // half a second to stabilize initial data
    }

		@api
		get status() {
			console.log(' GETTING status in blinker 🚦🚦🚦🚦  '+this._status)	;
			return this._status;
		}

    set status(value) {
      const hasChanged = this._status !== value;
      this._status = value;

      if (this.initialized && hasChanged) {
        this.startBlinking();
      }
    }
//
//		set status(value) {
//			const isFirstSet = !this.initialized;
//			const hasChanged = this._status !== value;
//			this._status = value;
//
//			if (isFirstSet) {
//				this.initialized = true;
//			} else if (hasChanged) {
//				this.startBlinking();
//			}
//		}

		set statusLabel(value) {
			this._statusLabel = value;
			// Don't trigger blinking here — only use `status` to detect changes
		}

		@api
		get statusLabel() {
			console.log(' GETTING statusLabel in blinker 🚦🚦🚦🚦  '+this._statusLabel)	;
			return this._statusLabel;
		}

//		@api
//		get statusClass() {
//			console.log('getting status class');
//
//			const status = (this._status || '').toLowerCase();
//			const label = (this._statusLabel || '').toLowerCase();
//
//			if (status === 'active' || status === 'inactive' || status === 'pause') {
//				const statusClass = `status-word ${status} ${this.blinking ? 'blinking' : ''}`.trim();
//				console.log('Computed class:', statusClass);
//				return statusClass;
//			}else{
//				console.log('No matching label, returning empty string');
//				return '';
//			}
//		}

  	get statusClass() {
      const status = (this._status || '').toLowerCase();
      const blinkingClass = this.blinking ? 'blinking' : '';
      const cls = ['status-word', status, blinkingClass].filter(Boolean).join(' ');
      console.log('statusClass computed:', cls);
      return cls;
    }


  startBlinking() {
    clearTimeout(this.blinkTimer);
    this.blinking = true;
    this.blinkTimer = window.setTimeout(() => {
      this.blinking = false;
    }, 10000);
  }

  disconnectedCallback() {
    window.clearTimeout(this.blinkTimer);

  }
}


