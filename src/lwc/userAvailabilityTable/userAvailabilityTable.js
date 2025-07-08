/**
 * Created by adpel on 23/06/2025.
 */

import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/tableController.getAccounts'
import getAvailabilityWithUser from '@salesforce/apex/AvailabilityService.getAvailabilityWithUser'
import {loadStyle} from 'lightning/platformResourceLoader'
import COLORS from '@salesforce/resourceUrl/Colors'
const COLUMNS = [
    {label:'Name', fieldName:'Name',  cellAttributes:{
        class:{fieldName:'accountColor'}
    }},
    {label:'Status', fieldName:'Status', cellAttributes:{
        class:{fieldName:'amountColor'},
        iconName:{fieldName:'iconName'}, iconPosition:'right'
    }},
    {label:'Industry', fieldName:'Industry', type:'text', cellAttributes:{
        class:{fieldName:'industryColor'}
    }},
    {label:'Phone', fieldName:'Phone', type:'phone'},
]
export default class DatatableDemo extends LightningElement {
    tableData
    columns = COLUMNS
    isCssLoaded = false

    @wire(getAvailabilityWithUser)
    usersHandler({data, error}){
        if(data){

            this.tableData = data.map(item=>{
                let amountColor = item.Status == "At Lunch" ? "slds-text-color_error":"slds-text-color_success"
                let iconName = item.Status == "At Lunch" ? "utility:down":"utility:up"
                return {...item,
                    "amountColor":amountColor,
                    "iconName":iconName,
                    "industryColor":"slds-icon-custom-custom12 slds-text-color_default",
                    "accountColor":"datatable-orange"
                }
            })
            console.log(this.tableData)
        }
        if(error){
            console.error(error)
        }
    }
//    @wire(getAccounts)
//    accountsHandler({data, error}){
//        if(data){
//
//            this.tableData = data.map(item=>{
//                let amountColor = item.AnnualRevenue <500000 ? "slds-text-color_error":"slds-text-color_success"
//                let iconName = item.AnnualRevenue <500000 ? "utility:down":"utility:up"
//                return {...item,
//                    "amountColor":amountColor,
//                    "iconName":iconName,
//                    "industryColor":"slds-icon-custom-custom12 slds-text-color_default",
//                    "accountColor":"datatable-orange"
//                }
//            })
//            console.log(this.tableData)
//        }
//        if(error){
//            console.error(error)
//        }
//    }

    renderedCallback(){
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, COLORS).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{
            console.error("Error in loading the colors")
        })
    }

}