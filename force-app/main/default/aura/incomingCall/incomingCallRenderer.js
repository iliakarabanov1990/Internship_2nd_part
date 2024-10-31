({
	rerender : function(cmp, helper) {
        if(cmp.get('v.pnr') !== helper.parthPhoneFromURL(cmp)){
            helper.initLoad(cmp);
        }
      
        this.superRerender();   
    }
})