import { LightningElement, api } from 'lwc';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//учесть таймзону https://salesforce.stackexchange.com/questions/284591/what-is-the-correct-approach-to-create-an-event-in-apex-for-another-user-with-th

export default class VisitPlanner extends NavigationMixin(LightningElement) {

    @api accIds;

    isOpenModal = true;
    isLoading = true;
    headerLabel = 'This is header';
    mainHintLabel = 'This is main hint';
    calendarEntriesOnlyLabel = 'Calendar entries only';
    sendEmailOnlyLabel = 'Send email only';
    calendarEntriesAndEmailLabel = 'Calendar entries + email';
    startDateLabel = 'Start date';
    closeButtonLabel = 'Close';
    acceptButtonLabel = 'Accept';

    startDateHintVisible = false;
    optionsHintVisible = false;

    startDate = new Date().toISOString();
    option = 'calendarEntriesOnly';

    options = [
        { label: this.calendarEntriesOnlyLabel, value: 'calendarEntriesOnly' },
        { label: this.sendEmailOnlyLabel, value: 'sendEmailOnly' },
        { label: this.calendarEntriesAndEmailLabel, value: 'calendarEntriesAndEmail' },
    ];

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
        /*setTimeout(
			function() {
				window.history.back();
			},
			1000
		);*/

        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
              objectApiName: "Account",
              actionName: "list",
            },
            state: {
              filterName: "Recent", 
            },
          });       
    }

    handleAcceptButton(event){
        if(!this.errorsExist()){
            /*this.disableSave = true;
            const isSent = await this.sendData();      
            this.disableSave = isSent;*/
        } 
    }

    async initLoad(pnr){
        this.toggleSpinner(true);
        this.clearData(pnr);
        //await this.getAccountsContacts({fields: 'PHONE FIELDS', searchString: this.pnr});
        this.operateFirstLoad();
        this.toggleSpinner(false);
    }

    operateFirstLoad(){
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