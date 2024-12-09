import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import addEvents from "@salesforce/apex/VisitPlannerController.addEvents";
import sendEmails from "@salesforce/apex/VisitPlannerController.sendEmails";

import { getRecords } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";


import visitPlanerCalendarEntriesOnly from "@salesforce/label/c.VisitPlanerCalendarEntriesOnly";//Nur Kalendereinträge //Calendar entries only
import visitPlanerCalendarEntriesAndEmail from "@salesforce/label/c.VisitPlanerCalendarEntriesAndEmail";//Kalendereinträge + E-Mail // Calendar entries + email
import visitPlanerHeader from "@salesforce/label/c.VisitPlanerHeader"; // Besuche planen // Plan visits
import visitPlanerMainHint from "@salesforce/label/c.VisitPlanerMainHint"; //Sie haben [x] zur Planung ausgewählt. Bitte hier die Planungsdetails auswahlen //  You have selected [x] for planning. Please select the planning details here
import visitPlanerStartDate from "@salesforce/label/c.VisitPlanerStartDate"; // An welchem Tag sollen die Besuche geplant werden? //  On which day should the visits be planned?
import visitPlanerOptionChoice from "@salesforce/label/c.VisitPlanerOptionChoice"; // Planungsauswahl //Planning selection
import visitPlanerCloseButton from "@salesforce/label/c.VisitPlanerCloseButton"; // Abbrechen // Cancel
import visitPlanerAcceptButton from "@salesforce/label/c.VisitPlanerAcceptButton"; // Jetzt planen // Plan now

export default class VisitPlanner extends LightningElement {

    @api accIds;
    wiredAccs;

    isOpenModal = true;
    disableSave = false;
    isLoading = true;
    accsString= [];

    startDateHintVisible = false;
    optionsHintVisible = false;

    startDate = new Date().toISOString().substring(0, 10);
    today = this.startDate;
    optionChoice = 'calendarEntriesOnly'; 

    haderLabel = visitPlanerHeader;
    mainHintLabel = visitPlanerMainHint;
    startDateLabel = visitPlanerStartDate;
    optionChoiceLabel = visitPlanerOptionChoice;
    closeButtonLabel = visitPlanerCloseButton;
    acceptButtonLabel = visitPlanerAcceptButton;
    calendarEntriesOnly = visitPlanerCalendarEntriesOnly;
    calendarEntriesAndEmail = visitPlanerCalendarEntriesAndEmail;
    

    get options() {
        return [
        { label: this.calendarEntriesOnly, value: 'calendarEntriesOnly'},
        //{ label: this.sendEmailOnlyLabel, value: 'sendEmailOnly' },
        { label: this.calendarEntriesAndEmail, value: 'calendarEntriesAndEmail'},
        ];
    }

    @wire(getRecords, {records: "$wiredAccs"})
      accsDataMeth({error, data}) {
        if (data) {
            this.accsString = '';
            data.results.forEach(record => {
                this.accsString += record.result.fields.Name.value + ', ';
            });
            this.mainHintLabel = this.mainHintLabel.replace('[x]', this.accsString.substring(0, this.accsString.length - 2));                
        } else if (error) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}));   
        }
    }
    
    connectedCallback() {     
        this.initLoad();
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
        this.operateInput(this.template.querySelector(`[data-id="${event.target.name}-hint"]`));
    }

    handleCloseButton(event){
        window.history.back();
    }

    async handleAcceptButton(event){
        
        if(this.errorsExist())      
            return;   

        this.toggleSpinner(true);

        switch (this.optionChoice) {
            case 'calendarEntriesOnly':
                try{
                    await addEvents({startDateTime: this.startDate, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({title: 'Events were added', variant: 'success'}));
                    console.log('Events were added')}
                catch(error){
                    console.log(error.body.message);
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))}
                break;

            case 'calendarEntriesAndEmail':

                let createdEventIds = [];

                try{
                    createdEventIds = await addEvents({startDateTime: this.startDate, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({title: 'Events were added', variant: 'success'}));
                    console.log('Events were added')}
                catch(error){
                    console.log(error.message);
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))
                    this.disableSave = true;
                    this.toggleSpinner(false);
                    return;
                }    
                
                try{
                    sendEmails({eventIds: createdEventIds, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({title: 'Email were sent', variant: 'success'}));
                    console.log('Email were sent')}
                catch(error){
                    console.log(error.body.message);
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))}   

                break;

            default:
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: 'Firstly fill all needed fields!'}));
        }

        this.disableSave = true;
        this.toggleSpinner(false); 
    }

    async initLoad(){
        this.toggleSpinner(true);
        this.clearData();
        this.operateFirstLoad();
        this.toggleSpinner(false);
    }

    operateFirstLoad(){
        this.wiredAccs = [{recordIds: this.accIds, fields: [ACCOUNT_NAME_FIELD]}];
        this.isOpenModal = true;       
    }

    clearData(){
        this.isOpenModal = false;
    }

    toggleSpinner(isLoading){
        this.isLoading = isLoading;
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
}