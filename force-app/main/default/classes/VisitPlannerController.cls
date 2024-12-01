public with sharing class VisitPlannerController {


    @AuraEnabled
    public static string addEvents(Id userId, Date startDateTime, List<Id> accIds){
        
        Date startOfDay = startDateTime;
        Date endOfDay = startDateTime.addDays(1);

        List<User> userSettings = [ SELECT StartOfDay__c, EndOfDay__c, DefaultVisitDuration__c, NumberVisitsPerDay__c, PauseBetweenVisitsInMinutes__c
                                    FROM User 
                                    WHERE Id = :userId];

        if(userSettings.size() == 0){          
            throw new AuraHandledException('User is not configured, please contact your administrator');
        }
    
        List<OpeningHours__c> opHours = [   SELECT Day_Of_Week__c, Preferred_Time__c, Opening_Time__c, Closing_Time__c 
                                            FROM OpeningHours__c 
                                            WHERE Account__c.Id IN :accIds 
                                                AND Account__c.RecordType.Name = 'Person Account'];

        if(opHours.size() == 0){            
            throw new AuraHandledException('No OpeningHours__c is defined');
        }
        
        String dayOfWeek = startOfDay.format('EEEE');

        List<Event> exsEvent = [SELECT StartDateTime, EndDateTime
                                FROM Event 
                                WHERE OwnerId = :userId
                                    AND StartDateTime >= :startOfDay
                                    AND EndDateTime < :endOfDay
                                ORDER BY StartDateTime];


        createBusyIntervals(exsEvent);
        createFreeIntervals();
        createFreeIntervals();
        
                                    
        List<Event> events = new List<Event>();
        //String timeRange = dayOfWeek + ' ' + userSettings[0].StartOfDay__c + ':00 - ' + userSettings[0].EndOfDay__c + ':00';                              
        VisitPlannerController.insertEvents(events);
        
    }

    @AuraEnabled
    public static string createEvent(Id userId, String accountName, Data eventStart, Data eventEnd){
        Event ev = new Event(OwnerId = userId,
                                StartDateTime = eventStart, 
                                    EndDateTime = eventEnd, 
                                        Subject = 'Visit accountName');
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }  

    @AuraEnabled
    public static string insertEvents(){
        Event ev = new Event(OwnerId = userIdwithDifferentTimezone,StartDateTime = eventStart, EndDateTime = eventEnd, Subject = subject);
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private with sharing List<TimeInterval> createBusyIntervals(List<Event> exsEvent, List<TimeInterval> busyIntevals){

        for(Event ev : exsEvent){
            TimeInterval interval = new TimeInterval(ev.StartDateTime, ev.EndDateTime, Preferred_Time__c);
            findCrossedIntervals(ev.EndDateTime, exsEvent, interval);
            busyIntevals.add(interval);
        }
    }

    private with sharing List<TimeInterval> findCrossedIntervals(List<Event> exsEvent, TimeInterval interval){

        for(Event ev : exsEvent){
            if(interval.endDateTime < ev.endDateTime && interval.endDateTime >= ev.startDateTime){
                interval.endDateTime = ev.EndDateTime;
            }
        }
    }

    private with sharing  class TimeInterval{
      
        public DateTime eventStart;
        public DateTime eventEnd;
        public Boolean isPreferredTime;
        public DateTime preferredTime;
        private Date day;

        public TimeInterval(DateTime eventStart, DateTime eventEnd, Integer preferredTime){
            day = eventStart.day();
            this.TimeInterval(eventStart, eventEnd, DateTime.newInstance(day, Time.newInstance(preferredTime, 0, 0, 0)));
        }
        
        public TimeInterval(DateTime eventStart, DateTime eventEnd, DataTime preferredTime){
            this.eventStart = eventStart;
            this.eventEnd = eventEnd;
            this.preferredTime = preferredTime;
            checkPreferredTime();
        }
        

        private Boolean checkPreferredTime(){
            this.isPreferredTime = false;
            if(this.eventStart <= preferredTime && preferredTime <= this.eventEnd){
                this.preferredTime = true;
            }
        }

        public Boolean isTimeInsideInterval(Datetime startToCheck, Datetime endToCheck){
            if(startToCheck >= this.eventStart && startToCheck <= this.eventEnd
                    && endToCheck >= this.eventStart && endToCheck <= this.eventEnd){
                return true;
            }
            return false;
        }

        

    }
    
}