({
	setContactColumns: function(cmp) {
   		cmp.set('v.contactColumns', [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	sortable: true, 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone', 	sortable: true},        
            {label: 'Account', 			fieldName: 'Account.Name', 		type: 'text', 	sortable: true}, 
         ]);
    },
            
    setAccountColumns: function(cmp){
    	cmp.set('v.accountColumns', [
            {label: 'Name', 			fieldName: 'Link', 				type: 'url', 	typeAttributes: {label: {fieldName: 'Name', }, 		target: '_blank', tooltip: 'go to contact',},},        
            {label: 'Phone', 			fieldName: 'Phone', 			type: 'phone',	},        
            {label: 'Address', 			fieldName: 'BillingAddress', 	type: 'text',	},
            {label: 'Type', 			fieldName: 'RecordType.Name', 	type: 'text',	},         
         ]);          
    },
    
    getAccountsContacts: function(cmp, searchObj, opperateFunc){
        const action = cmp.get('c.getAccountsContactsByPhone');
        action.setParams({searchString: searchObj.searchString, searchField: searchObj.fields});
        
        action.setCallback(this, function(response) {
            //this.handleSpinnerToggle(cmp);
            const state = response.getState();
            if(cmp.isValid() && state === 'SUCCESS') {
                const responseData = response.getReturnValue();
                const accountData = this.opperateFields(responseData[0]);
                const contactData = this.opperateFields(responseData[1]);

                cmp.set('v.accountData', accountData);
                cmp.set('v.contactData', contactData);
                
                if(opperateFunc !== null)
                    opperateFunc.call(this, cmp);  
            }
            else{
            	this.showToast(cmp, 'ERROR', 'error', 'Failed to retrieve data\n' + JSON.stringify(response.getError()));           
            }
        });
        //this.handleSpinnerToggle(cmp);
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
        const myPageRef = cmp.get('v.pageReference');
        cmp.set('v.pnr', myPageRef.state.c__pnr);
	},
    
    opperateFields: function(dataArr){
    	return dataArr.map(record => {record.Link = '/' + record.Id; return record;});
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
        
        /*//переписать
        if(type === 'success'){
         	cmp.set('v.visibleSucc', true);
        	cmp.set('v.messSucc', message);   
            setTimeout(() => {
                cmp.set('v.visibleSucc', false);
            }, 2000 );}
        else if(type === 'error'){
            cmp.set('v.visibleErr', true);
        	cmp.set('v.messErr', message);}  
        else
         	alert(message);   */               
    },
                
    handleSpinnerToggle: function (cmp) {
        $A.util.toggleClass(cmp.find('spinner'), 'slds-hide');
    },
})