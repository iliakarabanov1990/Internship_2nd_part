public with sharing class QueueableRequstService implements Queueable, Database.AllowsCallouts {

    List<String> names;
    Integer i = 0;

    public QueueableRequstService(List<String> names) {
        this.names = names;
    }

    public void execute(QueueableContext context) {
        while (i < names.size()) {
            if(Limits.getCallouts() == Limits.getLimitCallouts()) { System.enqueueJob(this); break; }
            SendRequastService.createContactOnReqres(names[i]);
            i++;           
        }
    }   
}