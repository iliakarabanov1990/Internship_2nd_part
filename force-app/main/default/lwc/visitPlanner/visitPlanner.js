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
import visitPlanerMainHintEmpty from "@salesforce/label/c.VisitPlanerMainHintEmpty"; // Zuerst müssen Sie Konten auswählen // First of all you need to choose Accounts
import successfullyCreated from "@salesforce/label/c.successfullyCreated"; // Die Termine für die ausgewählten {0} Kunden wurden erfolgreich erstellt. Gehen Sie {1} zu ihrem Kalender // Appointments for the selected {0} customers have been created successfully. Go to {1} their calendar
import visitPlanerStartDate from "@salesforce/label/c.VisitPlanerStartDate"; // An welchem Tag sollen die Besuche geplant werden? //  On which day should the visits be planned?
import visitPlanerOptionChoice from "@salesforce/label/c.VisitPlanerOptionChoice"; // Planungsauswahl //Planning selection
import visitPlanerCloseButton from "@salesforce/label/c.VisitPlanerCloseButton"; // Abbrechen // Cancel
import visitPlanerAcceptButton from "@salesforce/label/c.VisitPlanerAcceptButton"; // Jetzt planen // Plan now


export default class VisitPlanner extends LightningElement {

    @api accIds;
    wiredAccs;

    today = this.startDate;
    isOpenModal = true;
    disableSave = true;
    isLoading = true;
    accsString = '';

    startDate = new Date().toISOString().substring(0, 10);  
    optionChoice = 'calendarEntriesOnly'; 

    hints = ['startDateHint', 'optionChoiceHint'];
    startDateHint = '';
    optionChoiceHint = '';


    haderLabel = visitPlanerHeader;
    mainHintLabel = visitPlanerMainHintEmpty;
    startDateLabel = visitPlanerStartDate;
    optionChoiceLabel = visitPlanerOptionChoice;
    closeButtonLabel = visitPlanerCloseButton;
    acceptButtonLabel = visitPlanerAcceptButton;
    calendarEntriesOnly = visitPlanerCalendarEntriesOnly;
    calendarEntriesAndEmail = visitPlanerCalendarEntriesAndEmail;
    successfullyCreatedLabel = successfullyCreated;
    

    get options() {return [
        { label: this.calendarEntriesOnly, value: 'calendarEntriesOnly'},
        { label: this.calendarEntriesAndEmail, value: 'calendarEntriesAndEmail'}];}

    @wire(getRecords, {records: "$wiredAccs"})
      accsDataMeth({error, data}){
        this.accsString = '';
        if(data) {           
            data.results.forEach(record => { this.accsString += record.result.fields.Name.value + ', '});
            if(this.accsString !== '') { 
                this.mainHintLabel = visitPlanerMainHint.replace('[x]', this.accsString.substring(0, this.accsString.length - 2));
                this.disableSave = false;
            }              
        } 
        else if(error) { this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message})) }
    }
    
    connectedCallback() {     

        this.toggleSpinner(true);

        this.wiredAccs = [{recordIds: this.accIds, fields: [ACCOUNT_NAME_FIELD]}];
        this.isOpenModal = true;      
        
        this.hints.forEach(hint => { this[hint] = 'slds-form-element__help slds-text-color_destructive slds-text-body_small slds-hidden' }); 

        this.toggleSpinner(false);
    }

    handleChange(event){
        const elName = event.target.name;
        const elNameHint = event.target.name + 'Hint';
        this[elName] = event.target.value.trim();
        this[elNameHint] = this[elNameHint].replace('slds-hidden', '');
        this[elNameHint] += this[elName].trim() ? 'slds-hidden' : '';
    }

    handleCloseButton(event){
        window.history.back();
    }

    async handleAcceptButton(event){
        
        if(this.errorsExist()) { return }     

        if(this.accIds.length === 0) {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: 'There are not chosen accounts!'}));
            return;
        }                 

        this.toggleSpinner(true);

        switch (this.optionChoice) {
            case 'calendarEntriesOnly':
                try{
                    await addEvents({startDateTime: this.startDate, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.successfullyCreatedLabel,
                        variant: 'success',
                        messageData: [this.accsString, {url: '/lightning/o/Event/home', label: 'hier'}]
                    }))}
                catch(error){
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))}
                break;

            case 'calendarEntriesAndEmail':

                let createdEventIds = [];

                try{
                    createdEventIds = await addEvents({startDateTime: this.startDate, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.successfullyCreatedLabel,
                        variant: 'success',
                        messageData: [this.accsString, {url: '/lightning/o/Event/home', label: 'hier'}]
                    }))}
                catch(error){
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))
                    this.toggleSpinner(false);
                    this.disableSave = true;
                    return;
                }    
                
                try{
                    sendEmails({eventIds: createdEventIds, accIds: this.accIds});
                    this.dispatchEvent(new ShowToastEvent({title: 'Email were sent', variant: 'success'}))}
                catch(error){
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.body.message}))}   

                break;

            default:
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: 'Firstly fill all needed fields!'}));
        }

        this.disableSave = true;
        this.toggleSpinner(false); 
    }

    toggleSpinner(isLoading){
        this.isLoading = isLoading;
    }

    errorsExist(){
        let errorExist = false;
        this.hints.forEach(hint => { if(!this[hint].includes('slds-hidden')) { errorExist = true} });

        return errorExist;
    }
}