//controller for VisitPlanner LWC
//does: create events for visits, send email
public with sharing class VisitPlannerController {

    //  правки:
    //1.    User_moode и chema.SObjectType..isCreateable() добавлены
    //2.    Методы применяю только там где есть повторяющий код, или есть вложенные циклы (так как это бестрактис для apex)
    //          было 26! методов для создания визитов стало 7!
    //3.    Убрал внутренний класс и заменил его на Map<String, DateTime>
    //4.    Убрал поля класса и заменил их переменными метода
    //5.    Убрал последовательный вызов методов, которые ничего не получали и ничего не возвращали на, по возможности, чистые функции
    //6.    Использовал Database методов вместо try insert catch, обработал результат
    //7.    Использовал if(condition) { behavior; } 
    //8.    Удалил __test__ папку из LWC
    //9.    Подтянул VF Page в проект и залил на GITHub
    //10.   console.log поубирал везде
    //11.   Сделал проверку на то, что не выбраны аккаунты в LWC (+ меняю надпись при этом, лочу кнопку)
    //12.   В LWC убрал лишние переменные и лишнее маленькие методы
    //13.   Переписал hints с DOM на переменные класса, получилось супер (и универсальненько и в парадигме LWC и прозрачно, что происходит)
    //14.   Убрал ненужный параметр в VF Page и ненужные комметы
    //15.   ! Пока делал, нашел еще в задании показывать сообщение со ссылкой на каледарь
    //          так что сделал прикольный и крутой тост с ссылкой

    // Visit Scheduling
    //АЛГОРИТМ
    //1. Рекурсивно берем день за днем начиная с заданного пользователем, и распределяем визиты во все свободные места, до тех пор пока не распределим
    //2. Для каждого дня:
        //2.1. Идем по всем аккаунтам, которые еще не распределены (по факту перебираем OpeningHours для дня недели и проеряем в массиве разнесенных аккаунтов)
            //2.1.1.1. Сначала мы пытаемся распределить визиты с учетом предпочтительного времени, которое указал аккаунт
            //2.1.1.2. Заполняем все оставшееся время оставшимися не распределенными визитами
                // Так и не придумал алгоритм на Map<> или State Patern, которые бы катастрафически сильно не снижали оптимальность
    //3. Если остались нераспреденные аккаунты переходим к следующему буднему дню и все начинаем с п.1

    @AuraEnabled
    public static List<Id> addEvents(Date startDateTime, List<Id> accIds){

        List<Event> newEvents = new List<Event>();
        Map<String, Object> userSettings = new Map<String, Object>();

        //insert events with visits     
        if(!Schema.SObjectType.Event.isCreateable()) { throw new VisitPlannerControllerException('You don\'t have perpission to create events!'); }

        //check opening hours
        List<AggregateResult> opHoursCheck = [   SELECT Account__c, Count(Id)
                                            FROM OpeningHours__c 
                                            WHERE Account__c IN :accIds 
                                                AND Account__r.RecordType.Name = 'Person Account'
                                            WITH USER_MODE
                                            GROUP BY Account__c];

        if(opHoursCheck.size() < accIds.size()) { throw new VisitPlannerControllerException('Not all selected accounts are person or have filled Opening Hours!'); }
           
        List<OpeningHours__c> opHours = [  SELECT
                                                Day_Of_Week__c, 
                                                Preferred_Time__c,
                                                Opening_Time__c,
                                                Closing_Time__c,
                                                Account__c,
                                                Account__r.Name,
                                                Account__r.BillingStreet, 
                                                Account__r.BillingPostalCode, 
                                                Account__r.BillingCity 
                                        FROM OpeningHours__c 
                                        WHERE Account__c IN :accIds
                                        WITH USER_MODE
                                        ORDER BY Opening_Time__c];

        //get user settings of visits  
        List<User> userSettingsList = [ SELECT 
                                            StartOfDay__c, 
                                            EndOfDay__c,
                                            PauseBetweenVisitsInMinutes__c,
                                            DefaultVisitDuration__c,
                                            NumberVisitsPerDay__c 
                                        FROM User                                       
                                        WHERE Id = :UserInfo.getUserId()
                                        WITH USER_MODE];

        if(userSettingsList.size() == 0) { throw new VisitPlannerControllerException('User is not configured, please contact your administrator'); }

        User userEl = userSettingsList[0];
        Integer visitHours = userEl.DefaultVisitDuration__c.round(System.RoundingMode.DOWN).intValue();

        userSettings.put('id', userEl.Id);
        userSettings.put('startOfDay', userEl.StartOfDay__c);
        userSettings.put('endOfDay', userEl.EndOfDay__c);
        userSettings.put('pauseBetweenVisitsInMinutes', userEl.PauseBetweenVisitsInMinutes__c == null ? 0 : userEl.PauseBetweenVisitsInMinutes__c);
        userSettings.put('visitTimeMinets', visitHours * 60 + (userEl.DefaultVisitDuration__c.intValue() - visitHours) * 100);
        userSettings.put('numberVisitsPerDay', userEl.NumberVisitsPerDay__c);      
        

        //get all events
        //because if we got events for each next day it would be loop in loop
        //theoretically it may be not efficient, if user has really big busy future schedule
        // but it is better than loop in loop

        List<Event> plannedEvents = [SELECT StartDateTime, EndDateTime
                                    FROM Event 
                                    WHERE OwnerId = :userEl.Id
                                    WITH USER_MODE
                                    ORDER BY StartDateTime, EndDateTime];
        
      
                                    
        // locate visits from day to day  by recurtion
        //we consider day by day because the locate visits algorithm is quite sophisticated. (this method call recursion)
        newEvents.addAll(addEventsForDay(startDateTime, opHours, plannedEvents, userSettings, accIds.size(), new List<id>()));

        
        // Insert created events in DB
        List<Database.SaveResult> srList = Database.insert(newEvents, false, AccessLevel.USER_MODE);
        String errorMessge = '';    
        for (Database.SaveResult sr : srList) {           
            if (!sr.isSuccess()) {              
                for(Database.Error err : sr.getErrors()) { errorMessge += (err.getStatusCode() + ': ' + err.getMessage()) + '\r\n'; }
            }        
        }        
        if(errorMessge != '') { throw new VisitPlannerControllerException(errorMessge.left(errorMessge.length() - 2)); }


        return new List<Id>((new Map<Id, Event>(newEvents)).keySet());
    }

    private static List<Event> addEventsForDay(DateTime currDay, List<OpeningHours__c> opHours, List<Event> plannedEvents, Map<String, Object> userSettings, Integer countAcc, List<Id> operatedAccs) {
 
        //get all busy inteval in curr day, it will be needed to get free intervals
        List<Event> dayEvents = new List<Event>();
        List<Map<String, Datetime>> busyIntevals = new List<Map<String, Datetime>>();
        List<Map<String, Datetime>> freeIntevals = new List<Map<String, Datetime>>();
       
        Date day = Date.valueOf(currDay);
        String dayOfWeek = currDay.format('EEEE');
        Datetime nextDay = currDay.addDays(1);     
        Integer totalDaysEvents = 0; // we can't exceed max events per day for user
        
        Datetime startTime = Datetime.newInstance(day, (Time)userSettings.get('startOfDay')); 
        DateTime now = System.now();
        if(startTime < now) { startTime = now; }// it can be today in the middle of day, so cut previous part of day
        Datetime endTime = Datetime.newInstance(day, (Time)userSettings.get('endOfDay'));

        if(dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {            
            // we need boarders of user work day for create later free intevals
            busyIntevals.add(new Map<String, DateTime>{'eventStart' => startTime, 'eventEnd' => startTime});              
            for(Event ev : plannedEvents) {             
                if(ev.StartDateTime < startTime) { continue; }
                if(ev.StartDateTime >= endTime) { break; }
                //search for intersecting intevals and add only full big busy intervals
                //оставляю инкапсуляцию findLastDateCrossedIntervals, так как по бестпрактис for в for нежелательны и их нужно выносить в отдельную функцию, 
                Map<String, DateTime> interval = new Map<String, DateTime>{'eventStart' => ev.StartDateTime, 'eventEnd' => findLastDateCrossedIntervals(plannedEvents, ev.EndDateTime)};
                busyIntevals.add(interval);
            }      
            busyIntevals.add(new Map<String, DateTime>{'eventStart' => endTime, 'eventEnd' => endTime});

            // from busy intervals calculate free intervals
            for(Integer i = 0; i < busyIntevals.size(); i++) {
                if(busyIntevals.size() > i + 1){
                    freeIntevals.add(new Map<String, DateTime>{'eventStart' => busyIntevals[i].get('eventEnd'), 'eventEnd' => busyIntevals[i + 1].get('eventStart')});
                }
            }

            //first of all find intevals, whene we can sheduale visits in prefered times
            dayEvents.addAll(createEventsForDay(opHours, day, dayOfWeek, freeIntevals, operatedAccs, userSettings, totalDaysEvents, true));
            //then locate at all, wich was not lacoted
            dayEvents.addAll(createEventsForDay(opHours, day, dayOfWeek, freeIntevals, operatedAccs, userSettings, totalDaysEvents, false));
        }

        if(operatedAccs.size() < countAcc){ dayEvents.addAll(addEventsForDay(nextDay, opHours, plannedEvents, userSettings, countAcc, operatedAccs)); } 
            
        return dayEvents;
    }

    private static List<Event> createEventsForDay(List<OpeningHours__c> opHours, Date day, String dayOfWeek, List<Map<String, Datetime>> freeIntevals, List<Id> operatedAccs, Map<String, Object> userSettings, Integer totalDaysEvents,  Boolean isOnlyPrefered) {
          
        Event newEvent;
        List<Event> dayEvents = new List<Event>();   
        Decimal numberVisitsPerDay = (Decimal)userSettings.get('numberVisitsPerDay');
        
        for(OpeningHours__c openingHours : opHours) {    
            if(totalDaysEvents >= numberVisitsPerDay) { break; }
            if(!operatedAccs.contains(openingHours.Account__c) && openingHours.Day_Of_Week__c == dayOfWeek) {  
                
                //оставляю этот метод потому что по бестпрктис цикл в циклне - нельзя
                //а там мне приедся пройтись по свободным интервалам и определить подходит ли он для заполнения, потом еще пересчитать (разбить) свободный интервал
                newEvent = createEventForDayForAccount(openingHours, day, freeIntevals, userSettings, isOnlyPrefered);
                
                if(newEvent != null) { 
                    dayEvents.add(newEvent); 
                    operatedAccs.add(newEvent.WhatId);
                    totalDaysEvents += 1;
                }
            }               
        }

        return dayEvents;
    }

    private static Event createEventForDayForAccount(OpeningHours__c accHours, Date day, List<Map<String, DateTime>> freeIntevals, Map<String, Object> userSettings, Boolean isOnlyPrefered) {

        if((isOnlyPrefered && accHours.Preferred_Time__c == 0)) { return null; }

        Datetime preferredTime = DateTime.newInstance(day, Time.newInstance(accHours.Preferred_Time__c.intValue(), 0, 0, 0));

        for(Integer i = 0; i < freeIntevals.size(); i++){
        
            //loacate visit
                //if prefered time
                //  1. firts of all try to locate visit with time start at pfreferd time 
                //  2. then locate visit with end time at end time of free interval (becouse it will be the nearest time to preferd time of Account)
                //if not prefered time
                //  3. just locate event on start time of interval
            // не могу до конца принять, что пршлось логику из метода вынести просто в тело цикла
            // может быть сдесь сохранить вызов метода было бы лучше? 
            //Или то, что потом мне придется напистать тест на этот метод должно меня всегда предостерегать от инкапсуляции ради инкапсуляции?
            //we need add pause between events to our cosideration, if previous or next inteval is busy
            Map<String, DateTime> interval = freeIntevals[i];
            Integer pauseBetweenVisitsInMinutes = ((Decimal)userSettings.get('pauseBetweenVisitsInMinutes')).intValue();
            Integer visitTimeMinets = (Integer)userSettings.get('visitTimeMinets');
            Datetime eventStart = (Datetime)interval.get('eventStart');
            Datetime eventEnd = (Datetime)interval.get('eventEnd');
            Datetime intevalStart = eventStart.addMinutes(eventStart.time() == (Time)userSettings.get('startOfDay') ? 0 : pauseBetweenVisitsInMinutes);
            Datetime intervalEnd = eventEnd.addMinutes(eventEnd.time() == (Time)userSettings.get('endOfDay') ? 0 : -pauseBetweenVisitsInMinutes);

            //then we need check work day borders of account's work day
            intevalStart = intevalStart.time() < accHours.Opening_Time__c ? DateTime.newInstance(day, accHours.Opening_Time__c) : intevalStart;
            intervalEnd = intervalEnd.time() > accHours.Closing_Time__c ? DateTime.newInstance(day, accHours.Closing_Time__c) : intervalEnd;       

            //check weather enough time in interval
            Datetime visitStart = intevalStart;
            Datetime visitEnd = intevalStart.addMinutes(visitTimeMinets); 
            Boolean rightInterval = !isOnlyPrefered || preferredTime >= intevalStart && preferredTime <= intervalEnd;

            if(!rightInterval || visitEnd > intervalEnd) { continue; }

            if(isOnlyPrefered){
                //firstly try put visit with start time at preferredTime of Account
                //if time is not enough, we will put visit in the end of inteval (in this case it lets us to catch prefered time)
                visitEnd = preferredTime.addMinutes(visitTimeMinets);
                if(visitEnd <= intervalEnd) { visitStart = preferredTime; } //1
                else { visitStart = intervalEnd.addMinutes(-visitTimeMinets); visitEnd = intervalEnd; }  //2
            }

            //calculate borders of new free intevals           
            if(freeIntevals.size() <= i + 1) { freeIntevals.add(new Map<String, DateTime>{'eventStart' => visitEnd, 'eventEnd' => interval.get('eventEnd')}); }
            else { freeIntevals.add(i + 1, new Map<String, DateTime>{'eventStart' => visitEnd, 'eventEnd' => interval.get('eventEnd')}); }
            interval.put('eventEnd', visitStart);          

             
            //add event for visit
            return new Event(  
                OwnerId = (Id)userSettings.get('id'),
                WhatId = accHours.Account__c,
                StartDateTime = visitStart, 
                EndDateTime = visitEnd, 
                Subject = 'Besuch ' + accHours.Account__r.Name,
                Location = (String.isBlank(accHours.Account__r.BillingStreet) ? accHours.Account__r.BillingStreet + ', ' : '')
                                + (String.isBlank(accHours.Account__r.BillingPostalCode) ? accHours.Account__r.BillingPostalCode + ', ' : '')
                                    + (String.isBlank(accHours.Account__r.BillingCity) ? accHours.Account__r.BillingCity + ', ' : ''),
                DurationInMinutes = visitTimeMinets);
        }

        return null;
    }

    private static DateTime findLastDateCrossedIntervals(List<Event> exsEvent, Datetime eventEnd){

        for(Event ev : exsEvent) {
            if(eventEnd < ev.endDateTime && eventEnd >= ev.startDateTime) { eventEnd = ev.EndDateTime; }
        }

        return eventEnd;
    }

    private static void rememberAccsByAddedVisits(List<Id> operatedAccs, List<Event> newEvents){
        for(Event ev : newEvents) { operatedAccs.add(ev.WhatId); }
    }



    // Email Sending
    @AuraEnabled
    public static void sendEmails(List<Id> eventIds, List<Id> accIds){

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> emailTempls = [SELECT Id, Subject, HtmlValue  FROM EmailTemplate WHERE DeveloperName = 'Visit_Email_Template_1733310669865' WITH USER_MODE LIMIT 1];
        List<Event> events = [SELECT Id, WhatId, StartDateTime FROM Event WHERE Id IN :eventIds WITH USER_MODE];
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT PersonEmail FROM Account WHERE Id IN :accIds WITH USER_MODE]);

        if(emailTempls.size() == 0) { throw new VisitPlannerControllerException('Can not find email template!'); }

        for(Event ev: events){
            messages.add(createEmail(ev, accounts.get(ev.WhatId), emailTempls[0]));
        }

        Messaging.SendEmailResult[] messResalts = Messaging.sendEmail(messages, true);

        for(Messaging.SendEmailResult resMess : messResalts){
            if (!resMess.isSuccess()) { throw new VisitPlannerControllerException(resMess.getErrors()[0].getMessage()); }
        }
    }

    private static Messaging.SingleEmailMessage createEmail(Event ev, Account account, EmailTemplate emailTempl){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> bodies = new List<String>{emailTempl.HtmlValue.replace('[EventDate]',  ev.StartDateTime.format())};

        
        List<String> toAddress = new List<String>{account.PersonEmail};

        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(ev.WhatId, ev.WhatId, bodies);  

        mail.setSubject('Besuchsankündigung Karo Pharma');
        mail.setHtmlBody(renderResults[0].getMergedBody());
        mail.setToAddresses(toAddress);
        mail.setBccSender(false); 
        mail.setUseSignature(false); 
        mail.setSaveAsActivity(false);       

        return mail;
    }

    private class VisitPlannerControllerException extends Exception{} // AuraHandledException не виртиуальный, так что от Exception

}