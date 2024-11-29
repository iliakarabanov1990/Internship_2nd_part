import { LightningElement, api } from 'lwc';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
    closeButtonLable = 'Close';
    acceptButtonLabel = 'Accept';

    today = new Date().toISOString();

    options = [
        { label: this.calendarEntriesOnlyLabel, value: 'calendarEntriesOnly' },
        { label: this.sendEmailOnlyLabel, value: 'sendEmailOnly' },
        { label: this.calendarEntriesAndEmailLabel, value: 'calendarEntriesAndEmail' },
    ];


    connectedCallback() {
        this.initLoad();
    }

    get accs(){
        console.log('test-strart');
        console.dir(JSON.stringify(this.accIds));
        console.log('test-strart');
        return this.accIds;
        
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

    handleStartDateChange(event){

    }

    handleChangeOptionChoice(event){

    }

    handleCloseButton(event){
        
    }

    handleAcceptButton(event){
        
    }

    

    handleModalCancel(){
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

    toggleSpinner(isLoading){
        this.isLoading = isLoading;
    }
}