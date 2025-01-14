public with sharing class SendRequastService {
      
    public static void createContactOnReqres(String name){

        HttpRequest request = new HttpRequest();    
        request.setEndpoint('https://reqres.in/api/users');
        request.setBody('{"name": "' + name + '"}');
        request.setMethod('POST');

        new Http().send(request);
    }
}