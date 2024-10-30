({
    onPageReferenceChange: function(cmp, evt, helper) {       
        //https://saccesscraft-dev-ed.develop.lightning.force.com/lightning/cmp/c__incomingCall?png=7665
        helper.setPhoneFromURL(cmp);
        helper.setContactColumns(cmp);
        helper.setAccountColumns(cmp);
        helper.getAccountsContacts(cmp, {fields: 'PHONE FIELDS', searchString: cmp.get('v.pnr')}, helper.opperateFirstLoad);
    },
    
    handleNewPersonAccountButton: function(cmp, evt, helper) {

        helper.openObjectCreateForm(cmp,
                                    'Account', 
                                    {Phone: cmp.get('v.pnr')}, 
                                    {recordTypeId: cmp.get('v.businessRecordTypeId')});             
    },
    
    handleNewContactButton: function(cmp, evt, helper) {
        helper.openObjectCreateForm(cmp, 'Contact', {}, {});
    },
    
    handleNewAccountButton: function(cmp, evt, helper) {
        helper.openObjectCreateForm(cmp, 'Account', {Phone: cmp.get('v.pnr')}, {}, {});
    },
    
    handleSearch: function(cmp, event, helper) { 
        const searchStr = cmp.get('v.searchStr').trim();
        if(!!searchStr)
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