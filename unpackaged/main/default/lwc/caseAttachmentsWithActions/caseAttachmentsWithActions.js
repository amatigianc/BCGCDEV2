/* eslint-disable consistent-return */
/* eslint-disable no-console */
/* eslint-disable guard-for-in */
/* eslint-disable vars-on-top */
/* eslint-disable no-loop-func */
/* eslint-disable array-callback-return */
import { LightningElement, api, wire, track } from 'lwc';
import getAttachments from '@salesforce/apex/CaseCommentController.getAttachments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import deleteAttachment from '@salesforce/apex/CaseCommentController.deleteAttachment';
import getFiles from '@salesforce/apex/CaseCommentController.getFiles';
import deleteFile from '@salesforce/apex/CaseCommentController.deleteFile';
import refresh from '@salesforce/label/c.Refresh';
import viewAttachment from '@salesforce/label/c.View_attachment';
import deleteAttachmentLabel from '@salesforce/label/c.Delete_attachment';
import uploadedBy from '@salesforce/label/c.Uploaded_by';
import attachmentName from '@salesforce/label/c.Attachment_name';

export default class caseAttachmentsWithActions extends LightningElement { 
    @api recordId;
    @track attchs = [];
    @track attchID;
    @track files = [];
    @track fileID;
    wasRenderedCallbackCalled = false;

    label = {
        refresh,
        viewAttachment,
        deleteAttachmentLabel,
        uploadedBy,
        attachmentName
    }
    
    @wire(getAttachments, {caseId: '$recordId'})
    attchs;

    renderedCallback(){
        if(!this.wasRenderedCallbackCalled){
            getFiles({caseId: this.recordId})
                .then(result => {
                    if (result) {
                        result.map((x) => {
                            this.files.push({ DistributionPublicUrl: x.DistributionPublicUrl, Id: x.Id, CreatedBy : {Name: x.CreatedBy.Name}, Name: x.Name, LastModifiedDate: x.LastModifiedDate});
                        });
                    }
                })
                .catch(error => {
                    this.files = error;
                });
            this.wasRenderedCallbackCalled = true;
        }
    }

    deleteAttachmentjs(event) {
        this.attchID = event.target.dataset.recordid;
        deleteAttachment({attchID: this.attchID})
        .then(result => {
            if(result){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Attachment was deleted',
                        variant: 'success',
                    })
                );
                return refreshApex(this.attchs);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Attachments from agents cannot be deleted',
                    variant: 'error',
                }),
            );
        });
    }

    deleteFilejs(event) {
        this.fileID = event.target.dataset.recordid;
        deleteFile({fileID: this.fileID})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Attachment was deleted',
                    variant: 'success',
                })
            );
            return refreshApex(this.files);
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error While Deleting record',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    }

    handleClick(){
        return refreshApex(this.attchs);
    }
}