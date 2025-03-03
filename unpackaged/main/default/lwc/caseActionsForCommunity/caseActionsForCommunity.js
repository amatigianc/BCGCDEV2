/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-console */
/* eslint-disable guard-for-in */
/* eslint-disable vars-on-top */
/* eslint-disable no-loop-func */
/* eslint-disable array-callback-return */
import { LightningElement, api, wire, track } from 'lwc';
import getCaseDetails from '@salesforce/apex/CaseController.getCaseDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import requestClosure from '@salesforce/apex/CaseController.requestClosure';
//import updateCC from '@salesforce/apex/CaseController.updateCC';
import updatePriority from '@salesforce/apex/CaseController.updatePriority';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Priority_FIELD from '@salesforce/schema/Case.Priority';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import requestClosureLabel from '@salesforce/label/c.Request_closure';
//import updateAdditionalCC from '@salesforce/label/c.Update_additional_CC';
//import updateCCrecipients from '@salesforce/label/c.Update_CC_recipients';
import priority from '@salesforce/label/c.Priority';
import updatePriorityLabel from '@salesforce/label/c.Update_priority';

export default class caseActionsForCommunity extends LightningElement {
    @api recordId;
    @track error;
    @track thisCase = {};
    //@track CCvalue;
    @track selectedOption;
    @track options;

    label = {
        requestClosureLabel,
        //updateAdditionalCC,
        //updateCCrecipients,
        priority,
        updatePriorityLabel
    }

    /*get additionalCC(){
        return this.thisCase.E2CP__AdditionalCC__c;
    }*/

    get selectedOption(){
        return this.selectedOption;
    }

    get options(){
        return this.options;
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    @wire(getCaseDetails, {caseID: '$recordId'})
    wiredCase(result) {
        if (result.data) {
            this.thisCase = result.data;
            this.selectedOption = this.thisCase.Priority;
            //this.CCvalue = this.thisCase.E2CP__AdditionalCC__c;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Priority_FIELD})
    wiredOptions(result){
        if(result.data){
            this.options = result.data.values;
        }
    }

    handleClosureClick(){
        requestClosure({caseID: this.recordId})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Closure requested',
                        variant: 'success',
                    })
                );
                window.location.reload();
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while requesting closure',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }

    /*handleCCChange(event){
        this.CCvalue = event.target.value;
    }*/

    /*handleUpdateCCClick(){
        updateCC({caseID: this.recordId, CCRec: this.CCvalue})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Additional CC updated',
                        variant: 'success',
                    })
                );
                window.location.reload();
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while updating Additional CC',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }*/

    handlePriorityChange(event){
        this.priority = event.detail.value;
    }

    handleUpdatePriorityClick(){
        updatePriority({caseID: this.recordId, priority: this.priority})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Priority updated',
                    variant: 'success',
                })
            );
            window.location.reload();
        })
        .catch(error => {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while updating Priority',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }
}