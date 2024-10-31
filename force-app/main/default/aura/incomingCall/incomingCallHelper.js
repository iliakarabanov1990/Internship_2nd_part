({
	setContactColumns: function(cmp) {
   		cmp.set('v.contactColumns', [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	sortable: true, 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone', 	sortable: true},        
            {label: 'Account', 			fieldName: 'AccountName', 		type: 'text', 	sortable: true}, 
         ]);
    },
            
    setAccountColumns: function(cmp){
    	cmp.set('v.accountColumns', [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone',	},        
            {label: 'Address', 			fieldName: 'BillingAddress', 	type: 'text',	},
            {label: 'Type', 			fieldName: 'RecordTypeName', 	type: 'text',	},         
         ]);          
    },
    
    initLoad: function(cmp){
        
        this.clearData(cmp);
    	this.setPhoneFromURL(cmp);
        this.setContactColumns(cmp);
        this.setAccountColumns(cmp);
        this.getAccountsContacts(cmp, {fields: 'PHONE FIELDS', searchString: cmp.get('v.pnr')}, this.opperateFirstLoad);
    },
    
    clearData: function(cmp){
        cmp.set('v.accountData', []);
        cmp.set('v.contactData', []);
        cmp.set('v.searchStr', '');
        cmp.set('v.isOpenModal', false);  
        cmp.set('v.searchAndCreateVisible', false);
        cmp.set('v.accountTableVisible', false);
        cmp.set('v.contactTableVisible', false);
    },
    
    getAccountsContacts: function(cmp, searchObj, opperateFunc){
        
        if (searchObj.searchString == 'anonymous'){ 
            opperateFunc.call(this, cmp);
            return;
        }
        
        const action = cmp.get('c.getAccountsContacts');
        action.setParams({searchString: searchObj.searchString, searchField: searchObj.fields});
        
        action.setCallback(this, function(response) {
            this.handleSpinnerToggle(cmp);
            const state = response.getState();
            if(cmp.isValid() && state === 'SUCCESS') {
                const responseData = response.getReturnValue();
                const accountData = this.opperateAccountFields(responseData[0]);
                const contactData = this.opperateContactFields(responseData[1]);

                cmp.set('v.accountData', accountData);
                cmp.set('v.contactData', contactData);
                
                opperateFunc.call(this, cmp);  
            }
            else{
            	this.showToast(cmp, 'ERROR', 'error', 'Failed to retrieve data\n' + JSON.stringify(response.getError()));           
            }
        });
        this.handleSpinnerToggle(cmp);
        $A.enqueueAction(action);  
    },
    
    opperateFirstLoad: function(cmp){

        const accountData = cmp.get('v.accountData');
        const contactData = cmp.get('v.contactData');
        
  		if(accountData.length === 0 && contactData.length === 0){
            cmp.set('v.isOpenModal', true);  
            cmp.set('v.searchAndCreateVisible', true);
            this.getBusinessRecordTypeId(cmp);
        }
        else if(accountData.length <= 1 && contactData.length <= 1){
            const record = accountData.length === 0 ? contactData[0] : accountData[0];
            this.navigateToURL('e.force:navigateToSObject', {'recordId': record.Id}); 
        }
        else{
        	cmp.set('v.isOpenModal', true);   
            this.opperateTablesVisible(cmp);
        }      
    },
    
    opperateTablesVisible: function(cmp){
        
        const accountData = cmp.get('v.accountData');
        const contactData = cmp.get('v.contactData');
        
        cmp.set('v.accountTableVisible', accountData.length !== 0);
        cmp.set('v.contactTableVisible', contactData.length !== 0);     
    },
    
    getBusinessRecordTypeId: function(cmp){

        const action = cmp.get('c.getBusinessRecordTypeId');
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(cmp.isValid() && state === 'SUCCESS')
                cmp.set('v.businessRecordTypeId', response.getReturnValue());
            else
            	this.showToast(cmp, 'ERROR', 'error', 'Failed to retrieve data\n' + JSON.stringify(response.getError()));           
        });
        
        $A.enqueueAction(action);  
    },
    
    setPhoneFromURL: function(cmp){ 
        cmp.set('v.pnr', this.parthPhoneFromURL(cmp));
	},
                
    parthPhoneFromURL: function(cmp){ 
        const myPageRef = cmp.get('v.pageReference');
        const pnr = myPageRef.state.c__pnr;
        return pnr ? pnr.trim() : 'anonymous';
	},
    
    opperateAccountFields: function(dataArr){
    	return dataArr.map(record => {
            record.Link = '/' + record.Id;
            record.BillingAddress = (record.BillingCountry ? record.BillingCountry + ', ' : '') 
            						+ (record.BillingCity ? record.BillingCity + ', ' : '')  
            						+ (record.BillingState ? record.BillingState + ', ' : '')
            						+ (record.BillingStreet ? record.BillingStreet + ', ' : '')	
            						+ (record.BillingPostalCode ? record.BillingPostalCode : '');
            record.RecordTypeName = record.RecordType ? record.RecordType.Name : '';
            return record;
        });
	},
            
    opperateContactFields: function(dataArr){
    	return dataArr.map(record => {
            record.Link = '/' + record.Id;
            record.AccountName =  record.Account ? record.Account.Name : '';
            return record;
        });
	},
                                      
  	openObjectCreateForm: function(cmp, objectApiName, defaultFieldValues, state){
        const navService = cmp.find('navService');
        const pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'},
            state: state};

        if(Object.keys(defaultFieldValues).length !== 0)
        	pageRef.state.defaultFieldValues = cmp.find('pageRefUtils').encodeDefaultFieldValues(defaultFieldValues);
        
        navService.navigate(pageRef);
                                      
	},        
                                      
    navigateToURL: function (eventName, paramObj) {   
        const navEvt = $A.get(eventName);
        navEvt.setParams(paramObj);
        navEvt.fire();
    },    
                                      
	showToast: function(cmp, title, type, message){ 
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            duration: '3000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();            
    },
                
    handleSpinnerToggle: function (cmp) {
        $A.util.toggleClass(cmp.find('spinner'), 'slds-hide');
    },
})