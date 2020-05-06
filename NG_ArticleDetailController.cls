/*
* This class is used to display the Knowledge Article details (both to external users and preview to internal users)
*/ 
public with sharing class NG_ArticleDetailController {

    // Variables for capturing incoming parameters
    public boolean IsGuidedAssistance {get;set;}
    public string domaintype {get;set;}
    public string searchpage {get;set;}
    public String showdoctype {get;set;}
    public string imageshortcut{get;set;}
    public String showSecurityTag {get;set;}
    public Boolean showNetgearlogo {get;set;}
    public Boolean showArlologo {get;set;}    
    public String usercomment{get;set;} 
    public string IpValue {get;set;}
    public string articledetailsvar {get;set;}
    
        
    public boolean iscommentadd {get;set;}
    public String articleNumber {get;set;}
    public String publishStatus {get;set;}
    public String isPreview {get;set;}

    // Variables for displaying result in output vf page
    public ArticleWrapper article {get;set;}
    public String userFriendlyUrl {get;set;}
    public String metaCategories {get;set;}
    public String metaCategoriesLevel3 {get;set;}

    public String metaModels {get;set;}
    public List<ProductCategory> categoryHierarchy{get;set;}
    public Boolean feedbackSubmitted {get;set;}
    public String supportModelsJSON {get;set;}
    public String languageISOCode {get;set;}
    public String cssStyle {get;set;}
    public String cssStyle1 {get;set;}

    // variables for internal use
    private final String FIELD_LIST = 'ID,Summary, GA_Flow_ID__c,KnowledgeArticleId, ArticleNumber, Language, SEO_URL_Component__c, Solution_Section_1__c, Title, VersionNumber, UrlName, LastPublishedDate, CSS_Style__c, Do_Not_Crawl__c, Legacy_Answer_Id__c ';
    // MOVE TO NG_Constant CLASS IF NEEDED:
    private final String PRODUCT_SUPPORT_PAGE_URL  = 'https://www.netgear.com/support/product/{0}';
    private final String GSA_SEARCH_PAGE_URL = 'https://www.netgear.com/search-support.aspx?&q={0}';
    
    public String ARLOPRODUCT_SUPPORT_PAGE_URL  = 'https://www.arlo.com/en-us/products/{0}/default.aspx'  ;
    public String ARLOGSA_SEARCH_PAGE_URL = 'https://www.arlo.com/en-us/support/';
    
    
    //private final static String NETGEAR_SUPPORT_MODEL_JSON_URL = 'http://kb.netgear.com/cc/appController/SupportModels';
    private final static String NETGEAR_SUPPORT_MODEL_JSON_URL = System.Label.NG_SUPPORT_MODEL_JSON_URL;
    private final String ARTICLE_NOT_FOUND='https://kb.netgear.com/app/error//error_id/1';
    public String ARTICLE_STYLE_ARLO { get { return 'Arlo'; } }
    
    
    // In the production Instance (where URL redirection is active, set the base url to kb.netgear.com). Sandboxes should use the KB Site URL (e.g. kbchat-netgear.cs45.force.com)
    private final String baseURL = URL.getSalesforceBaseUrl().toExternalForm(); // = 'kb.netgear.com';  // For Prod

    //private String articleNumber;
    private String knowledgeArticleId;
    private Integer versionNumber;
    
    
    public Boolean pageShow {get;set;}
    
    public String topicName {get;set;}//Added for CEP-5951
    private String IdOfArticle;//Added for CEP-5951
    
    
     
    /* 
    * Constructor: fetch the article details from given article Id (When the )
    */ 
    public NG_ArticleDetailController() {
         
            
        IpValue = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        String language;//5182
        iscommentadd = false;
        Pagereference userFriendlyUrl =     ApexPages.CurrentPage();
        System.debug('$$$$ ^Incoming URL^: ' + userFriendlyUrl + '^Host^ : ' +userFriendlyUrl.getHeaders().get('Host') + ' ^Parameters^: ' + userFriendlyUrl.getParameters());
        System.debug(URL.getSalesforceBaseUrl().getHost());

        String pageUrl = ApexPages.CurrentPage().getUrl();
        String languageTemp =  ApexPages.CurrentPage().getParameters().get('language');         
        if(languageTemp != NULL){               
        language = languageTemp.escapeHtml4();      
        }
        //CEP-5182
        articleNumber =  String.isBlank(ApexPages.CurrentPage().getParameters().get('article'))?'':ApexPages.CurrentPage().getParameters().get('article').escapeHtml4();
        publishStatus =  String.isBlank(ApexPages.CurrentPage().getParameters().get('pubstatus'))?'':ApexPages.CurrentPage().getParameters().get('pubstatus').escapeHtml4(); 
        isPreview = String.isBlank(ApexPages.CurrentPage().getParameters().get('preview'))?'':ApexPages.CurrentPage().getParameters().get('preview').escapeHtml4(); 
        
       
        // Set the default value of publishStatus to 'Online' (for external users; Internal users can query for archive/draft versions too). Set to Online if not in preview mode
        publishStatus = (publishStatus == null || isPreview != 'true' ? 'Online' : publishStatus);

        categoryHierarchy = new List<ProductCategory>();
        metaCategories = '';
        metaCategoriesLevel3  = '';

        metaModels = ''; 
        System.debug(URL.getSalesforceBaseUrl().getHost());
        // Fetch the Host information (the actual domain which forwared the request to Salesforce (e.g: kb.netgear.fr   OR kb.netgear.com OR ...etc)
        Map<String,String> pageHeaders = userFriendlyUrl.getHeaders();
        String hostName = (pageHeaders != null) ? pageHeaders.get('Host') : '';
        
        // Get all possible URL patterns:
        Map<String, NG_DomainPatterns__c> domainPatterns = NG_DomainPatterns__c.getAll();
        NG_DomainPatterns__c currentDomain = domainPatterns.get(hostName);
        
        // Find the appropriate language code for the incoming domains (if the request is made from kb.netgear.nl, set the language code to nl_NL automatically).
        // If Language has been passed explicitly, keep as is (in next step find it's SF compatible version 2/5 digit version of the language)
        language = ( String.isBlank(language) && isPreview != 'true' && currentDomain != null && !String.isBlank(currentDomain.Language_ISO__c)) ? currentDomain.Language_ISO__c : language;
        
        // Transform and/Or validate the 'language' parameter (If an invalid language is passed then default to English)
        String languageISOCodeTemp = NG_Utilities.getLanguageISO(language);         
        languageISOCode = languageISOCodeTemp.escapeHtml4();
        if(languageISOCode == 'en_US')
            ARLOPRODUCT_SUPPORT_PAGE_URL  = 'https://www.arlo.com/' + 'en-us' + '/support/';
        else
            ARLOPRODUCT_SUPPORT_PAGE_URL  = 'https://www.arlo.com/' + languageISOCode  + '/support/';
        
               
    }
    
    
    
   
    /*
    * This action method retrives the article details; If article not found, then redirects user to Article-Not-Found page
    */ 
    public PageReference fetchArticleDetails() {
        
        
        
        PageReference redirectUrl = new PageReference(ARTICLE_NOT_FOUND);   // Fall back to error not found page.
        try {
            System.debug('$$$%%^%^%' + articleNumber + ' ^Language^ : ' + languageISOCode);
            // Check if the article is a valid number or not (to avoid any random string)
            if(articleNumber != null && articleNumber.isNumeric()) {
                sObject genericArticleRecord = NG_KnowledgeArticleService.getArticleVersionByArticleNumberStatus(articleNumber, publishStatus, languageISOCode, FIELD_LIST, isPreview);
                system.debug('^genericArticleRecord^ : $$$:' + genericArticleRecord);
                if(genericArticleRecord != null) {
    
                    String articleTitle = String.valueOf(genericArticleRecord.get('Title'));
                    String summary = String.valueOf(genericArticleRecord.get('Solution_Section_1__c'));
                    String seoUrlComponent = String.valueOf(genericArticleRecord.get('SEO_URL_Component__c'));
                    String urlName = String.valueOf(genericArticleRecord.get('UrlName'));
                    Date lastPublishedDate = Date.ValueOf(genericArticleRecord.get('LastPublishedDate'));
                    Boolean doNotCrawl = Boolean.valueOf(genericArticleRecord.get('Do_Not_Crawl__c'));
                    String cssStyle = String.valueOf(genericArticleRecord.get('CSS_Style__c'));
                    string gaFlowId= String.valueOf(genericArticleRecord.get('GA_Flow_ID__c'));
                    string NavId= String.valueOf(genericArticleRecord.get('ID'));
                    IdOfArticle = NavId;//added for CEP-5951
                    //Adding meta tag data's if summary is not there.
                    string stdsummary;
                    if(genericArticleRecord.get('summary') != null && genericArticleRecord.get('summary') != '')
                       stdsummary= String.valueOf(genericArticleRecord.get('summary')).left(500);
                    else if(genericArticleRecord.get('Solution_Section_1__c') != null && genericArticleRecord.get('Solution_Section_1__c') != '')
                    {
                       stdsummary = String.valueOf(genericArticleRecord.get('Solution_Section_1__c'));
                       stdsummary = stdsummary.replaceall('&nbsp;', ' ');
                       stdsummary= stdsummary.stripHtmlTags().left(500);
                     
                    }
                    
                    
                    
        
                    versionNumber = genericArticleRecord.get('VersionNumber') != null ? Integer.valueOf(genericArticleRecord.get('VersionNumber')) : null;
                    knowledgeArticleId = String.valueOf(genericArticleRecord.get('KnowledgeArticleId'));
                    boolean mstrlanguage = true;
                     knowledgeArticleId = knowledgeArticleId.escapeHtml4();
                     publishStatus =publishStatus.escapeHtml4();
                     
                    //subba
                    //String queryString = 'SELECT  Id, Title_Meta_tag__c, IsGuidedAssistance__c,GuidedAssistanceURL__c, Article_Sub_Classification__c, CSS_Style__c, Answer_Id__c,Answer_Type__c,Answer_URL__c,MasterVersion.Language FROM Netgear__kav WHERE KnowledgeArticleId = \''+knowledgeArticleId +'\' AND PublishStatus = \''+publishStatus  +'\' AND IsMasterLanguage = \''+mstrlanguage+'\'  ';
                    String queryString = 'SELECT  Id, Title_Meta_tag__c, IsGuidedAssistance__c,GuidedAssistanceURL__c, Article_Sub_Classification__c, CSS_Style__c, Answer_Id__c,Answer_Type__c,Answer_URL__c,MasterVersion.Language FROM Netgear__kav WHERE KnowledgeArticleId = \''+knowledgeArticleId +'\' AND PublishStatus = \''+publishStatus  +'\' AND IsMasterLanguage = :mstrlanguage';
                    system.debug('vv1122 ' + querystring);
                    String querySelect = queryString.substringBefore(' WHERE ');
                    String queryWhere = queryString.substringAfter('WHERE');
                    String formatedQuery = '{0} WHERE {1}'; 
                    System.debug('AfterEscape :' + queryString);
                    List<Netgear__kav> lstArticles = Database.Query(String.Format(formatedQuery,new List<String> {String.escapeSingleQuotes(querySelect),queryWhere}));
                    
                    
                   // List<Netgear__kav> lstArticles = Database.Query(queryString);
                    if(lstArticles[0].CSS_Style__c=='Netgear')
                    {
                       showNetgearlogo = true;
                       domaintype = label.NG_KB_Support_Domain;
                       searchpage = 'search-support.aspx';
                       imageshortcut = 'images/favicon.ico';
                    }  
                    else
                    { 
                        showNetgearlogo = false;
                        domaintype = label.Arlo_KB_Support_Domain;
                        imageshortcut = 'images/arlo-favicon/favicon.ico';
                        if(languageISOCode == 'en_US')
                            searchpage = 'en-us/search-arlo.aspx';
                        else if(languageISOCode == 'ja')
                            searchpage = 'jp/search-arlo.aspx';
                        else if(languageISOCode == 'zh_CN')
                            searchpage = 'cn/search-arlo.aspx';
                        else if(languageISOCode == 'zh_TW')
                            searchpage = 'cn/search-arlo.aspx';
                        else
                            searchpage = languageISOCode  + '/search-arlo.aspx';
                    }    
                    cssStyle1 = lstArticles[0].CSS_Style__c;    
                    if(lstArticles[0].CSS_Style__c=='Arlo')
                       showArlologo = true;
                    else 
                        showArlologo = false;
                        
                        
                   IsGuidedAssistance = lstArticles[0].IsGuidedAssistance__c; 
                    
                    showSecurityTag = 'Knowledge Article';
                    if(lstArticles[0].Article_Sub_Classification__c=='Security Vulnerability')
                        if(!showArlologo)
                           showSecurityTag = 'Security Advisory';
                    
                   
                   
                    if (showArlologo)
                    {
                       showdoctype= 'doctype';
                       showSecurityTag = 'Support Articles';

                     }
                    else
                       showdoctype= 'document_type';
                        
                    /*if([select id from netgear__kav where id =:lstArticles[0].id WITH DATA CATEGORY Categories_Hierarchy__c AT 
                                Security_CommonTopics__c].size() > 0)
                                    showSecurityTag = 'Security Advisory';
                      */              
                                    
                    system.debug('lstArticles******'+lstArticles);
                    if(lstArticles != null && lstArticles.size() >0) {
                        if(lstArticles[0].Answer_Type__c=='URL' && lstArticles[0].Answer_URL__c != NULL){
                            //redirectToURL(lstArticles[0].Answer_URL__c);
                            PageReference pageRef = new PageReference(lstArticles[0].Answer_URL__c.escapeHtml4());
                            return pageRef;
                        }
                    }
                    //end Subba Code
                    
                    // If the article exists, increase its view count by 1 (Exclude for page previews by internal customsers)
                    if(isPreview != 'true')
                        NG_PageStatService.increseArticleViewCount(knowledgeArticleId, articleNumber, languageISOCode, versionNumber);
    
                    // Get the view count of the article (KA not KAV)
                    //Integer viewCount = NG_PageStatService.getTotalArticleViewCount(knowledgeArticleId);
                    
                    // Get the count of users who found this article helpful
                    Integer articleHelpfulCount = NG_PageStatService.getThumbUpCountForLast30Days(knowledgeArticleId);
    
                    // prepare the wrapper with all required values
                    article = new ArticleWrapper(gaFlowId,articleTitle, articleNumber, summary, articleHelpfulCount, lastPublishedDate, doNotCrawl, cssStyle,stdsummary, string.valueof(lstArticles[0].guidedassistanceurl__c), lstArticles[0].Title_Meta_tag__c);
    
                    // Create the user friendly url to display in the user's browser (Add the language parameter except for Engilsh language)
                    userFriendlyUrl = baseURL +(languageISOCode != 'en_US' ? '/'+languageISOCode : '') + '/'+articleNumber+'/' + (seoUrlComponent != null ? seoUrlComponent : urlName);
                    userFriendlyUrl = userFriendlyUrl.escapeHtml4();
    
                    // Get the meta data and related categories:
                    Map<String,List<String>> mapCategoryHierarchy = NG_ProductCategoryService.getSpecificProductCategoriesForArticle(knowledgeArticleId);
    			
                    if(mapCategoryHierarchy != null) {
                        List<String> allRelatedProductItems = new List<String>();
                        List<String> allRelatedCategories = new List<String>();
                        for(String l4ProdCategory : mapCategoryHierarchy.keySet()) {
                            // Get the product items (level 7) for the product category (L4)
                            List<String> lstProductItems = mapCategoryHierarchy.get(l4ProdCategory);
    
                            // Add the products to a giant list to use in the meta tags
                            allRelatedProductItems.addAll(lstProductItems);
                            allRelatedCategories.add(l4ProdCategory);
    
                            // Create the Products in respective category & their Urls:
                            // Incase a product has an underscore or plus or parenthesis sign in the name the link should take them to the GSA search page with product name appended as query string to the link 
                            Map<String,String> productMap = new Map<String,String>();
                            if(lstProductItems != null && lstProductItems.size() > 0) {
                                // Check the product names and prepare the URLs
                                for(String item: lstProductItems) {
                                    // Check for existance of Plus, Underscore or paranthesis in the product name
                                    String productItemUrl;
                                    if(ShowNetgearlogo)
                                      productItemUrl  = String.format( (item.indexOfAny('_+() ') == -1 ? PRODUCT_SUPPORT_PAGE_URL: GSA_SEARCH_PAGE_URL ), new List<String>{item});
                                    if(ShowArlologo)
                                    {
                            
                                      productItemUrl  = String.format( (item.indexOfAny('_+() ') == -1 ? ARLOPRODUCT_SUPPORT_PAGE_URL: ARLOPRODUCT_SUPPORT_PAGE_URL), new List<String>{item});
                                     }
                                    productMap.put(item, productItemUrl);
                                }                           
                            }
                            categoryHierarchy.add(new ProductCategory(l4ProdCategory, productMap));
                        }
                        system.debug('categoryHierarchy-->'+categoryHierarchy);
                        // Create the meta tags from the product Level 4 category & Level 7 categories
                        metaCategories = String.join(allRelatedCategories,',');
                        metaModels = String.join(allRelatedProductItems, ',');                        
                        metaCategoriesLevel3 = NG_ProductCategoriesSelector.selectSpecificProductCategoriesForArticleforlevel3(knowledgeArticleId);
                        
                    }
                    // set redirectUrl to Null to stay on the same page.
                    redirectUrl = null;
                    
                    //Sets the ariticle details to the property to send data to remote action.
                    String strtemp;
                    if (isPreview != null && isPreview != '')
                        strtemp = ispreview;
                    else
                        strtemp = 'false';
                    articledetailsvar = String.valueOf(genericArticleRecord.get('KnowledgeArticleId')) + ',' + articleNumber + ',' + languageISOCode + ',' +  versionNumber + ',' +  IpValue + ','+ strtemp;                     
                    articledetailsvar = articledetailsvar.escapeHtml4();
                    
                }
            }
            //CEP-5951--CHANGES START
            List<String> topicList = new List<String>();
            List<String> catgLabel = new List<String>();
            if(IdOfArticle != NULL){
                Set<Id> setArticleID = new Set<Id>{IdOfArticle};            	
                for(sObject dataCategory : NG_KnowledgeArticlesSelector.getDataCategoryFromKnowlegdeArticleKavIdSet(setArticleID)){
                    String data= String.valueof(dataCategory.get('DataCategoryName'));
                    system.debug('data with underscore'+data);
                    if(data != null)                        
                    	topicList.add(data);                 
                }
                system.debug('topicList-->'+topicList);
            }
            if(topicList.size() > 0){                
                for (Data_Category__c datcatg: [Select Label__c from Data_Category__c where LanguageCode__c = 'en_US'
                                                AND Data_Category_Name__c IN:topicList]){
                                                    catgLabel.add(datcatg.Label__c); 
                                                }
            }
            system.debug('catgLabel-->'+catgLabel);
            if(catgLabel.size() > 0)
                topicName = String.join(catgLabel, ','); 

        } catch(Exception e) {
            System.debug('$$$ ^Error Message: ^'+e.getMessage());
        }
        return redirectUrl;
       
    }

    /*
    * This action method retrives the article details; If article not found, then redirects user to another page
    */ 
    public PageReference processThumbUpAction() {
        
        
        Boolean iprangecheck = NG_PageStatService.getAricleFeedbackIpfortoday(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, IpValue);
       

        if(isPreview != 'true' && iprangecheck == true)
        {
            
            iscommentadd = true;
            NG_PageStatService.increseArticleThumbUpCount(knowledgeArticleId, articleNumber,languageISOCode, versionNumber);
            NG_PageStatService.createUserFeedbackTrack(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, IpValue);
            feedbackSubmitted = true; // Set to true to display user a message
        }
            knowledgeArticleId = knowledgeArticleId.escapeHtml4();//5182
            // Get the latest thumb up count:
            article.articleHelpfulCount = NG_PageStatService.getThumbUpCountForLast30Days(knowledgeArticleId);
        return null;
    }

    public PageReference processThumbDownAction() {
    
    
        Boolean iprangecheck = NG_PageStatService.getAricleFeedbackIpfortoday(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, IpValue);
        
        
    
        // Avoid changing the thumb/up down count for previews
        if(isPreview != 'true' &&  iprangecheck == true)
            {
                
                iscommentadd  = true;
                NG_PageStatService.increseArticleThumbDownCount(knowledgeArticleId, articleNumber,languageISOCode, versionNumber);
                NG_PageStatService.createUserFeedbackTrack(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, IpValue);
                feedbackSubmitted = true; // Set to true to display user a message    
            }
            
            // This doesn't change the Thumb up count, so no need to query again.
        return null;
    }

    // Get the support models from the netgear website to this current page - to be used by the page for auto complete
    @RemoteAction
     public static String getSupportModels() {
        String supportModelsJSON ='';
        HTTPRequest req = new HTTPRequest();
        req.setMethod('GET');
        req.setEndpoint(NETGEAR_SUPPORT_MODEL_JSON_URL);
        Http h = new Http();
        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            supportModelsJSON= res.getBody();    
        }
        return supportModelsJSON;
    }

    // To support all article types (Netgear , 'Arlo' type later)
    public class ArticleWrapper {
        public String title {get;set;}
        public String articleNumber {get;set;}
        public String summary{get;set;}
        //public Integer viewCount {get;set;}
        public Integer articleHelpfulCount {get;set;}
        public Date lastPublishedDate {get;set;}
        public Boolean doNotCrawl {get;set;}
        public String cssStyle {get;set;}
        public String gaFlowId {get;set;}
        public String stdsummary {get;set;}
        public string guidedURL {get;set;}
        public string titleMetaTag {get;set;}
        
        public ArticleWrapper(string gaFlowId,String title, String articleNumber, String summary, Integer articleHelpfulCount, Date lastPublishedDate, Boolean doNotCrawl, String cssStyle , string stdsummary, string guidedURL , string titleMetaTag ) {
            this.title = title;
            this.articleNumber = articleNumber;
            this.summary = summary;
            this.articleHelpfulCount = (articleHelpfulCount == null ? 0: articleHelpfulCount);
            this.lastPublishedDate = lastPublishedDate;
            //this.viewCount = (viewCount == null ? 0 : viewCount);
            this.doNotCrawl = (doNotCrawl == null ? false : doNotCrawl);
            this.cssStyle = cssStyle;
            this.gaFlowId = gaFlowId;
            this.stdsummary= stdsummary;
            this.guidedURL= guidedURL;
            if(titleMetaTag != null && titleMetaTag != '')
                this.titleMetaTag = titleMetaTag;
             else
                 this.titleMetaTag = title;  
             
        }
    }

    // To hold the product category , related product & product count - displayed at the right side of the public facing page
    public class ProductCategory{
        public String categoryName {get;set;}
        public Map<String,String> productMap {get;set;} // List of articles & their url
        public Integer productCount {get;set;}

        public ProductCategory(String categoryName, Map<String,String> productMap){
            this.categoryName = categoryName;
            this.productMap = productMap;
            this.productCount = (productMap!= null ? productMap.size() :0);
        }
    }
    
    
    //Method to crete the feedback for articles
    public void CreateCommentforArticle()
        
    {
        Boolean iprangecheck = NG_PageStatService.getAricleFeedbackIpfortoday(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, IpValue);        
        if(isPreview != 'true')
        {
        string passedParam1 =  usercomment;
        if(passedParam1 != '' && passedParam1 != null)
            NG_PageStatService.createArticleUserFeedbackComment(knowledgeArticleId, articleNumber,languageISOCode, versionNumber, passedParam1);
        
        }
    }
    
    
    //Method to fetcht the status of the IP for the day and for the article.
    @RemoteAction 
    public static boolean checkCommentstatus(string test)
    {
        system.debug('fr11' + test + ' ');
        string[] st = test.split(',');
        
        Boolean iprangecheck = NG_PageStatService.getAricleFeedbackIpfortoday(st[0], st[1],st[2], integer.valueof(st[3]), st[4]);
        if(st.size() > 4)
        {
            if(st[5] == 'true')
                iprangecheck = false;
        }
        return iprangecheck ;
    }
}