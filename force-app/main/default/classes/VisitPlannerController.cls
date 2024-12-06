public with sharing class VisitPlannerController {

    static Id userId;
    static Integer visitTimeMinets;
    static List<Id> accs;
    static List<TimeInterval> freeIntevals;
    static List<TimeInterval> busyIntevals;

    static Time startOfUserDay;
    static Time endOfUserDay;
    static Integer pauseBetweenVisitsInMinutes; 
    static Integer numberVisitsPerDay;
    static Decimal defaultVisitDuration; 
    static List<Event> newEvents;
    

    @AuraEnabled
    public static List<Id> addEvents(Date startDateTime, List<Id> accIds, Boolean isSendEmails){
        

        //не забыть про время начала и окончания у самих контрагентов


        userId = (Id)UserInfo.getUserId();
        accs = accIds;
        newEvents = new List<Event>();
        Date currDay = startDateTime;
        Date nextDay = currDay.addDays(1);


        checkOpeningHours();

        setUserSettings();      
        
        visitTimeMinets = getVisitTime();

        addEventsForDay(currDay, newEvents);
                                     
        insertEvents(newEvents);  
        

        return new List<Id>((new Map<Id, Event>(newEvents)).keySet());
    }

    @AuraEnabled
    public static void sendEmails(List<Id> eventIds, List<Id> accIds){

        List<EmailTemplate> emailTempls = [SELECT Id, Subject, HtmlValue  FROM EmailTemplate WHERE DeveloperName = 'Visit_Email_Template_1733310669865'];
        List<Event> events = [SELECT Id, WhatId, StartDateTime FROM Event WHERE Id IN :eventIds];
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT (SELECT Id, Email FROM Contacts) FROM Account WHERE Id IN :accIds]);

        if(emailTempls.size() == 0)
            throw new AuraHandledException('Can not find email template!');

        
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        for(Event ev: events){
            messages.add(createEmail(ev, accounts.get(ev.WhatId), emailTempls[0]));
        }

        Messaging.SendEmailResult[] messResalts = Messaging.sendEmail(messages, true);

        for(Messaging.SendEmailResult res : messResalts){
            if (!res.isSuccess()) 
                throw new AuraHandledException(res.getErrors()[0].getMessage());
        }

    }

    private static Messaging.SingleEmailMessage createEmail(Event ev, Account account, EmailTemplate emailTempl){
        

        String body = emailTempl.HtmlValue;

        body = body.replace('[EventDate]',  ev.StartDateTime.format()); 

        List<String> bodies = new List<String>();
        bodies.add(body);


        /*List<String> toAddress = new List<String>();
        toAddress.add(account.PersonEmail);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(emailTempl.Id);
        mail.setToAddresses(toAddress);
        
        //mail.setHtmlBody(body);
        mail.setTargetObjectId(account.Contacts[0].Id);
        mail.setWhatId(account.Id);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false); */
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddress = new List<String>();
        toAddress.add(account.Contacts[0].Email);

        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(account.Contacts[0].Id, ev.WhatId, bodies);
        body = renderResults[0].getMergedBody();

        mail.setSubject('Besuchsankündigung Karo Pharma');
        //mail.setTemplateId(emailTempl.Id);//'00XWU000008ZxOn2AK'); 
        //mail.setTargetObjectId(account.Contacts[0].Id);//'003WU000007bdorYAA');
        //mail.setWhatId(ev.WhatId);//'001WU00000TCpetYAD'); 
        mail.setHtmlBody(body);
        mail.setBccSender(false); 
        mail.setUseSignature(false); 
        mail.setSenderDisplayName('Card Division'); 
        mail.setSaveAsActivity(false); 
        mail.setToAddresses(toAddress);

        return mail;
    }

    private static void checkOpeningHours(){

        List<AggregateResult> opHours = [   SELECT Account__c, Count(Id)
                                            FROM OpeningHours__c 
                                            WHERE Account__c IN :accs 
                                            //    AND Account__r.RecordType.Name = 'Person Account'
                                            GROUP BY Account__c];

        if(opHours.size() < accs.size()) 
            throw new AuraHandledException('Not all selected accounts have filled Opening Hours!');
    }

    private static void setUserSettings(){
        List<User> userSettingsList = [ SELECT StartOfDay__c, EndOfDay__c, PauseBetweenVisitsInMinutes__c, DefaultVisitDuration__c, NumberVisitsPerDay__c 
                                        FROM User 
                                        WHERE Id = :userId];

        if(userSettingsList.size() == 0){          
            throw new AuraHandledException('User is not configured, please contact your administrator');
        }

        startOfUserDay = userSettingsList[0].StartOfDay__c;
        endOfUserDay = userSettingsList[0].EndOfDay__c;
        pauseBetweenVisitsInMinutes = userSettingsList[0].PauseBetweenVisitsInMinutes__c?.intValue();
        numberVisitsPerDay = userSettingsList[0].NumberVisitsPerDay__c?.intValue();
        defaultVisitDuration = userSettingsList[0].DefaultVisitDuration__c;
    }

    private static Integer getMinutesFromDecimal(Decimal timeDec){
        Integer hours = timeDec.round(System.RoundingMode.DOWN).intValue();
        return  hours * 60 + ((timeDec - hours) * 100).intValue();
    }

    private static void addEventsForDay(DateTime currDay, List<Event> newEvents){

        String dayOfWeek = currDay.format('EEEE');
        DateTime nextDay = currDay.addDays(1);
        Date day = Date.valueOf(currDay);
        Integer totalDaysEvents = 0;

        if(dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday'){
            VisitPlannerController.addEventsForDay(nextDay, newEvents);  
            return;
        }

        List<OpeningHours__c> opHours = [   SELECT  Day_Of_Week__c, 
                                                    Preferred_Time__c,
                                                    Opening_Time__c,
                                                    Closing_Time__c,
                                                    Account__c,
                                                    Account__r.Name,
                                                    Account__r.BillingStreet, 
                                                    Account__r.BillingPostalCode, 
                                                    Account__r.BillingCity 
                                            FROM OpeningHours__c 
                                            WHERE Account__c IN :accs 
                                            //    AND Account__r.RecordType.Name = 'Person Account'
                                                AND Day_Of_Week__c = :dayOfWeek
                                            ORDER BY Opening_Time__c];

        if(opHours.size() == 0){            
            VisitPlannerController.addEventsForDay(nextDay, newEvents);
            return;
        } 

        createBusyIntervals(currDay, nextDay);
        calculateFreeIntervals();
        fillForAccounts(newEvents, opHours, day, totalDaysEvents, true);
        fillForAccounts(newEvents, opHours, day, totalDaysEvents, false);

        if(accs.size() > 0)
            VisitPlannerController.addEventsForDay(nextDay, newEvents);   
    }

    private static void createBusyIntervals(DateTime currDay, DateTime nextDay){

        List<Event> exsEvent = [SELECT StartDateTime, EndDateTime
                                FROM Event 
                                WHERE OwnerId = :userId
                                    AND StartDateTime >= :currDay
                                    AND EndDateTime < :nextDay
                                ORDER BY StartDateTime];

       busyIntevals = new List<TimeInterval>();
        
        DateTime startT = getDateTimeFromTime(Date.valueOf(currDay), startOfUserDay);
        DateTime endT = getDateTimeFromTime(Date.valueOf(currDay), endOfUserDay);

        busyIntevals.add(new TimeInterval(startT, startT));
               
        for(Event ev : exsEvent){
            TimeInterval interval = new TimeInterval(ev.StartDateTime, ev.EndDateTime);
            VisitPlannerController.findCrossedIntervals(exsEvent, interval);
            busyIntevals.add(interval);
        }
        
        busyIntevals.add(new TimeInterval(endT, endT));
    }

    private static void insertBusyInterval(TimeInterval interval, Integer index){
        busyIntevals.add(index, interval);
    }

    private static Integer getIndexOfBusyInteval(TimeInterval interval){


        Integer indx = 0;
        for(TimeInterval busyInt: busyIntevals){
            if(busyInt.eventEnd <= interval.eventStart){
                indx = busyIntevals.indexOf(busyInt);
            }          
        }
        return indx;
    }
    

    private static void calculateFreeIntervals(){

        freeIntevals = new List<TimeInterval>();
        for(Integer i = 0; i < busyIntevals.size(); i++){
            if(busyIntevals.size() > i + 1){
                TimeInterval interval = new TimeInterval(busyIntevals[i].eventEnd, busyIntevals[i + 1].eventStart);
                freeIntevals.add(interval);
            }
        }
    }

    private static void fillForAccounts(List<Event> newEvents, List<OpeningHours__c> opHours, Date day, Integer totalDaysEvents, Boolean isOnlyPrefered){

        for (Integer i = opHours.size() - 1; i >= 0 ; i--){     
            if(fillAccountInterval(opHours[i], day, totalDaysEvents, isOnlyPrefered))
                opHours.remove(i); 
        }
    }  

    private static Boolean fillAccountInterval(OpeningHours__c accHours, Date day, Integer totalDaysEvents, Boolean isOnlyPrefered){

        if(totalDaysEvents >= numberVisitsPerDay || (isOnlyPrefered && accHours.Preferred_Time__c == 0)) return false;

        Integer intTime = accHours.Preferred_Time__c?.intValue();
        Datetime preferredTime = getDateTimeFromInteger(intTime, day);

        for(TimeInterval interval : freeIntevals){
        
            //comment in the method
            TimeInterval eventEnterval = lacateVisit(interval, preferredTime, isOnlyPrefered, accHours, day);
            
            if(eventEnterval != null){

                insertBusyInterval(eventEnterval, getIndexOfBusyInteval(eventEnterval)+1);
                calculateFreeIntervals();
                
                newEvents.add(createEvent(  accHours.Account__c, 
                                            accHours.Account__r.Name, 
                                            (String.isBlank(accHours.Account__r.BillingStreet) ? accHours.Account__r.BillingStreet + ', ' : '')
                                                + (String.isBlank(accHours.Account__r.BillingPostalCode) ? accHours.Account__r.BillingPostalCode + ', ' : '')
                                                    + (String.isBlank(accHours.Account__r.BillingCity) ? accHours.Account__r.BillingCity + ', ' : ''),
                                            eventEnterval.eventStart, 
                                            eventEnterval.eventEnd));
                //interval.eventStart = eventEnd;          
                totalDaysEvents += 1;
                //opHours.remove(i);
                removeAccFromList(accHours.Account__c); 

                return true;
            }
        }

        return false;
    }

    //if prefered time
    //  1. firts of all try to locane event with time start on pfreferd time 
    //  2. then with time end on emd time of free interval (becouse it will be the nearest time to pfreferd time)
    //if not prefered time
    //  3. just locate event on start time of interval
    private static TimeInterval lacateVisit(TimeInterval freeInterval, Datetime preferredTime, Boolean isOnlyPrefered, OpeningHours__c accHours, Date day){
        
        Datetime eventStart;
        Datetime eventEnd;
        TimeInterval eventInterval;

        Datetime intevalStrat = getVisitStartTime(freeInterval.eventStart, freeInterval.eventStart);
        Datetime intevalEnd = getVisitEndTime(freeInterval.eventEnd, freeInterval.eventEnd);

        intevalStrat = intevalStrat.time() < accHours.Opening_Time__c ?  getDateTimeFromTime(day, accHours.Opening_Time__c) : intevalStrat;
        intevalEnd = intevalEnd.time() > accHours.Closing_Time__c ?  getDateTimeFromTime(day, accHours.Closing_Time__c) : intevalEnd;       

        //check weather enough time in interval
        eventEnd = calculateEndTime(intevalStrat); 
        Boolean rightInterval = preferredTime >= intevalStrat && preferredTime <= intevalEnd || !isOnlyPrefered;

        if(!rightInterval || !intervalEnoughToEvent(intevalEnd, eventEnd)) return null;

        if(isOnlyPrefered){
            eventEnd = calculateEndTime(preferredTime);
            if(VisitPlannerController.intervalEnoughToEvent(intevalEnd, eventEnd)){ 
                eventInterval = new TimeInterval(preferredTime, eventEnd);//1
            }
            else{
                eventStart = calculateStartTime(intevalEnd);
                eventInterval = new TimeInterval(eventStart, intevalEnd);//2   
            }
        }
        else {              
            eventInterval = new TimeInterval(intevalStrat, eventEnd);//3
        }

        return eventInterval;
    }


    private static void removeAccFromList(Id toRemove){
        for(Integer i = accs.size() - 1; i >= 0; i--) {
            if(accs[i].equals(toRemove)) {
                accs.remove(i);
            }
        }
    }

    private static Integer getVisitTime(){
        return getMinutesFromDecimal(defaultVisitDuration);
    }

    private static DateTime getVisitStartTime(DateTime startTime, DateTime freeIntervalStart) {
        Boolean isPouseNeeded = isPreviousBusyInteval(freeIntervalStart);
        return startTime.addMinutes(isPouseNeeded ? pauseBetweenVisitsInMinutes : 0);
    } 

    private static DateTime getVisitEndTime(DateTime endTime, DateTime freeIntervalEnd) {
        Boolean isPouseNeeded = isNextBusyInterval(freeIntervalEnd);
        return endTime.addMinutes(isPouseNeeded ? -pauseBetweenVisitsInMinutes : 0);
    } 

    private static Boolean isPreviousBusyInteval(DateTime considerTime){
        return considerTime.time() != startOfUserDay;
    }

    private static Boolean isNextBusyInterval(DateTime considerTime){
        return considerTime.time() != endOfUserDay;
    }

    private static DateTime calculateEndTime(DateTime startTime) {
        return startTime.addMinutes(visitTimeMinets);
    } 

    private static DateTime calculateStartTime(DateTime endTime) {
        return endTime.addMinutes(-visitTimeMinets);
    } 

    private static Boolean intervalEnoughToEvent(DateTime intervalEnd, DateTime eventEnd){
        return intervalEnd >= eventEnd;
    }

    private static void findCrossedIntervals(List<Event> exsEvent, TimeInterval interval){

        for(Event ev : exsEvent){
            if(interval.eventEnd < ev.endDateTime && interval.eventEnd >= ev.startDateTime){
                interval.eventEnd = ev.EndDateTime;
                findCrossedIntervals(exsEvent, interval);
                break;
            }
        }
    }

    private static DateTime getDateTimeFromInteger(Integer hour, Date day){
        return DateTime.newInstance(day, Time.newInstance(hour, 0, 0, 0));    
    }

    private static DateTime getDateTimeFromTime(Date day, Time tim){
        return DateTime.newInstance(day, tim);    
    }

    private static Event createEvent(Id accountId, String accountName, String accountBillingAddress,  DateTime eventStart, DateTime eventEnd){      

        return new Event(
            OwnerId = userId,
            WhatId = accountId,
            StartDateTime = eventStart, 
            EndDateTime = eventEnd, 
            Subject = 'Besuch ' + accountName,
            Location = accountBillingAddress,
            DurationInMinutes = visitTimeMinets);
    }  

    private static void insertEvents(List<Event> newEvents){
        try {
            insert newEvents;    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private with sharing  class TimeInterval{
      
        public DateTime eventStart;
        public DateTime eventEnd;
        //public Boolean isClosed;
        /*public Boolean isPreferredTime;
        public DateTime preferredTime;*/
        //private Date day;
        

        public TimeInterval(DateTime eventStart, DateTime eventEnd){//, Integer preferredTime){
            this.eventStart = eventStart;
            this.eventEnd = eventEnd;
            //day = eventStart.day();
            //isClosed = false;
            //this.TimeInterval(eventStart, eventEnd);//, DateTime.newInstance(day, Time.newInstance(preferredTime, 0, 0, 0)));
        }
        
        /*public TimeInterval(DateTime eventStart, DateTime eventEnd, DateTime preferredTime){
            this.eventStart = eventStart;
            this.eventEnd = eventEnd;
            this.preferredTime = preferredTime;
            checkPreferredTime();
        }*/
        

        /*private Boolean checkPreferredTime(){
            this.isPreferredTime = false;
            if(this.eventStart <= preferredTime && preferredTime <= this.eventEnd){
                this.preferredTime = true;
            }
        }*/
        public Boolean isTimeInsideInterval(Datetime startToCheck, Datetime endToCheck){
            if(startToCheck >= this.eventStart && startToCheck <= this.eventEnd
                    && endToCheck >= this.eventStart && endToCheck <= this.eventEnd){
                return true;
            }
            return false;
        }
    }
    
}