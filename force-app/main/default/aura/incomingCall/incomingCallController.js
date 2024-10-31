({
    onPageReferenceChange: function(cmp, evt, helper) {       
        //https://saccesscraft-dev-ed.develop.lightning.force.com/lightning/cmp/c__incomingCall?c__pnr=7665
        helper.initLoad(cmp);
    },
    
    handleNewPersonAccountButton: function(cmp, evt, helper) {
		helper.openObjectCreateForm(cmp, 'Account', {Phone: cmp.get('v.pnr')}, {});                  
    },
    
    handleNewContactButton: function(cmp, evt, helper) {
        helper.openObjectCreateForm(cmp, 'Contact', {Phone: cmp.get('v.pnr')}, {});
    },
    
    handleNewAccountButton: function(cmp, evt, helper) {
        
        helper.openObjectCreateForm(cmp,
                                    'Account', 
                                    {Phone: cmp.get('v.pnr')}, 
                                    {recordTypeId: cmp.get('v.businessRecordTypeId')});
    },
    
    handleSearch: function(cmp, event, helper) { 
        const searchStr = cmp.get('v.searchStr').trim();
        if(searchStr && searchStr.length >= 2)
        	helper.getAccountsContacts(cmp, {fields: 'NAME FIELDS', searchString: searchStr}, helper.opperateTablesVisible); 
        else{
         	cmp.set('v.accountData', []);
        	cmp.set('v.contactData', []);
            helper.opperateTablesVisible(cmp);
        }   
    }, 
    
    handleModalCancel: function(cmp, event, helper) {
        helper.navigateToURL('e.force:navigateToURL', {'url': '/lightning/page/home'});
    }, 
})