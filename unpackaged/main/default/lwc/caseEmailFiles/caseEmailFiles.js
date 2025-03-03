import { LightningElement, api, wire } from 'lwc';
import getAttachmentsFromCaseEmails from '@salesforce/apex/CaseEmailFiles.getAttachmentsFromCaseEmails';

export default class CaseEmailAttachments extends LightningElement {
    @api recordId; // The case record ID passed in from the page

    attachments = [];
    error;

    @wire(getAttachmentsFromCaseEmails, { caseId: '$recordId' })
    wiredAttachments({ error, data }) {
        if (data) {
            this.attachments = data.map((attachment) => ({
                title: attachment.title,
                downloadUrl: attachment.downloadUrl
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.attachments = [];
        }
    }
}