import { LightningElement, api, wire } from 'lwc';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addEvents from "@salesforce/apex/VisitPlannerController.addEvents";
import sendEmails from "@salesforce/apex/VisitPlannerController.sendEmails";

import { getRecords, getFieldValue } from 'lightning/uiRecordApi';

import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";


import visitPlanerCalendarEntriesOnly from "@salesforce/label/c.VisitPlanerCalendarEntriesOnly";//Nur Kalendereinträge //Calendar entries only
import visitPlanerCalendarEntriesAndEmail from "@salesforce/label/c.VisitPlanerCalendarEntriesAndEmail";//Kalendereinträge + E-Mail // Calendar entries + email
import visitPlanerHeader from "@salesforce/label/c.VisitPlanerHeader"; // Besuche planen // Plan visits
import visitPlanerMainHint from "@salesforce/label/c.VisitPlanerMainHint"; //Sie haben [x] zur Planung ausgewählt. Bitte hier die Planungsdetails auswahlen //  You have selected [x] for planning. Please select the planning details here
import visitPlanerStartDate from "@salesforce/label/c.VisitPlanerStartDate"; // An welchem Tag sollen die Besuche geplant werden? //  On which day should the visits be planned?
import visitPlanerOptionChoice from "@salesforce/label/c.VisitPlanerOptionChoice"; // Planungsauswahl //Planning selection
import visitPlanerCloseButton from "@salesforce/label/c.VisitPlanerCloseButton"; // Abbrechen // Cancel
import visitPlanerAcceptButton from "@salesforce/label/c.VisitPlanerAcceptButton"; // Jetzt planen // Plan now




//учесть таймзону https://salesforce.stackexchange.com/questions/284591/what-is-the-correct-approach-to-create-an-event-in-apex-for-another-user-with-th

export default class VisitPlanner extends NavigationMixin(LightningElement) {

    @api accIds;

    wiredAccs;

    isOpenModal = true;
    isLoading = true;
    accsString= [];


    startDateHintVisible = false;
    optionsHintVisible = false;

    startDate = new Date().toISOString();
    option = 'calendarEntriesOnly';


    haderLabel = visitPlanerHeader;
    mainHintLabel = visitPlanerMainHint;
    calendarEntriesOnly = visitPlanerCalendarEntriesOnly;
    calendarEntriesAndEmail = visitPlanerCalendarEntriesAndEmail;
    startDateLabel = visitPlanerStartDate;
    optionChoiceLabel = visitPlanerOptionChoice;
    closeButtonLabel = visitPlanerCloseButton;
    acceptButtonLabel = visitPlanerAcceptButton;
    optionChoiceValue = 'calendarEntriesOnly';
    

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

          console.log("error: ", error);
        }
    }
    
    connectedCallback() {
        
        this.initLoad();
    }

    /*get accs(){
        console.log('test-strart');
        console.dir(JSON.stringify(this.accIds));
        console.log('test-strart');
        return this.accIds;
        
    }*/

    handleStartDateChange(event){
        this.startDate = event.target.value;
        this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'), );
    }

    handleChangeOptionChoice(event){
        this.option = event.target.value;
        this.operateInput(this.template.querySelector('[data-id="firstName-hint"]'), );
    }

    handleCloseButton(event){

        //alert('cancel');

        window.history.back();
        /*setTimeout(
			function() {
				window.history.back();
			},
			1000
		);*/

       // this.navigateToURL('standard__recordPage', {'recordId': this.accIds[0], actionName: "view"}); 

        /*this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
              objectApiName: "Account",
              actionName: "list",
            },
            state: {
              filterName: "Recent", 
            },
          });   */
    }

    navigateToURL(type, attributes, state = {}) {   
        this[NavigationMixin.Navigate]({
            type,
            attributes,
            state,
        });
    }   

    async handleAcceptButton(event){
        this.toggleSpinner(true);
        if(this.errorsExist())      
            return;   

        switch (expr) {
            case 'calendarEntriesOnly':
                addEvents({startDateTime: this.startDate, accIds: this.accIds, isSendEmails: true})
                .then(s=>console.log(s))
                .catch(e=>console.log(e.getMessage()));
                break;
            case 'calendarEntriesAndEmail':

                const eventsFromEvents = [];
                try{
                    accsFromEvents = await addEvents({startDateTime: this.startDate, accIds: this.accIds, isSendEmails: true});}
                catch(error){
                    this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message}));   
                    return;}     
                
                sendEmails({eventIds: eventsFromEvents, accIds: this.accIds});                   
                break;
            default:
                this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: 'Firstly fill all needed fields!'}));
        }

        this.toggleSpinner(false); 
    }

    async initLoad(pnr){
        this.toggleSpinner(true);
        this.clearData(pnr);
        //await this.getAccountsContacts({fields: 'PHONE FIELDS', searchString: this.pnr});
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

    operateInput(el, value){

        if(!value) return;

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