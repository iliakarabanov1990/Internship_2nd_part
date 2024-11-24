import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import unknown_Caller from "@salesforce/label/c.Unknown_Caller";
import found_Accounts from "@salesforce/label/c.Found_Accounts";
import anonymous from "@salesforce/label/c.Anonymous";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import New_Personal_Account from "@salesforce/label/c.New_Personal_Account";
import New_Business_Contact from "@salesforce/label/c.New_Business_Contact";
import New_Account from "@salesforce/label/c.New_Account";
import Search_Existing_Accounts_Contacts from "@salesforce/label/c.Search_Existing_Accounts_Contacts";
import Found_Accounts from "@salesforce/label/c.Found_Accounts";
import Found_Contacts from "@salesforce/label/c.Found_Contacts";

import getAccountsContacts from "@salesforce/apex/IncomingCallController.getAccountsContacts";
import getBusinessRecordTypeId from "@salesforce/apex/IncomingCallController.getBusinessRecordTypeId";


export default class IncomingCallLwc extends NavigationMixin(LightningElement) {

    newPersonalAccount = New_Personal_Account;
    newBusinessAccount = New_Business_Contact;
    newAccount = New_Account;
    searchExistingAccountsContacts = Search_Existing_Accounts_Contacts;
    foundAccounts = Found_Accounts;
    foundContacts = Found_Contacts;

    pnr = '';
    accountData = [];
    contactData = [];
    accountColumns = [];
    contactColumns = [];
    businessRecordTypeId = null;
    searchStr = '';
    isOpenModal = false;
    searchAndCreateVisible = false;
    accountTableVisible = false;
    contactTableVisible = false;
    isLoading = true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference)
          this.initLoad(currentPageReference.state?.c__pnr);
    }

    async initLoad(pnr){
        this.clearData(pnr);
    	this.setPhoneFromURL(pnr);
        this.setContactColumns();
        this.setAccountColumns();
        await this.getAccountsContacts({fields: 'PHONE FIELDS', searchString: this.pnr});
        this.operateFirstLoad();
    }

    clearData(){
        this.pnr = '';
        this.accountData = [];
        this.contactData = [];
        this.accountColumns = [];
        this.contactColumns = [];
        this.businessRecordTypeId = null;
        this.searchStr = '';
        this.isOpenModal = false;
        this.searchAndCreateVisible = false;
        this.accountTableVisible = false;
        this.contactTableVisible = false;
    }

    setPhoneFromURL(pnr){ 
        this.pnr = this.parsePhoneFromURL(pnr);
    }

    parsePhoneFromURL(pnr){ 
        return pnr ? pnr.trim() : 'anonymous';
    }

    setContactColumns() {
        this.contactColumns = [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	sortable: true, 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone', 	sortable: true},        
            {label: 'Account', 			fieldName: 'AccountName', 		type: 'text', 	sortable: true}, 
        ];
    }
         
    setAccountColumns(){
        this.accountColumns = [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone',	},        
            {label: 'Address', 			fieldName: 'BillingAddress', 	type: 'text',	},
            {label: 'Type', 			fieldName: 'RecordTypeName', 	type: 'text',	},         
        ];        
    }

    async getAccountsContacts(searchObj){
        
        if (searchObj.searchString == 'anonymous')
            return;
       
        this.toggleSpinner(true);
        try{
            const data = await getAccountsContacts({searchString: searchObj.searchString, searchField: searchObj.fields});
            this.accountData = this.operateAccountFields(data[0]);
            this.contactData = this.operateContactFields(data[1]);
        }
        catch(error){
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message})); 
        }     
        this.toggleSpinner(false);
    }

    operateAccountFields(dataArr){
        return dataArr.map(record => {
            const result = Object.assign({}, record);
            result.Link = '/' + record.Id;
            result.BillingAddress = (record.BillingCountry ? record.BillingCountry + ', ' : '') 
                                    + (record.BillingCity ? record.BillingCity + ', ' : '')  
                                    + (record.BillingState ? record.BillingState + ', ' : '')
                                    + (record.BillingStreet ? record.BillingStreet + ', ' : '')	
                                    + (record.BillingPostalCode ? record.BillingPostalCode : '');
            result.RecordTypeName = record.RecordType ? record.RecordType.Name : '';
            return result;
        });
    }
            
    operateContactFields(dataArr){
        return dataArr.map(record => {
            const result = Object.assign({}, record);
            result.Link = '/' + record.Id;
            result.AccountName =  record.Account ? record.Account.Name : '';
            return result;
        });
    }
    
    operateFirstLoad(){
        
        if(this.accountData.length === 0 && this.contactData.length === 0){
            this.isOpenModal = true;  
            this.searchAndCreateVisible = true;
            this.getBusinessRecordTypeId();
        }
        else if(this.accountData.length <= 1 && this.contactData.length <= 1){
            const record = this.accountData.length === 0 ? this.contactData[0] : this.accountData[0];
            this.navigateToURL('standard__recordPage', {'recordId': record.Id, actionName: "view"}); 
        }
        else{
            this.isOpenModal = true;   
            this.operateTablesVisible();
        }   
        
        toggleSpinner(false);
    }
    
    operateTablesVisible(){       
        this.accountTableVisible = this.accountData.length !== 0;
        this.contactTableVisible = this.contactData.length !== 0;     
    }
    
    getBusinessRecordTypeId(){
        getBusinessRecordTypeId()
        .then(Id => this.businessRecordTypeId = Id)
        .catch(error => this.dispatchEvent(new ShowToastEvent({title: 'ERROR', variant: 'error', message: error.message})));  
    }   
                                    
    navigateToURL(type, attributes, state = {}) {   
        this[NavigationMixin.Navigate]({
            type,
            attributes,
            state,
        });
    }    

    openObjectCreateForm(objectApiName, state){       
        this.navigateToURL('standard__objectPage', {objectApiName: objectApiName, actionName: 'new'}, state);
    }
                
    /*handleSpinnerToggle(){
        //$A.util.toggleClass(cmp.find('spinner'), 'slds-hide');
    }

    handleNewAccountButton(){
        navigateToURL('standard__objectPage', {objectApiName: 'Account', actionName: 'new'}, {phone: this.pnr, recordTypeId: this.businessRecordTypeId});
    }*/

    get callerLabel(){
        return this.searchAndCreateVisible ? unknown_Caller : found_Accounts;
    }

    get phoneLabel(){
        return this.pnr === 'anonymous' ? anonymous : this.pnr;
    }

    handleModalCancel(){
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            },
        });
    }

    handleNewPersonAccountButton(){
        this.openObjectCreateForm('Account', 
                                    {defaultFieldValues: encodeDefaultFieldValues({Phone: this.pnr})});
    }

    handleNewAccountButton(){
        this.openObjectCreateForm(
            'Account', 
            {
                defaultFieldValues: encodeDefaultFieldValues({Phone: this.pnr}),
                recordTypeId: this.businessRecordTypeId
            });
    }

    handleNewContactButton(){
        this.openObjectCreateForm(
            'Contact', 
            {defaultFieldValues: encodeDefaultFieldValues({Phone: this.pnr})});
    }

    async handleSearch(event){ 

        this.toggleSpinner(true);

        this.accountData = [];
        this.contactData = [];
        const searchStr = event.target.value;

        if(searchStr && searchStr.length >= 2)
        	await this.getAccountsContacts({fields: 'NAME FIELDS', searchString: searchStr});

        this.operateTablesVisible();

        this.toggleSpinner(false);
    }

    toggleSpinner(isLoading){
        this.isLoading = isLoading;
    }
}