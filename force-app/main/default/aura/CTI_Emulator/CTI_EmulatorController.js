({
	handleCallPnr : function(cmp, event, helper) {
        
        let pageRef;
        const navService = cmp.find('navService');
        const pnr = cmp.get("v.pnr");
        
        if(cmp.get("v.value") === 'lwc'){
            const encodedCompDef = btoa(JSON.stringify({componentDef: "c:incomingCallLwc", "state": {"c__pnr": pnr}}));
            pageRef = {
                "type": 'standard__webPage', 
                "attributes": {url: '/one/one.app#' + encodedCompDef},
                //"state": {"c__pnr": pnr}
                };
        }
        else{
            pageRef = {   
                "type": "standard__component",
                "attributes": {"componentName": "c__incomingCall"},    
                "state": {"c__pnr": pnr}     
            }
        }
            
        navService.navigate(pageRef);
	}
})