import { LightningElement, api, wire } from 'lwc';
import getCaseCommentsWithAttachments from '@salesforce/apex/CaseCommentsFiles.getCaseCommentsWithAttachments';

export default class CaseCommentsWithAttachments extends LightningElement {
    @api recordId; // This property is dynamically set via Experience Builder

    comments = [];
    error;

    @wire(getCaseCommentsWithAttachments, { caseId: '$recordId' })
    wiredComments({ error, data }) {
        if (data) {
            this.comments = data.map((comment) => ({
                id: comment.commentId,
                body: comment.commentBody,
                createdDate: comment.createdDate,
                attachments: comment.attachments.map((attachment) => ({
                    title: attachment.title,
                    downloadUrl: attachment.downloadUrl,
                })),
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.comments = [];
            console.log('Error: ' + error.message + '\n' + error.stack);
        }
    }
}