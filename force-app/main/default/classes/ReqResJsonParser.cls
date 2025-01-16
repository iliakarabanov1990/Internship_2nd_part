public with sharing class ReqResJsonParser {

    public data[] data;
    public Integer page;
    public Integer per_page;
    public Integer total;
    public Integer total_pages;
    public supp support;

    public class data {
        public String email;
        public String first_name;  
        public String last_name;
        public String avatar;
        public Integer id;   
    }

    public class supp {
        public String url;
        public String text;  
    }
}
    