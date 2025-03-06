import { LightningElement, api, wire, track} from 'lwc';
import { getRecord} from "lightning/uiRecordApi";
import createPortalComment from "@salesforce/apex/PortalCaseCommentWrapper.createPortalComment";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_NUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";

import CASE_RECORD_ID from "@salesforce/schema/Case.Id";

const FIELDS = [CASE_RECORD_ID, CASE_NUMBER_FIELD];


export default class CaseCommentWithAttachment extends LightningElement {
    @api recordId;
    @track commentText;
    caseData = {};

    commentText = "Write your commment here";

@wire(getRecord, { recordId: '$recordId', fields: FIELDS }) 
wiredrecord({error,data}){
    if (data) {
        this.caseData=data;
        console.log(
            "Fetched Case Data:",
            JSON.stringify(this.caseData, null, 2)
          );
    } else if (error) {
        console.error("Error fetching case record:", error); // Log any errors that occur
      }
};

get commentTitle() {
    this.caseCommentTitle += this.caseData?.fields?.caseNumber?.value;
    return this.caseCommentTitle|| "N/A";
}

get caseTheCaseNumber(){   
    console.log('CaseCommentWithAttachment --> get CaseNumber: ' + this.caseData);
    return this.caseRecord?.fields?.caseNumber?.value || 'N/A';
}

get acceptedFormats() {
    return ['.pdf', '.png','.jpg', '.doc', '.docx', '.txt', '.jpeg','.js'];
}

handleCommentChange (event) {
    this.commentText = event.target.value;
    console.log(" handleCommentChange" + event.target.value);
}

handleSubmit(event){
    console.log('Start handleSubmit ' + JSON.stringify(event.detail, null, 2));
    console.log('this commmenttext: ' + this.commentText);
    createPortalComment({caseId: this.recordId, bodyComment: this.commentText})
    .then(result => {
        console.log('handleSubmit result: ' + JSON.stringify(result));
        this.commentText = '';
        this.showToast('Success', 'Case Comment Added', 'success');
    }).catch(error => {
        console.log('handleSubmit error: ' + JSON.stringify(error));
        this.showToast('Error','Error adding case comment', 'error');
     
    });

    
}

handleUploadFinished(event) {
    console.log ('Start handleUploadFinished ' + event.details);
    const d = new Date();
    
    console.log('uploadedFiles: ' + JSON.stringify(event.detail, null, 2));
    this.commentText =  "["+d.toLocaleDateString()+ " " + d.toLocaleTimeString()+" Filename: "+ event.detail.files[0].name  + "] \n\n" + this.commentText;
    console.log ('END handleUploadFinished ');
}

showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
}


}