@isTest
private class VisitPlannerControllerTest {

    @IsTest(SeeAllData=true)
    static void addEventsTest() {

        /*List<Id> accIds = new List<Id>();
        accIds.add('001WU00000TCpetYAD');     
        accIds.add('001WU00000SY2fxYAD');

        VisitPlannerController.addEvents((Id)UserInfo.getUserId(), System.today(), accIds);*/

        List<Id> events = new List<Id>();
        events.add('00UWU000000a5Sb2AI');  
        VisitPlannerController.sendEmails(events);
        
    }
}