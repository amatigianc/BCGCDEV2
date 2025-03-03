import { LightningElement, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import termsAndConditionsUrl from '@salesforce/label/c.TBS_Terms_and_Conditions';
import privacyPolicyUrl from '@salesforce/label/c.TBS_Privacy_Policy';
import successUrl from '@salesforce/label/c.SuccessPageURL';

import registerUser from '@salesforce/apex/CommunitySignUpController.registerUser';
import doesUserExist from '@salesforce/apex/CommunitySignUpController.doesUserExist';
import doesNicknameExist from '@salesforce/apex/CommunitySignUpController.doesUserNicknameExist';
import getFormData from '@salesforce/apex/CommunitySignUpController.getFormData';

import { roles, relationships, countries, getStateValues } from './res/picklistValues.js';

export default class CommunitySignUp extends LightningElement {
    @track newUser ;

    termsUrl = termsAndConditionsUrl;
    privacyUrl = privacyPolicyUrl;
    successPage = successUrl;

    confirmPassword;
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

    showMessage = false;
    submitSelected = false;

    connectedCallback() {
        getFormData()
            .then(result => {
                this.loading = false;
                this.newUser = result.regData;
            })
            .catch(error => {
                this.loading = false;
                this.updateErrorMessage(error);
            })
    }

    get showSpinner() {
        return this.loading || this.registering;
    }

    get showStateField() {
        return this.stateOptions != undefined && this.stateOptions.length > 0;
    }

    isInputValid() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true); 

        return isInputsCorrect;
    }

    handleFirstNameChange(event){
        this.newUser.firstName = event.detail.value;
    }
    
    handleLastNameChange(event){
        this.newUser.lastName = event.detail.value;
    }

    handleEmailChange(event){
        this.newUser.email = event.detail.value;
        this.newUser.username = this.newUser.email;
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

    handleTimezoneChange(event){
        this.newUser.userTimeZone = event.detail.value;
    }

    handlePasswordChange(event){
        this.newUser.password = event.detail.value;
    }

    handleConfirmChange(event){
        this.confirmPassword = event.detail.value;
    }

    handleAgreeToTandCChange(event){
        var submitButton = this.template.querySelector('[data-id="submitBtn"]');
        this.approvesTC = event.detail.checked;
        this.newUser.agreedToTandC = new Date();
        
        //disable the submit button unless we accept T&Cs
        if(this.approvesTC) {
            submitButton.removeAttribute('disabled');
        } else {
            submitButton.setAttribute('disabled', '');
        }
    }

    handleSignUpClick(event){
        this.submitSelected = true;
        this.errorMessge = null;
        this.registering = true;
        if(!this.isInputValid()) {
            this.registering = false;
            this.submitSelected  = false;
            this.updateErrorMessage('Please check form fields');        
        }
        else{
            this.checkUserExists();
        }

    }

    checkUserExists(){
        doesUserExist({username: this.newUser.username})
            .then(result => {
                if(result){
                    this.updateErrorMessage('User with this email address already exists');
                    this.registering = false;
                    this.showMessage = true;
                    this.submitSelected  = false;
                }
                else{
                    this.checkNicknameExists();
                }
            })
            .catch(error => {
                this.updateErrorMessage(error);
                this.registering = false;
            })
    }

    checkNicknameExists(){
        doesNicknameExist({nickname: this.newUser.nickname})
            .then(result => {
                if(result){
                    this.updateErrorMessage('User with this nickname already exists');
                    this.registering = false;
                    this.showMessage = true;
                    this.submitSelected  = false;
                }
                else{
                    this.registerNewUser();
                }
            })
            .catch(error => {
                this.updateErrorMessage(error);
                this.registering = false;
            })
    }

    registerNewUser(){
        registerUser({regData: this.newUser})
            .then(result => {
               
                if(result) {
                    this.submitSelected  = false;
                    this.successMessage = 'Account Created, redirecting...';
                    this.showToast('Success!', 'Account Created, redirecting...', 'success');

                    let urlVar = window.location.origin;
                    let urlArr = urlVar.split("/s/");
                    urlVar = urlArr[0]+ this.successPage;
                   
                    window.location.href = urlVar;
                }
            })
            .catch(error => {
                console.log(error);
                this.registering = false;
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