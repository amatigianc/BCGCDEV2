import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import termsAndConditionsUrl from '@salesforce/label/c.TBS_Terms_and_Conditions';
import privacyPolicyUrl from '@salesforce/label/c.TBS_Privacy_Policy';

import doesUserAcceptTandC from '@salesforce/apex/CommunitySignUpController.doesUserAcceptTandC';
import getFormData from '@salesforce/apex/CommunitySignUpController.getFormData';
import getCurrentUserInfo from '@salesforce/apex/CommunitySignUpController.getCurrentUserInfo';
import doesNicknameExist from '@salesforce/apex/CommunitySignUpController.doesUserNicknameExist';
import updateExistingContactAndUser from '@salesforce/apex/CommunitySignUpController.updateExistingContactAndUser';

import { roles, relationships, countries, getStateValues } from './res/picklistValues.js';

export default class TheBrightSpotExistingUserRegistration extends LightningElement {
    @track isModalOpen = false;
    @track newUser;

    @track nickname = '';
    @track company = '';
    @track role = '';

    existingNickname = '';


    termsUrl = termsAndConditionsUrl;
    privacyUrl = privacyPolicyUrl;

    approvesTC = false; 
 
    registering = false;
    loading = true;
    errorMessge; 
    successMessage; 

    //hard coded in seperate file to not require permissions based on SFDC objects
    roleOptions = roles;
    relationshipOptions = relationships;
    countryOptions = countries;
    stateOptions;

    submitSelected = false;

    get showSpinner() {
        return this.loading || this.registering;
    }

    get showStateField() {
        return this.stateOptions != undefined && this.stateOptions.length > 0;
    }

    connectedCallback() {
        doesUserAcceptTandC().then(result => {
            if(result == false) {
                getCurrentUserInfo().then(result => {
                    console.log(result);
                    if(result !== undefined) {
                        this.nickname = result.CommunityNickname;
                        this.existingNickname = result.CommunityNickname;
                        this.company = result.CompanyName;
                        this.role = result.My_Role__c;
                    }
                    this.isModalOpen = true;
                    getFormData()
                    .then(result => {
                        this.loading = false;
                        this.newUser = result.regData;
                        this.newUser.nickname = this.nickname;
                        this.newUser.myCompany = this.company;
                        this.newUser.myRole = this.role;
                    })
                    .catch(error => {
                        this.loading = false;
                        this.updateErrorMessage(error);
                    })
                });
            }
        });
    }

    isInputValid() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true); 

        return isInputsCorrect;
    }

    handleNicknameChange(event){
        this.newUser.nickname = event.detail.value;
    }

    handleMyCompanyChange(event){
        this.newUser.myCompany = event.detail.value;
    }

    handleMyRoleChange(event){
        this.newUser.myRole = event.detail.value;
    }

    handleCountryChange(event){
        this.newUser.mailingCountry = event.detail.value;
        this.stateOptions = getStateValues(event.detail.value);
        if(!this.showStateField()) {
            this.newUser.mailingState = '';
        }
    }

    handleStateChange(event){
        this.newUser.mailingState = event.detail.value;
    }

    handleRelationshipChange(event){
        this.newUser.relationshipToBrightcove = event.detail.value;
    }

    handleAgreeToTandCChange(event){
        var submitButton = this.template.querySelector('[data-id="submitBtnExisting"]');
        this.approvesTC = event.detail.checked;
        this.newUser.agreedToTandC = new Date();
        
        //disable the submit button unless we accept T&Cs
        if(this.approvesTC) {
            submitButton.removeAttribute('disabled');
        } else {
            submitButton.setAttribute('disabled', '');
        }
    }

    handleSubmitDetails(event){
        this.submitSelected = true;
        if(!this.isInputValid()) {
            this.submitSelected = false;
            this.updateErrorMessage('Please check form fields');        
        }
        else{
            this.checkNicknameExists();
        }

    }

    checkNicknameExists(){
        if(this.existingNickname != '' && this.existingNickname == this.newUser.nickname) {
            //skip checking for an existing nickname and try to update the user
            this.registerExistingUser();
        } else {
            console.log('checking nickname');
            doesNicknameExist({nickname: this.newUser.nickname})
            .then(result => {
                if(result){
                    this.submitSelected = false;
                    this.updateErrorMessage('User with this nickname already exists');
                }
                else{
                    this.registerExistingUser();
                }
            })
            .catch(error => {
                this.updateErrorMessage(error);
            })
        }
        
    }

    registerExistingUser(){
        updateExistingContactAndUser({regData: this.newUser})
            .then(result => {
                if(result == 0) {
                    this.successMessage = 'Information Updated, redirecting...';
                    this.showToast('Success!', 'Information Updated, redirecting...', 'success');
                   
                    window.location.reload();
                }
            })
            .catch(error => {
                console.log(error);
                this.submitSelected = false;
                this.updateErrorMessage(error);
            })
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });

        this.dispatchEvent(evt);
    }

    updateErrorMessage(error){
        if(!error) return;

        if(typeof error === 'string'){
            this.errorMessge = error;
        }
        else if(error.body && !Array.isArray(error.body.message)){
            this.errorMessge = error.body.message;
        }
        else if(error.body && Array.isArray(error.body.message)){
            this.errorMessge = '';
            error.body.message.forEach(element => {
                this.errorMessge = this.errorMessge + '<p>' + element.message + '</p>';
            });
        }
        else{
            console.log(error);
            this.errorMessge = 'An error occured during registration.';
        }

        this.showToast('Error', this.errorMessge, 'error');
    }
}