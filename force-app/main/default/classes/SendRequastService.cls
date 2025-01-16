public with sharing class SendRequastService {
      
    public static void createContactOnReqres(String name){

        HttpRequest request = new HttpRequest();    
        request.setEndpoint('https://reqres.in/api/users');
        request.setBody('{"name": "' + name + '"}');
        request.setMethod('POST');

        new Http().send(request);
    }

    public static void createContactFromReqres(){

        HttpRequest request = new HttpRequest();    
        request.setEndpoint('https://reqres.in/api/users?page=2');
        request.setMethod('GET');

        HttpResponse response = new Http().send(request);
        List<Contact> cons = new List<Contact>(); 

        ReqResJsonParser objJsonParser = (ReqResJsonParser) JSON.deserializeStrict(response.getBody(), ReqResJsonParser.class);
        for(ReqResJsonParser.data data: objJsonParser.data){
            cons.add(new Contact(FirstName = data.first_name, LastName = data.last_name, Email = data.email, ReqresId__c = data.id, AvatarURL__c = data.avatar));
        }

        try { Database.upsert(cons, Schema.Contact.field.ReqresId__c, true, AccessLevel.USER_MODE); } 
        catch (Exception e) { throw new CSendRequastServiceException(e); }      
    }

    public with sharing class CSendRequastServiceException extends Exception {}

}