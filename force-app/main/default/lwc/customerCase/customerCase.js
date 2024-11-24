import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContact from '@salesforce/apex/CustomerCaseController.getContact';
import createContact from '@salesforce/apex/CustomerCaseController.createContact';
import createCase from '@salesforce/apex/CustomerCaseController.createCase';

export default class InputGuest extends LightningElement {

    contactId = null;
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    message = '';

    firstNameHintVisible = false;
    lastNameHintVisible = false;
    emailHintVisible = false;
    messageHintVisible = false;
    disableSave = false;


    async sendData(){

        let contacts = [];

        try {
            contacts = await getContact({firstName: this.firstName, lastName: this.lastName, email: this.email})} 
        catch(error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: JSON.stringify(error)})); return false}
        
        if(contacts.length === 0){
            try {     
                this.contactId = await createContact({firstName: this.firstName, lastName: this.lastName, email: this.email, phone: this.phone});}  
            catch(error) {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message})); return false}}
        else   
            this.contactId = contacts[0].Id;

        try {        
            await createCase({subject: this.message, suppliedPhone: this.phone, suppliedEmail: this.email, contactId: this.contactId});
            this.dispatchEvent(new ShowToastEvent({title: 'Message Sent', variant: 'success'})) 
            return false}
        catch (error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message}))}

        return true;
    }

    errorsExist(){

        let errorExist = false;
        const hints = this.template.querySelectorAll('[data-name="error-hint"]');
        hints.forEach(el => {
            const errEx = this.operateInput(el);
            if(errEx) errorExist = true;
        });

        return errorExist;
    }
    
    operateInput(el){

        let errorExist = false;

        const hintName = el.getAttribute('data-id').replace('-hint', '');
        const elName = el.getAttribute('data-id').replace('-hint', '');
        const hintBox = this.template.querySelector(`[data-id="${hintName}-hint-box"]`); 
        if(this[elName].trim()){  
            el.classList.add('slds-hidden'); 
            el.classList.remove('slds-show');              
            hintBox.classList.remove("slds-has-error");
        }
        else{
            el.classList.remove('slds-hidden'); 
            el.classList.add('slds-show');
            hintBox.classList.add("slds-has-error");
            errorExist = true;
        }

         return errorExist;
    }

    async handleSave(event) {     

        if(!this.errorsExist()){
            this.disableSave = true;
            const isSent = await this.sendData();      
            this.disableSave = isSent;
        }      
    }
 
    onChangeFirstNameHandler(event) {
        this.firstName = event.target.value;

        if(this.firstName.trim())
            this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'));
    }

    onChangeLastNameHandler(event) {
        this.lastName = event.target.value;

        if(this.firstName.trim())
            this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'));
    }
   
    onChangeEmailHandler(event) {
        this.email = event.target.value;

        if(this.firstName.trim())
            this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'));
    }

    onChangePhoneHandler(event) {
        this.phone = event.target.value;
    }

    onChangeMessageHandler(event) {
        this.message = event.target.value;

        if(this.firstName.trim())
            this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'));
    }

    async sendDataOld(){

        let contacts = [];
         /*const contactFields = {};
        contactFields[FIRST_NAME_FIELD.fieldApiName] = this.firstName;
        contactFields[LAST_NAME_FIELD.fieldApiName] = this.lastName;
        contactFields[EMAIL_FIELD.fieldApiName] = this.email;
        contactFields[PHONE_FIELD.fieldApiName] = this.phone;
        const contactRecordInput = {apiName: CONTACT_OBJECT.objectApiName, fields: contactFields};*/

        try {
            contacts = await getContact({firstName: this.firstName, lastName: this.lastName, email: this.email})
        } 
        catch(error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message})); return}
        
        if(contacts.length === 0){
            try {     
                //const cont = await createRecord(contactRecordInput);
                //this.contactId = cont.id;
                this.contactId = await createContact({firstName: this.firstName, lastName: this.lastName, email: this.email, phone: this.phone});
            }  
            catch(error) {
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message})); return}
            }
        else   
            this.contactId = contacts[0].Id;
 

        /*const caseFields = {};
        caseFields[STATUS_FIELD.fieldApiName] = 'New';
        caseFields[ORIGIN_FIELD.fieldApiName] = 'Web';
        caseFields[SUBJECT_FIELD.fieldApiName] = this.message;
        caseFields[SUPPLIED_PHONE_FIELD.fieldApiName] = this.phone;
        caseFields[SUPPLIED_EMAIL_FIELD.fieldApiName] = this.email;
        caseFields[CONTACT_FIELD.fieldApiName] = this.contactId;
        const caseRecordInput = {apiName: CASE_OBJECT.objectApiName, fields: caseFields};*/

        try {        
            //await createRecord(caseRecordInput);
            await createCase({subject: this.message, suppliedPhone: this.phone, suppliedEmail: this.email, contactId: this.contactId});
            this.dispatchEvent(new ShowToastEvent({title: 'Message Sent', variant: 'success'}))} 
        catch (error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message}))}
    }
}