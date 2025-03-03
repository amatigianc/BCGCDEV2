/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-console */
/* eslint-disable guard-for-in */
/* eslint-disable vars-on-top */
/* eslint-disable no-loop-func */
/* eslint-disable array-callback-return */
import { LightningElement, api, wire, track } from 'lwc';
import getComments from '@salesforce/apex/CaseCommentController.getComments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import deleteAttachment from '@salesforce/apex/CaseCommentController.deleteAttachment';
import refresh from '@salesforce/label/c.Refresh';
import viewAttachment from '@salesforce/label/c.View_attachment';
import deleteAttachmentLabel from '@salesforce/label/c.Delete_attachment';

export default class BasicDatatable extends LightningElement {
    @api recordId;

    @track error;
    @track comments = [];
    @track attchID = '';

    label = {
        refresh,
        viewAttachment,
        deleteAttachmentLabel
    }

    @wire(getComments, {caseId: '$recordId'})
    comments;

    deleteAttachmentjs(event) {
        this.attchID = event.target.dataset.recordid;
        console.log('delete account: ' + this.attchID);
        deleteAttachment({attchID: this.attchID})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Attachment was deleted',
                        variant: 'success',
                    })
                );
                return refreshApex(this.comments);
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error While Deleting record',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

    /*renderedCallback(){
        this.handleClick();
    }*/

    handleClick(){
        console.log('Sí entró');
        return refreshApex(this.comments);
    }
}