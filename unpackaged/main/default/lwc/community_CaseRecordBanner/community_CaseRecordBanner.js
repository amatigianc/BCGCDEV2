import { LightningElement, api, wire } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";

import CASE_SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import CASE_NUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";
import CASE_SUPPORT_PACKAGE_FIELD from "@salesforce/schema/Case.Support_Package_txt__c";
import CASE_STATUS from "@salesforce/schema/Case.Status";
import { ShowToastEvent } from "lightning/platformShowToastEvent"; // Import toast event for feedback

const FIELDS = [
  CASE_SUBJECT_FIELD,
  CASE_NUMBER_FIELD,
  CASE_SUPPORT_PACKAGE_FIELD,
  CASE_STATUS
];

export default class CommunityCaseRecordBanner extends LightningElement {
  @api recordId; // The recordId passed into the component
  caseRecord = {}; // Object to store the case record data

  // Wire adapter to fetch the case record using the recordId
  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.caseRecord = data; // Store the case record data
      console.log("Case Data:", this.caseRecord); // Log the case record data (for debugging purposes)
      console.log(
        "Fetched Case Data:",
        JSON.stringify(this.caseRecord, null, 2)
      );
    } else if (error) {
      console.error("Error fetching case record:", error); // Log any errors that occur
    }
  }

  // Getter for Case Subject
  get caseSubject() {
    console.log("Getting caseSubject:", this.caseRecord);
    return this.caseRecord?.fields?.Subject?.value || "N/A";
  }

  get caseNumber() {
    console.log("Getting caseNumber:", this.caseRecord);
    return this.caseRecord?.fields?.CaseNumber?.value || "N/A";
  }

  get caseSupportPackage() {
    return (
      this.caseRecord?.fields?.Support_Package_txt__c?.value || "Not selected"
    );
  }
  get isClosed() {
    return this.caseRecord?.fields?.Status?.value === "Closed";
  }

  handleClick() {
    console.log("Clicked!");
    const fields = {};
    fields["Id"] = this.recordId;
    fields["Status"] = "Closed";

    const recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        console.log("Case Close!");
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Case has been closed successfully.",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.log("ERROR COSE " + error.body.message);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }
}