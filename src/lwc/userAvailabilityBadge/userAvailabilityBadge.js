/**
 * Created by adpel on 17/06/2025.
 */

// userAvailabilityBadge.js
import { LightningElement, api, track } from 'lwc';
import getAvailabilityWithUser from "@salesforce/apex/AvailabilityService.getAvailabilityWithUser"



export default class UserAvailabilityBadge extends LightningElement {

    draftValues = [];
    columns = [
        {
            label: 'Status',
            fieldName: 'Status',
            cellAttributes: {
                class: {fieldName:'Format'},
                iconName: {fieldName:'Icon'},
            },
        },
        { label: 'Name', fieldName: 'userFirstName' },
        { label: 'Id', fieldName: 'Id', type: 'url', typeAttributes: {label: { fieldName: 'Id' }, target: '_blank' } },
    ];

    @track usersAvailability = [];
    connectedCallback() {
        getAvailabilityWithUser()
            .then(result => {
                this.usersAvailability = result.map(user => ({
                    ...user,
                    Name: user.userFirstName,
                    Status: user.Status,
                    Format: user.Status == "At Lunch"? "slds-text-title_caps slds-theme_alert-texture slds-alert_warning slds-text-color_error":"slds-text-title_caps slds-text-color_success",
                    Icon: user.Status == "At Lunch"? "standard:first_non_empty":"standard:impact_outcome",
                    Id: '/' + user.userRecordId // Create a link to the user record
                }));
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
}
