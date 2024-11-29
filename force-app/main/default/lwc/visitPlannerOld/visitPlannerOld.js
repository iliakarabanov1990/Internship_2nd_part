import { LightningElement, wire, track, api } from 'lwc';
import getAccounts from '@salesforce/apex/VisitPlannerController.getAccounts';

//https://medium.com/@sfdcpulse/salesforce-lwc-datatable-with-pagination-e81c7df5693c#:~:text=Pagination%20is%20a%20technique%20used,with%20large%20amounts%20of%20information.
//https://salesforce.stackexchange.com/questions/410406/filter-data-on-client-side-js-in-lwc

export default class VisitPlanner extends LightningElement {
    
    
    

    columns = [
        {
            label: "Name", fieldName: "Link", type: "url", sortable: "true", typeAttributes: {
                label: { fieldName: 'Name'}, target: '_self' 
            }
        },
        { label: "Invoice Date", fieldName: "Invoice_Date__c", type: "Date", sortable: "true" },
        { label: "Due Date", fieldName: "Due_Date__c", type: "Date", sortable: "true" },
        { label: "Status", fieldName: "Status__c", type: "Text", sortable: "true" },
        { label: "Total", fieldName: "Total__c", type: "Number", sortable: "true" }
    ];
    
    fullAccounts = [];
    currAccounts = [];
    pageSize = 100;
    searchableFields = ['Name','Category__c','Make__c','MSRP__c'];


    currentPage = 1;
    totalRecords;
    totalPages; 

    searchText = '';
    searchKey = '';
    sortByUI = 'Link';    
    sortBy = 'Name';   
    sortByType = 'Text'; 
    sortDirection = 'asc';
    //used to Load the First Page. 
    first = true;
    //used to load the Next Page. It holds the sorted field value of last record of the current page
    after = '';
    //used to load the Next Page if multiple records have same sorted field value. It holds the Id of last record of the current page
    lastId = '';
    //used to load the Previous Page. It holds the sorted field value of first record of the current page
    before = '';
    //used to load the Previous Page if multiple records have same sorted field value. It holds the Id of first record of the current page
    firstId = '';
    //used to Load the Last Page. 
    last = false;
    lastPageSize = 0;

    isLoading = true;

    /*@wire(getAccounts, {
        accountId: "$recordId",
        searchKey: "$searchKey",     
        sortBy: "$sortBy",
        sortOrder: "$sortDirection",
        pageSize,
        first: "$first",
        after: "$after",
        lastId: "$lastId",
        before: "$before",
        firstId: "$firstId",
        last: "$last",   
        lastPageSize: "$lastPageSize",
        sortByType: "$sortByType"
    })
    getInvoiceRecords({ data, errors }) {
        this.isLoading = false;
        if (data) {
            this.records = data.map((rec) => {
                return {...rec, "Link": '/'+rec.Id }
            }); 
        }       
    }*/

    connectedCallback(){
       getAccounts()
       .then(data => opperateLoadData())
       .cantch(err => err);
    }     

    opperateLoadData(data){


        //...
        this.fullAccounts = data;
        this.currAccounts = this.fullAccounts;
        this.totalRecords = this.currAccounts.length;

    }

    filterAccount(){

        this.currAccounts = this.fullAccounts.filter(item=>{
            return this.searchableFields.some(field=>{
                if(field=='Name'||field=='Category__c'||field=='Make__c'){
                   return item[field].toLowerCase().includes(this.filterConditions.filterData.searchkey) 
                    
                }
            })
        })

    }

 

    handleSearchChange(event) {
        this.filterAccount();
    }


    /*handleSort(event) {
        this.currentPage = 1;  
        this.resetFields();
        this.refreshButtons();   

        this.sortByUI = event.detail.fieldName;
        this.sortBy = this.sortByUI == 'Link' ? 'Name' : this.sortByUI;     
        this.sortByType =  this.sortByUI == 'Link' ? 'Text' : this.columns.find(ele => ele.fieldName == this.sortByUI).type;
        this.sortDirection = event.detail.sortDirection;      
    }*/

    get showBar() {
        return this.totalPages > 1; 
    } 

    handleFirst() {        
        this.currentPage = 1;  
        this.resetFields();
        this.refreshButtons();
    }

    handleNext() {
        this.currentPage++;    
        this.resetFields();
        var lastRecord = this.records[this.currAccounts.length-1];
        this.after = lastRecord[this.sortBy] ? lastRecord[this.sortBy] : 'NULL'; 
        this.lastId = lastRecord['Id'];  
        this.first = false;
        this.last = (this.currentPage == this.totalPages);  
        this.refreshButtons();
    }

    handlePrevious() {   
        this.currentPage--;  
        this.resetFields();     
        var firstRecord = this.currAccounts[0];     
        this.before = firstRecord[this.sortBy] ? firstRecord[this.sortBy] : 'NULL'; 
        this.firstId = firstRecord['Id'];       
        this.first = (this.currentPage == 1);
        this.refreshButtons();
    }

    handleLast() {
        this.currentPage = this.totalPages; 
        this.resetFields();      
        this.first = false;
        this.last = true;  
        this.lastPageSize = this.totalRecords % pageSize;
        this.refreshButtons();
    }

    resetFields() {
        this.isLoading = true;  
        this.before = ''; 
        this.firstId = '';     
        this.after = ''; 
        this.lastId = '';       
        this.first = true;
        this.last = false;  
        this.lastPageSize = 0;
    }

    refreshButtons() {
        this.template.querySelectorAll('.icon_button').forEach(button => {
            button.classList.remove('icon_button_disabled');
        });
        if(this.last) {
            this.template.querySelector('[role=next]').classList.add('icon_button_disabled');
            this.template.querySelector('[role=last]').classList.add('icon_button_disabled');
        }
        if(this.first) {
            this.template.querySelector('[role=first]').classList.add('icon_button_disabled');
            this.template.querySelector('[role=previous]').classList.add('icon_button_disabled');
        }
    }

    get rowNumberOffset() {
        return (this.currentPage-1)*pageSize;
    }
}