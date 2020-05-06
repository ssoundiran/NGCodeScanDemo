/************************************************************************
* Name :CEP_AssetHelper
* Author:Nitesh Halliyal
* Date : 23rd december 2017
* Desc : This is a helper class for all trigger logic on asset.
*
*
*************************************************************************/
public class CEP_AssetHelper {

public static map<string,string> newastAccountmap = new map<string,string>(); //CEP-6033

/* Method Name: createEntitlementsContarcts                                                     	
* Author Name: Nitesh Halliyal
* Description: This is used in the asset trigger to create entitlements and contracts on creation of asset.
* Parameters: list<asset>
* Returns:    void
*/
/* Commented by Gokul CEP - 4834 
   Public static void createEntitlementsContarcts(list<asset> assetList,Boolean entitlementOnCountryChange){
        System.debug(' Inside CEP_AssetHelper --> createEntitlementsContarcts**');
        set<string> productIdSet = new Set<string>();
        list<Entitlement> entitlementWithoutDateList = new list<Entitlement>();
        list<Entitlement> entitlementWithDateList = new list<Entitlement>();
        set<String> assetupdateSet = new set<String>();
        set<String> accIdSet = new set<String>();//Added for meural
        set<String> proIdSet = new set<String>();//Added for meural
        map<String,date> meuralConMap = new map<String,date>();//Added for meural
        boolean checker = false;
        for(asset ast :assetList){
            if(String.isNotBlank(ast.CEP_Product_Map__c) && String.isNotblank(ast.CEP_Asset_Type__c) && ast.CEP_Asset_Type__c == 'New'){
                productIdSet.add(ast.CEP_Product_Map__c);
                if(ast.Accountid != null)//Added for meural
                    accIdSet.add(ast.Accountid);
                if(ast.product2id != null)
                    proIdSet.add(ast.product2id);
            }
        }
        //system.debug('productIdSet======>'+productIdSet);
        if(productIdSet.size() > 0){           
            
            Map<id,List<CEP_Entitlement_Association__c>>  EntitlementAssocMap = new Map<id,List<CEP_Entitlement_Association__c>>();   
            
            For(CEP_Entitlement_Association__c eAss : [SELECT Id,CEP_Product_Mappings__c,CEP_Entitlement_Configuration__r.CEP_Multiplier__c,
                CEP_Entitlement_Configuration__r.CEP_isHardware__c,CEP_Entitlement_Configuration__r.CEP_Configuration_Type__c,
                CEP_Entitlement_Configuration__r.CEP_Country__c,CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c,
                CEP_Entitlement_Configuration__r.CEP_Duration__c,CEP_Entitlement_Configuration__r.CEP_Gearhead_Contract__c,
                CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c,CEP_Entitlement_Configuration__r.CEP_Region__c,
                CEP_Entitlement_Configuration__r.CEP_Term_Days__c,CEP_Entitlement_Configuration__r.name,
                CEP_Entitlement_Configuration__r.CEP_hwDays__c,
                CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c,CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c,
                CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c, CEP_Entitlement_Configuration__r.CEP_psDays__c,
                CEP_Entitlement_Configuration__r.CEP_acDays__c
                FROM CEP_Entitlement_Association__c 
                WHERE  CEP_Product_Mappings__c IN :productIdSet 
                AND CEP_Entitlement_Configuration__r.For_Refurbished__c =  FALSE
                AND (CEP_Entitlement_Configuration__r.CEP_Configuration_Type__c = 'Warranty' OR 
                     CEP_Entitlement_Configuration__r.CEP_Configuration_Type__c = 'Entitlement') AND 
                CreatedDate>2014-04-01T13:48:00.000+0000]){
                
                If(EntitlementAssocMap.containskey(eAss.CEP_Product_Mappings__c))
                    EntitlementAssocMap.get(eAss.CEP_Product_Mappings__c).add(eAss);
                else
                    EntitlementAssocMap.put(eAss.CEP_Product_Mappings__c,new List<CEP_Entitlement_Association__c>{eAss});    
                
            }    
            if(accIdSet.size() > 0){//Added for meural
                for (aggregateResult conAgg : [select max(CEP_End_Date__c) maxEndDate,accountId from contract where CEP_Entitlement_Configuration__r.CEP_Contract_Type__c ='Meural' and CEP_Status__c = 'Activated' and Accountid in :accIdSet and CEP_End_Date__c != null group by accountId ]){
                    meuralConMap.put((string)conAgg.get('AccountId'),(Date)conAgg.get('maxEndDate'));
                }                
            } 
            if(proIdSet.size() > 0){//Added for meural
                list<product2> MeuralProducts = [select id,name from product2 where Product_Line__c  in:CEP_Meural_Product_Line__c.getAll().keyset() and id in:proIdSet];
                proIdSet = new set<string>();
                if(MeuralProducts.size() > 0){
                    for(product2 productObj : MeuralProducts){
                        proIdSet.add(productObj.id);
                    }
                }
            }    
            try{
                system.debug('Assoc Map**** '+EntitlementAssocMap);
                System.debug('Asset Size==>'+assetList.size());
                System.debug('EntitlementAssocMap Size==>'+EntitlementAssocMap.size());
                for(Asset ast : assetList){                    
                    System.debug('CEP_Entitlements_Created__c field used - ast.CEP_Entitlements_Created__c' + ast.CEP_Entitlements_Created__c);        
                    System.debug('EntitlementAssocMap' + EntitlementAssocMap);                
                    if((!EntitlementAssocMap.isEmpty() && !ast.CEP_Entitlements_Created__c) || (entitlementOnCountryChange && !EntitlementAssocMap.isEmpty())){
                        System.debug('Inside if**');
                        for(CEP_Entitlement_Association__c assoc : EntitlementAssocMap.get(ast.CEP_Product_Map__c)){
                            System.debug('assoc.id***'+assoc.id);
                            System.debug('ast ID***'+ast.id);
                            checker = false;
                            if(assoc.CEP_Product_Mappings__c == ast.CEP_Product_Map__c && (String.isBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Country__c)|| (String.isBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Region__c)) 
                                                                                           && assoc.CEP_Entitlement_Configuration__r.Name.contains('Global')) || 
                               ((String.IsNotBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Country__c) && 
                                 assoc.CEP_Entitlement_Configuration__r.CEP_Country__c.contains(ast.CEP_Country__c)) || 
                                (String.IsNotBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Region__c) && 
                                 assoc.CEP_Entitlement_Configuration__r.CEP_Region__c.contains(ast.CEP_Region__c)))){
                                     system.debug('inside prod mapping*** '+assoc);
                                     if((String.IsNotBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Country__c) && assoc.CEP_Entitlement_Configuration__r.CEP_Country__c.contains(ast.CEP_Country__c))){
                                         ast.CEP_Entitlements_Created__c = TRUE;
                                         checker = true;
                                     }
                                     else if((String.IsNotBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Region__c) && assoc.CEP_Entitlement_Configuration__r.CEP_Region__c.contains(ast.CEP_Region__c))){
                                         ast.CEP_Entitlements_Created__c = TRUE;   
                                         checker = true;
                                     }
                                     else if((String.isBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Country__c)) && (String.isBlank(assoc.CEP_Entitlement_Configuration__r.CEP_Region__c))){
                                         ast.CEP_Entitlements_Created__c = TRUE;   
                                         checker = true;
                                     }
                                     assetupdateSet.add(ast.Id);
                                     date meuralConEndDate;//Added for meural
                                     if(proIdSet.contains(ast.product2id) && meuralConMap.containskey(ast.AccountId)){//will all serial number starts with MEU
                                         meuralConEndDate = meuralConMap.get(ast.AccountId);
                                         integer daysDiff = (ast.PurchaseDate).daysbetween(meuralConEndDate);
                                         if(daysDiff < 90)
                                             meuralConEndDate = meuralConEndDate.addDays(daysDiff);                                                
                                     }     
                                     if(ast.Purchasedate != null && assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c != null
                                        &&  assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c != null && ast.Purchasedate >= assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c
                                        && ast.Purchasedate <= assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c && checker){
                                            //entitlementWithDateList.clear();
                                            system.debug('clearing with date list*** '+entitlementWithDateList);
                                            system.debug(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c +'WithDate--hwdays');
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c > 0){
                                                Entitlement HardWareEnt = new Entitlement();
                                                HardWareEnt.AccountId = ast.AccountId;
                                                HardWareEnt.AssetId = ast.Id;
                                                HardWareEnt.StartDate = ast.PurchaseDate;
                                                HardWareEnt.name = Label.CEP_Hardware_Warranty;
                                                System.debug(' hardware entl end date assignment *** ' + HardWareEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c) );
                                                HardWareEnt.EndDate = HardWareEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c);
                                                if(assoc.CEP_Entitlement_Configuration__r.CEP_isHardware__c)
                                                    HardWareEnt.CEP_isHardware__c = TRUE;
                                                entitlementWithDateList.add(HardWareEnt);
                                            } 
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c > 0){   
                                                system.debug('WithDate--chatDays'); 
                                                system.debug('chatDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);                                                       
                                                    Entitlement Chatent = new Entitlement();
                                                    Chatent.AccountId = ast.AccountId;
                                                    Chatent.AssetId = ast.Id;
                                                    Chatent.StartDate = ast.PurchaseDate;
                                                    Chatent.name = Label.CEP_Call_Support;
                                                     if(meuralConEndDate != null)
                                                        Chatent.EndDate = meuralConEndDate;
                                                     else
                                                        Chatent.EndDate = Chatent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);
                                                    entitlementWithDateList.add(Chatent);                                                
                                            }
                                            
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c > 0){          
                                                system.debug('WithDate--phoneDays ');
                                                system.debug('phoneDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c );                                            
                                                    Entitlement PhoneEnt = new Entitlement();
                                                    PhoneEnt.AccountId = ast.AccountId;
                                                    PhoneEnt.AssetId = ast.Id;
                                                    PhoneEnt.StartDate = ast.PurchaseDate;
                                                    PhoneEnt.name = Label.CEP_Phone_Support;
                                                     if(meuralConEndDate != null)
                                                        PhoneEnt.EndDate = meuralConEndDate;
                                                     else
                                                        PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);
                                                    entitlementWithDateList.add(PhoneEnt);
                                               
                                            }
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c > 0){          
                                                system.debug('WithDate--emailDays');
                                                system.debug('EmailDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);                                                   
                                                    Entitlement EmailEnt = new Entitlement();
                                                    EmailEnt.AccountId = ast.AccountId;
                                                    EmailEnt.AssetId = ast.Id;
                                                    EmailEnt.StartDate = ast.PurchaseDate;
                                                    EmailEnt.name = Label.CEP_Email_support;
                                                     if(meuralConEndDate != null)
                                                        EmailEnt.EndDate = meuralConEndDate;
                                                    else
                                                        EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);
                                                    entitlementWithDateList.add(EmailEnt);
                                                
                                            }
                                            system.debug(assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c +'WithDate--psDays');
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c > 0){
                                                Entitlement PowerSupplyEnt = new Entitlement();
                                                PowerSupplyEnt.AccountId = ast.AccountId;
                                                PowerSupplyEnt.AssetId = ast.Id;
                                                PowerSupplyEnt.StartDate = ast.PurchaseDate;
                                                PowerSupplyEnt.name = Label.CEP_Power_Supply_Warranty;
                                                PowerSupplyEnt.EndDate = PowerSupplyEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c);
                                                entitlementWithDateList.add(PowerSupplyEnt);
                                            }
                                            system.debug(assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c +'WithDate--acDays');
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c > 0){
                                                Entitlement AccessoryEnt = new Entitlement();
                                                AccessoryEnt.AccountId = ast.AccountId;
                                                AccessoryEnt.AssetId = ast.Id;
                                                AccessoryEnt.StartDate = ast.PurchaseDate;
                                                AccessoryEnt.name = Label.CEP_Accessory_Warranty;
                                                AccessoryEnt.EndDate = AccessoryEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c);
                                                entitlementWithDateList.add(AccessoryEnt);
                                            }
                                        }
                                     else if(assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c == null && assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c == null && checker){
                                         entitlementWithoutDateList.clear();
                                         system.debug('clraring with date list*** '+entitlementWithoutDateList);
                                         system.debug(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c +'WithoutDate--HwDays');
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c > 0){
                                             Entitlement HardWareEnt = new Entitlement();
                                             HardWareEnt.AccountId = ast.AccountId;
                                             HardWareEnt.AssetId = ast.Id;
                                             HardWareEnt.StartDate = ast.PurchaseDate;
                                             HardWareEnt.name = Label.CEP_Hardware_Warranty;
                                             HardWareEnt.EndDate = HardWareEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c);
                                             if(assoc.CEP_Entitlement_Configuration__r.CEP_isHardware__c)
                                                 HardWareEnt.CEP_isHardware__c = TRUE;
                                             entitlementWithoutDateList.add(HardWareEnt);
                                         }                                 
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c > 0){   
                                             system.debug('WithoutDate--Chatdays');
                                             system.debug('Chatdays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);                    
                                                Entitlement Chatent = new Entitlement();
                                                 Chatent.AccountId = ast.AccountId;
                                                 Chatent.AssetId = ast.Id;
                                                 Chatent.StartDate = ast.PurchaseDate;
                                                 Chatent.name = Label.CEP_Call_Support;
                                                 if(meuralConEndDate != null)
                                                    Chatent.EndDate = meuralConEndDate;
                                                 else
                                                    Chatent.EndDate = Chatent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);
                                                 entitlementWithoutDateList.add(Chatent);
                                             
                                         }
                                         
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c > 0){          
                                             system.debug('WithDate--phoneDays ');
                                             system.debug('phoneDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);                                              
                                                 Entitlement PhoneEnt = new Entitlement();
                                                 PhoneEnt.AccountId = ast.AccountId;
                                                 PhoneEnt.AssetId = ast.Id;
                                                 PhoneEnt.StartDate = ast.PurchaseDate;
                                                 PhoneEnt.name = Label.CEP_Phone_Support;
                                                 if(meuralConEndDate != null)
                                                    PhoneEnt.EndDate = meuralConEndDate;
                                                 else
                                                    PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);
                                                 entitlementWithoutDateList.add(PhoneEnt);
                                         }
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c > 0){          
                                             system.debug('WithDate--emailDays');
                                             system.debug('EmailDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);                                                          
                                                 Entitlement EmailEnt = new Entitlement();
                                                 EmailEnt.AccountId = ast.AccountId;
                                                 EmailEnt.AssetId = ast.Id;
                                                 EmailEnt.StartDate = ast.PurchaseDate;
                                                 EmailEnt.name = Label.CEP_Email_support;
                                                 if(meuralConEndDate != null)
                                                    EmailEnt.EndDate = meuralConEndDate;
                                                 else
                                                    EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);
                                                 entitlementWithoutDateList.add(EmailEnt);                                             
                                         }
                                         
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c > 0){
                                             Entitlement PowerSupplyEnt = new Entitlement();
                                             PowerSupplyEnt.AccountId = ast.AccountId;
                                             PowerSupplyEnt.AssetId = ast.Id;
                                             PowerSupplyEnt.StartDate = ast.PurchaseDate;
                                             PowerSupplyEnt.name = Label.CEP_Power_Supply_Warranty;
                                             PowerSupplyEnt.EndDate = PowerSupplyEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c);
                                             entitlementWithoutDateList.add(PowerSupplyEnt);
                                         }
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c > 0){
                                             Entitlement AccessoryEnt = new Entitlement();
                                             AccessoryEnt.AccountId = ast.AccountId;
                                             AccessoryEnt.AssetId = ast.Id;
                                             AccessoryEnt.StartDate = ast.PurchaseDate;
                                             AccessoryEnt.name = Label.CEP_Accessory_Warranty;
                                             AccessoryEnt.EndDate = AccessoryEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c);
                                             entitlementWithoutDateList.add(AccessoryEnt);
                                         }
                                     }
                                     
                                 }
                        }
                    }
                    
                }
                system.debug('entitlementWithDateList Size==>'+entitlementWithDateList.size());
                system.debug('dates List**** '+entitlementWithDateList);
                system.debug('without dates List**** '+entitlementWithoutDateList);
                if(!assetupdateSet.isEmpty()){
                    system.debug('condition true');
                    if(!entitlementWithDateList.isEmpty())
                        insert entitlementWithDateList;
                    else if(!entitlementWithoutDateList.isEmpty())
                        insert entitlementWithoutDateList;
                    for(Asset ast : assetList){
                        if(assetupdateSet.contains(ast.Id))
                            system.debug('condtion true'+ ast.CEP_Entitlements_Created__c );
                        ast.CEP_Entitlements_Created__c = true;
                    }
                } 
            }
            catch(Exception e){
                system.debug('Error in saving&&&& '+e.getMessage());
              
            }
        }
        
    }   */
 /******************************************************************************************
* Method Name      :     rollupSummaryAfterInsert
* Create By        :     Naveen VM
* Create Date      :     01/23/2018
* Description      :     Calculate Annual Revenue while inserting Asset to Account
* ***********************************************************************/
    public Static void rollupSummary(List<Asset> VLstAsset,map<Id,asset> triggerOld){
                   
        set<String> vAccId = new set<String>();
        list<Account> vLstAccounts = new list<Account>();
        Account vAcccount;  
        for(Asset vAsset : VLstAsset){
            if(vAsset.AccountId != null){
                vAccId.add(vAsset.AccountId);
            }
        }                
        
        try{
            for(AggregateResult vAggr : [SELECT  SUM(CEP_Product_Unit_Cost__c) sumAssetCost,AccountId 
                                         FROM Asset WHERE AccountId In :vAccId GROUP BY AccountId]) { 
                string accId = (string) vAggr.get('AccountId');
                decimal sumOfChild = (decimal) vAggr.get('sumAssetCost');                
                vAcccount = new Account(Id = accId , AnnualRevenue = sumOfChild);
                vLstAccounts.add(vAcccount);
            }
            if(vLstAccounts.size()>0){
                update vLstAccounts;
            }                       
        }
        catch(Exception e) {
            system.debug('Error in saving&&&& '+e.getMessage());
        }         
    }

/******************************************************************************************
* Method Name      :     createEntitlementRefurbishedProduct
* Create By        :     Naveen VM
* Create Date      :     01/30/2018
* Description      :     Create Entitlement for Refurbished Product
* ***********************************************************************/     
   /* Commented by Gokul CEP - 4834  
   Public static void createEntitlementRefurbishedProduct (List<Asset> assetList,Boolean entitlementOnCountryChange){
        system.debug('test inside');
        set<string> productIdSet = new Set<string>();
        list<Entitlement> entitlementWithoutDateList = new list<Entitlement>();
        list<Entitlement> entitlementWithDateList = new list<Entitlement>();
        list<Entitlement> entitlementList = new list<Entitlement>();   /*      
   /*     for(asset astNew :assetList){        
            if(String.isNotBlank(astNew.CEP_Product_Map__c) && astNew.Status == 'Active'){
                system.debug('Is getting product mapping');
                productIdSet.add(astNew.CEP_Product_Map__c);
            }
        } */       /* Commented by Gokul CEP - 4834            
        map<String,CEP_Entitlement_Association__c> EntitlementAssocMap = new map<String,CEP_Entitlement_Association__c>([SELECT Id,CEP_Product_Mappings__c,CEP_Entitlement_Configuration__r.CEP_Multiplier__c,CEP_Entitlement_Configuration__r.CEP_isHardware__c,
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_Configuration_Type__c,CEP_Entitlement_Configuration__r.CEP_Country__c,CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c,
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_Duration__c,CEP_Entitlement_Configuration__r.CEP_Gearhead_Contract__c,CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c,
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_Region__c,CEP_Entitlement_Configuration__r.CEP_Term_Days__c,CEP_Entitlement_Configuration__r.name,
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_hwDays__c,//CEP_Entitlement_Configuration__r.CEP_swDays__c,
                                                                                                                         //Added By Yuvaraj - 4812
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c,CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c,
                                                                                                                         CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c,CEP_Entitlement_Configuration__r.CEP_psDays__c,          CEP_Entitlement_Configuration__r.CEP_acDays__c
                                                                                                                         FROM CEP_Entitlement_Association__c WHERE CEP_Entitlement_Configuration__r.For_Refurbished__c =  TRUE AND CEP_Entitlement_Configuration__r.Name LIKE '%Refurbished%' AND CreatedDate>2014-04-01T13:48:00.000+0000] );
        try{
            Set<Id> assetIdSet= new Set<Id>{};
                for(Asset ast : assetList){
                    system.debug('======='+ast.CEP_Entitlements_Created__c);
                    
                    if((!EntitlementAssocMap.isEmpty() && (ast.CEP_Asset_Type__c =='Refurbished – with SN' || 
                                                           ast.CEP_Asset_Type__c =='Refurbished – without SN' ) && ast.Status == 'Active' && 
                        ast.CEP_Legacy_Asset_ID__c == null && !ast.CEP_Entitlements_Created__c) || 
                       (entitlementOnCountryChange && !EntitlementAssocMap.isEmpty() && 
                        (ast.CEP_Asset_Type__c =='Refurbished – with SN' || ast.CEP_Asset_Type__c =='Refurbished – without SN' ) 
                        && ast.Status == 'Active' && ast.CEP_Legacy_Asset_ID__c == null) ){
                            for(CEP_Entitlement_Association__c assoc : EntitlementAssocMap.values()){
                                if(assoc.CEP_Entitlement_Configuration__r.Name.contains('Refurbished')){
                                    system.debug('inside prod mapping refurb*** '+assoc);
                                    system.debug('asset purchase date==='+ast.Purchasedate );
                                    system.debug('startdate==='+assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c );
                                    system.debug('enddate==='+assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c );
                                    if(ast.Purchasedate != null && assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c != null
                                       &&  assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c != null && ast.Purchasedate >= assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c
                                       && ast.Purchasedate <= assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c){
                                           system.debug('Is going into if');                       
                                           entitlementWithDateList.clear();
                                           system.debug('hwdays' +assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c );
                                           if(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c > 0){
                                               Entitlement HardWareEnt = new Entitlement();
                                               HardWareEnt.AccountId = ast.AccountId;
                                               HardWareEnt.AssetId = ast.Id;
                                               HardWareEnt.StartDate = ast.PurchaseDate;
                                               HardWareEnt.name = Label.CEP_Hardware_Warranty;
                                               HardWareEnt.EndDate = HardWareEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c);
                                               if(assoc.CEP_Entitlement_Configuration__r.CEP_isHardware__c)
                                                   HardWareEnt.CEP_isHardware__c = TRUE;
                                               entitlementWithDateList.add(HardWareEnt);
                                           }
                                           /*   system.debug('swdays' +assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
if(assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c > 0){
Entitlement Callent = new Entitlement();
Callent.AccountId = ast.AccountId;
Callent.AssetId = ast.Id;
Callent.StartDate = ast.PurchaseDate;
Callent.name = Label.CEP_Call_Support;
Callent.EndDate = Callent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithDateList.add(Callent);

Entitlement PhoneEnt = new Entitlement();
PhoneEnt.AccountId = ast.AccountId;
PhoneEnt.AssetId = ast.Id;
PhoneEnt.StartDate = ast.PurchaseDate;
PhoneEnt.name = Label.CEP_Phone_Support;
PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithDateList.add(PhoneEnt);

Entitlement EmailEnt = new Entitlement();
EmailEnt.AccountId = ast.AccountId;
EmailEnt.AssetId = ast.Id;
EmailEnt.StartDate = ast.PurchaseDate;
EmailEnt.name = Label.CEP_Email_support;
EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithDateList.add(EmailEnt);

}*//* Commented by Gokul CEP - 4834  
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c > 0){   
                                             system.debug('WithDate--Ref--Chatdays');
                                             system.debug('Chatdays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);                     
                                                 Entitlement Chatent = new Entitlement();
                                                 Chatent.AccountId = ast.AccountId;
                                                 Chatent.AssetId = ast.Id;
                                                 Chatent.StartDate = ast.PurchaseDate;
                                                 Chatent.name = Label.CEP_Call_Support;
                                                 Chatent.EndDate = Chatent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);
                                                 entitlementWithDateList.add(Chatent);                                           
                                         }
                                         
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c > 0){          
                                             system.debug('WithDate--Ref--phoneDays');
                                             system.debug('phoneDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);                                              
                                                Entitlement PhoneEnt = new Entitlement();
                                                 PhoneEnt.AccountId = ast.AccountId;
                                                 PhoneEnt.AssetId = ast.Id;
                                                 PhoneEnt.StartDate = ast.PurchaseDate;
                                                 PhoneEnt.name = Label.CEP_Phone_Support;
                                                 PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);
                                                 entitlementWithDateList.add(PhoneEnt);
                                            
                                         }
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c > 0){          
                                            system.debug('WithDate--Ref--EmailDays');
                                             system.debug('EmailDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);                                                         
                                                 Entitlement EmailEnt = new Entitlement();
                                                 EmailEnt.AccountId = ast.AccountId;
                                                 EmailEnt.AssetId = ast.Id;
                                                 EmailEnt.StartDate = ast.PurchaseDate;
                                                 EmailEnt.name = Label.CEP_Email_support;
                                                 EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);
                                                 entitlementWithDateList.add(EmailEnt);
                                            
                                         }
                                        
                                           if(assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c > 0){
                                               Entitlement PowerSupplyEnt = new Entitlement();
                                               PowerSupplyEnt.AccountId = ast.AccountId;
                                               PowerSupplyEnt.AssetId = ast.Id;
                                               PowerSupplyEnt.StartDate = ast.PurchaseDate;
                                               PowerSupplyEnt.name = Label.CEP_Power_Supply_Warranty;
                                               PowerSupplyEnt.EndDate = PowerSupplyEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c);
                                               entitlementWithDateList.add(PowerSupplyEnt);
                                           }
                                           if(assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c > 0){
                                               Entitlement AccessoryEnt = new Entitlement();
                                               AccessoryEnt.AccountId = ast.AccountId;
                                               AccessoryEnt.AssetId = ast.Id;
                                               AccessoryEnt.StartDate = ast.PurchaseDate;
                                               AccessoryEnt.name = Label.CEP_Accessory_Warranty;
                                               AccessoryEnt.EndDate = AccessoryEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c);
                                               entitlementWithDateList.add(AccessoryEnt);
                                           }
                                           assetIdSet.add(ast.id);
                                           //           ast.CEP_Entitlements_Created__c=TRUE;
                                           
                                       }
                                    else if(assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_Start_Date__c == null && assoc.CEP_Entitlement_Configuration__r.CEP_Purchase_End_Date__c == null){
                                        system.debug('Is going into else');
                                        entitlementWithoutDateList.clear();
                                        if(assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c > 0){
                                            Entitlement HardWareEnt = new Entitlement();
                                            HardWareEnt.AccountId = ast.AccountId;
                                            HardWareEnt.AssetId = ast.Id;
                                            HardWareEnt.StartDate = ast.PurchaseDate;
                                            HardWareEnt.name = Label.CEP_Hardware_Warranty;
                                            HardWareEnt.EndDate = HardWareEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_hwDays__c);
                                            if(assoc.CEP_Entitlement_Configuration__r.CEP_isHardware__c)
                                                HardWareEnt.CEP_isHardware__c = TRUE;
                                            entitlementWithoutDateList.add(HardWareEnt);
                                        }
                                        /*
if(assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c > 0){
Entitlement Callent = new Entitlement();
Callent.AccountId = ast.AccountId;
Callent.AssetId = ast.Id;
Callent.StartDate = ast.PurchaseDate;
Callent.name = Label.CEP_Call_Support;
Callent.EndDate = Callent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithoutDateList.add(Callent);

Entitlement PhoneEnt = new Entitlement();
PhoneEnt.AccountId = ast.AccountId;
PhoneEnt.AssetId = ast.Id;
PhoneEnt.StartDate = ast.PurchaseDate;
PhoneEnt.name = Label.CEP_Phone_Support;
PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithoutDateList.add(PhoneEnt);

Entitlement EmailEnt = new Entitlement();
EmailEnt.AccountId = ast.AccountId;
EmailEnt.AssetId = ast.Id;
EmailEnt.StartDate = ast.PurchaseDate;
EmailEnt.name = Label.CEP_Email_support;
EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_swDays__c);
entitlementWithoutDateList.add(EmailEnt);

}*//* Commented by Gokul CEP - 4834  
                                       if(assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c > 0){   
                                             system.debug('WithoutDate--Ref--Chatdays');
                                             system.debug('Chatdays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);                 
                                                 Entitlement Chatent = new Entitlement();
                                                 Chatent.AccountId = ast.AccountId;
                                                 Chatent.AssetId = ast.Id;
                                                 Chatent.StartDate = ast.PurchaseDate;
                                                 Chatent.name = Label.CEP_Call_Support;
                                                 Chatent.EndDate = Chatent.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Chat_Support_Days__c);
                                                 entitlementWithoutDateList.add(Chatent);                                           
                                         }
                                         
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c > 0){          
                                             system.debug('WithoutDate--Ref--phoneDays');
                                             system.debug('phoneDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);                                                
                                                 Entitlement PhoneEnt = new Entitlement();
                                                 PhoneEnt.AccountId = ast.AccountId;
                                                 PhoneEnt.AssetId = ast.Id;
                                                 PhoneEnt.StartDate = ast.PurchaseDate;
                                                 PhoneEnt.name = Label.CEP_Phone_Support;
                                                 PhoneEnt.EndDate = PhoneEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Phone_Support_Days__c);
                                                 entitlementWithoutDateList.add(PhoneEnt);
                                           
                                         }
                                         if(assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c != null && assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c > 0){          
                                             system.debug('WithoutDate--Ref--EmailDays');
                                             system.debug('EmailDays'+ assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);                                                          
                                                 Entitlement EmailEnt = new Entitlement();
                                                 EmailEnt.AccountId = ast.AccountId;
                                                 EmailEnt.AssetId = ast.Id;
                                                 EmailEnt.StartDate = ast.PurchaseDate;
                                                 EmailEnt.name = Label.CEP_Email_support;
                                                 EmailEnt.EndDate = EmailEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_Email_Support_Days__c);
                                                 entitlementWithoutDateList.add(EmailEnt);
                                            
                                         }
                                        
                                        
                                        if(assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c > 0){
                                            Entitlement PowerSupplyEnt = new Entitlement();
                                            PowerSupplyEnt.AccountId = ast.AccountId;
                                            PowerSupplyEnt.AssetId = ast.Id;
                                            PowerSupplyEnt.StartDate = ast.PurchaseDate;
                                            PowerSupplyEnt.name = Label.CEP_Power_Supply_Warranty;
                                            PowerSupplyEnt.EndDate = PowerSupplyEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_psDays__c);
                                            entitlementWithoutDateList.add(PowerSupplyEnt);
                                        }
                                        if(assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c > 0){
                                            Entitlement AccessoryEnt = new Entitlement();
                                            AccessoryEnt.AccountId = ast.AccountId;
                                            AccessoryEnt.AssetId = ast.Id;
                                            AccessoryEnt.StartDate = ast.PurchaseDate;
                                            AccessoryEnt.name = Label.CEP_Accessory_Warranty;
                                            AccessoryEnt.EndDate = AccessoryEnt.StartDate.addDays((Integer)assoc.CEP_Entitlement_Configuration__r.CEP_acDays__c);
                                            entitlementWithoutDateList.add(AccessoryEnt);
                                        }
                                        //ast.CEP_Entitlements_Created__c=TRUE;
                                        assetIdSet.add(ast.id);
                                    }
                                }
                            }
                        }
                }
            
             
            
            system.debug('dates List refurb**** '+entitlementWithDateList);
            system.debug('without dates List**** '+entitlementWithoutDateList);
            if(!entitlementWithDateList.isEmpty())
                insert entitlementWithDateList;
            else if(!entitlementWithoutDateList.isEmpty())
                insert entitlementWithoutDateList;
            List<Asset> assList=[Select Id,CEP_Entitlements_Created__c from asset where id in:assetIdSet];
            for(integer i=0;i<assList.size();i++){
               assList[i].CEP_Entitlements_Created__c=true;
            }
            update assList;
        }
        catch(Exception e) {
            system.debug('Error in saving&&&& '+e.getMessage());
        }     
        
      
    }*/
    
/******************************************************************************************
* Method Name      :     updateOrderLineItem
* Create By        :     Jagan
* Create Date      :     07/09/2019
* Description      :     Update order line with asset - Guest order flow/Gift order flow/logged in flow...
* ***********************************************************************/  

Public static void updateOrderLineItem(List<Asset> assetList){    
    map<String,Id> mapSNWithAssetId = new map<String,Id>();
    List<Order_Line_Item__c> lstOliToBeUpdated = new List<Order_Line_Item__c>();
 
    for(asset ast :assetList){   
        if(ast.SerialNumber !=NULL){             
            mapSNWithAssetId.put(ast.SerialNumber,ast.id);   
        }       
    }
    System.debug('mapSNWithAssetId***' + mapSNWithAssetId);
   
    //List<Order_Line_Item__c> lstOli = [Select id,CEP_Serial_Number__c,Asset__c,CEP_Status__c from Order_Line_Item__c where Asset__c =NULL AND CEP_Serial_Number__c IN:mapSNWithAssetId.keyset() AND (CEP_Order__r.CEP_IsGuestOrder__c = TRUE OR CEP_Order__r.CEP_IsGiftOrder__c = TRUE) ];
    
    List<Order_Line_Item__c> lstOli = [Select id,CEP_Serial_Number__c,Asset__c,CEP_Status__c from Order_Line_Item__c where Asset__c =NULL AND CEP_Serial_Number__c IN:mapSNWithAssetId.keyset() ];
    System.debug('Order line item to be updated ***' + lstOli);
    for(Order_Line_Item__c oli: lstOli){
        oli.Asset__c = mapSNWithAssetId.get(oli.CEP_Serial_Number__c);
        oli.CEP_Status__c = 'Processed-success';
        lstOliToBeUpdated.add(oli);
    }
    if(!lstOliToBeUpdated.isEmpty()){     
         //update lstOliToBeUpdated;                     //It is advisable to go with database.update since there are chances of multiple order line items to be updated in single time...
        Database.SaveResult[] srList = Database.update(lstOliToBeUpdated, false);
        List<String> errorRecords = new List<String>();
        List<CEP_DreamFactory_Exception__c> errorRecordsLst = new List<CEP_DreamFactory_Exception__c>();   
        Integer i = 0;           
        for (Database.SaveResult sr : srList) {            
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {                    
                    System.debug('Error record' + sr.getId() + ':' + err.getStatusCode() + ': ' + err.getMessage() +'<br/>');                    
                    CEP_DreamFactory_Exception__c dreamFactory = new CEP_DreamFactory_Exception__c();
                    dreamFactory.Exception__c = 'Exception during order line item update:'+ sr +'Error record' + sr.getId() + ':' + err.getStatusCode() + ': ' + err.getMessage() +'<br/>' ;
                    dreamFactory.Source__c = 'CEP_AssetHelper_updateOrderLineItem()';
                    dreamFactory.CEP_Order_Line_Item__c = sr.getId();
                    errorRecordsLst.add(dreamFactory);                    
                }
            }else{
                System.debug('Success record information **' + sr);
                System.debug('Success record getid() **' + sr.getId());                 
            }  
            i++;        
        }
        insert errorRecordsLst;
        System.debug('Inserted exception record for failure contract creation ***' + errorRecordsLst); 
   }    
}    

    
/******************************************************************************************
* Method Name      :     assetTransferBeforeUpdate
* Create By        :     Naveen VM
* Create Date      :     01/30/2018
* Description      :     Transfer Asset, Case and Entitlement on change of Account
* ***********************************************************************/       
 Public static void assetTransferBeforeUpdate(List<Asset> assetList, map<Id,asset> triggerOld){
        
        set<string> productIdSet = new Set<string>();
		 //CEP-6033 - logic moved to after update
		/*list<Asset> assetsToBeUpdated = new list<Asset>();        
        map<id,string> newAssetMap = new map<id,string>();
        list<Case> casesForUpdate = new List<Case>(); 
        Set<id> asstTrfId = new Set<id>();// Added by Gokul CEP-CEP-5898
        Commented by Gokul CEP - 4834  list<Entitlement> entitlementForUpdate = new list<Entitlement>(); 
        list<Contract> contractForUpdate = new list<Contract>();*/
        
      for(asset ast :assetList){
            if(ast.accountid != triggerOld.get(ast.id).accountid && String.isNotBlank(ast.SerialNumber) && ast.Status == 'Active'){
                    if(ast.Product2Id != null && ast.CEP_Asset_Type__c != 'RMA'){
                        productIdSet.add(ast.Product2Id);
                    }
                    //asstTrfId.add(ast.id);// Added by Gokul CEP-CEP-5898 //CEP-6033 used map instead
                }
        }
     Map<String,CEP_RefurbishedSerialNumber__c > refurbishedMap;
     if( productIdSet != NULL && !productIdSet.isEmpty()){
        refurbishedMap = new Map<String,CEP_RefurbishedSerialNumber__c >([SELECT ID,Name,CEP_Serial_Number__c,CEP_Used_Serial_Number__c FROM CEP_RefurbishedSerialNumber__c WHERE  
                                                         CEP_Serial_Number__c IN :productIdSet]);         
     }

 
        for(Asset ast : assetList){
               if( !ast.CEP_Asset_Swapped__c && ast.AccountId != triggerOld.get(ast.id).AccountID) {   
                     /* if(ast.SerialNumber != null){
          for(CEP_RefurbishedSerialNumber__c refurbList : [SELECT ID,Name,CEP_Serial_Number__c,CEP_Used_Serial_Number__c FROM CEP_RefurbishedSerialNumber__c WHERE CEP_Serial_Number__c<> NULL 
                                                        AND CEP_Serial_Number__c =: ast.SerialNumber]){
           refurbList.CEP_Used_Serial_Number__c = FALSE;                                                       
                                                   }                   
                }*/
                if(refurbishedMap != null){
                    for(CEP_RefurbishedSerialNumber__c refurb: refurbishedMap.values()){
                        refurb.CEP_Used_Serial_Number__c = FALSE;
                    }
                }
				 //CEP-6033 - logic moved to after update
               /* ast.CTS_Product_Registration_ID__c = null;
                Asset tempIns = ast.clone(true,false,false,false);
                tempIns.CEP_Legacy_Asset_ID__c = ast.id;
                tempIns.id = null;
                assetsToBeUpdated.add(tempIns); */
                
				newastAccountmap.put(ast.id,ast.AccountId); 
                ast.Status = 'InActive';
                ast.CEP_Asset_Swapped__c = True;
                ast.AccountId = triggerOld.get(ast.id).AccountID; 
                ast.CEP_Unique_Serial_Number__c = ast.SerialNumber+ast.id;                                           
            } 
            else if (ast.CEP_Asset_Swapped__c && ast.AccountId != triggerOld.get(ast.id).AccountID && !test.isRunningTest()) {
                ast.addError('Asset Cannot be Transferred');
            }
        }
		 //CEP-6033 - logic moved to after update
       /*if(assetsToBeUpdated.size()>0){
            insert assetsToBeUpdated;
        }
        
        If(!asstTrfId.isEmpty()){ // Added by Gokul CEP-CEP-5898
     for(Asset ast : assetsToBeUpdated){
            if(ast.CEP_Legacy_Asset_ID__c != null) {
                newAssetMap.put(ast.CEP_Legacy_Asset_ID__c,ast.id +'-'+ast.AccountId);
            }
        }
       
            for(case caseObj : [SELECT id,AssetId, AccountId from Case where AssetId IN : asstTrfId]) { // Changed by Gokul CEP-CEP-5898
            if(newAssetMap.containskey(caseObj.AssetId)) {
                casesForUpdate.add(new Case(id= caseObj.id, AssetId = id.valueof(newAssetMap.get(caseObj.AssetId).split('-')[0]),
                                           AccountId= id.valueof(newAssetMap.get(caseObj.AssetId).split('-')[1])));
            }
        }
       if(casesForUpdate.size()>0){
             update casesForUpdate;
        }
         Commented by Gokul CEP - 4834              
        for(Entitlement eachEntitlement: [select id,AssetId,AccountId from Entitlement where AssetId IN : triggerOld.keySet()]){
            if(newAssetMap.containskey(eachEntitlement.AssetId)){
                entitlementForUpdate.add(new Entitlement(id= eachEntitlement.Id, AssetId= newAssetMap.get(eachEntitlement.AssetId).split('-')[0],
                                                        AccountId= id.valueof(newAssetMap.get(eachEntitlement.AssetId).split('-')[1])));
                                     
            }
        }
        try{
            if(entitlementForUpdate.size()>0){
                update entitlementForUpdate;
            }
        }
        catch(Exception e){
        }
        
        
            for(Contract eachContract : [select id,CEP_Asset__c,AccountId from Contract where CEP_Asset__c IN:asstTrfId]){ // Changed by Gokul CEP-CEP-5898
         if(newAssetMap.containskey(eachContract.CEP_Asset__c)){
             contractForUpdate.add(new Contract(id=eachContract.Id, CEP_Asset__c= newAssetMap.get(eachContract.CEP_Asset__c).split('-')[0],
                                               AccountId= id.valueof(newAssetMap.get(eachContract.CEP_Asset__c).split('-')[1])));
         }
     }
     try{
            if(contractForUpdate.size()>0){
                update contractForUpdate;
            }
        }
        catch(Exception e){
        }*/    
    }
	Public static void assetTransferafterUpdate(List<Asset> assetList, map<Id,asset> triggerOld){  //CEP-6033
        map<id,string> newAssetMap = new map<id,string>();
        list<Asset> assetsToBeUpdated = new list<Asset>();
        list<Case> casesForUpdate = new List<Case>();  
        list<Contract> contractForUpdate = new list<Contract>();
        for(Asset ast : assetList){           
            if( !triggerOld.get(ast.id).CEP_Asset_Swapped__c && newastAccountmap.containsKey(ast.id)) { 
                Asset tempIns = ast.clone(true,false,false,false);
                tempIns.CTS_Product_Registration_ID__c = null;
                tempIns.CEP_Legacy_Asset_ID__c = ast.id;
                tempIns.Status = 'Active';
                tempIns.CEP_Asset_Swapped__c = false;                
                tempIns.AccountId = newastAccountmap.get(ast.id);               
                tempIns.id = null;
                tempIns.CEP_Unique_Serial_Number__c = ast.SerialNumber;
                assetsToBeUpdated.add(tempIns); 
            }
        }    
		if(!newastAccountmap.isEmpty()){
			if(assetsToBeUpdated.size()>0){
				insert assetsToBeUpdated;
			}
			for(Asset ast : assetsToBeUpdated){
				if(ast.CEP_Legacy_Asset_ID__c != null) {
					newAssetMap.put(ast.CEP_Legacy_Asset_ID__c,ast.id +'-'+ast.AccountId);
				}
			}        
			for(case caseObj : [SELECT id,AssetId, AccountId from Case where AssetId IN : triggerOld.keySet()]) {
				if(newAssetMap.containskey(caseObj.AssetId)) {
					casesForUpdate.add(new Case(id= caseObj.id, AssetId = id.valueof(newAssetMap.get(caseObj.AssetId).split('-')[0]),
												AccountId= id.valueof(newAssetMap.get(caseObj.AssetId).split('-')[1])));
				}
			}
			if(casesForUpdate.size()>0){
				update casesForUpdate;
			} 
			
			for(Contract eachContract : [select id,CEP_Asset__c,AccountId from Contract where CEP_Asset__c IN:triggerOld.keySet()]){
				if(newAssetMap.containskey(eachContract.CEP_Asset__c)){
					contractForUpdate.add(new Contract(id=eachContract.Id, CEP_Asset__c= newAssetMap.get(eachContract.CEP_Asset__c).split('-')[0],
													   AccountId= id.valueof(newAssetMap.get(eachContract.CEP_Asset__c).split('-')[1])));
				}
			}
			try{
				if(contractForUpdate.size()>0){
					update contractForUpdate;
				}
			}
			catch(Exception e){
			}   
			newastAccountmap.clear();
		}
    }
/******************************************************************************************
* Method Name      :     createAutoApplyContracts
* Create By        :     Nitesh Halliyal
* Create Date      :     02/23/2018
* Description      :     logic to create any auto apply contarcts on asset registration
* *****************************************************************************************/
    public static void createAutoApplyContracts(list<asset> triggerNew,Boolean entitlementOnCountryChange){
      System.debug('Inside createAutoApplyContracts flow***');  
        list<contract> contractList = new list<contract>();
        list<contract> updateContractList = new list<contract>();
        set<string> productIdSet = new Set<string>();
        list<Id> contractSet = new list<Id>();
        
        Date ContractstartDate;
        Date ContractendDate;  
        Date assetpurchaseDate;
        boolean createContract = false;
        
        for(asset ast :triggerNew){
            if(String.isNotBlank(ast.CEP_Product_Map__c) && ast.Status == 'Active' && String.isNotblank(ast.CEP_Asset_Type__c) && ast.CEP_Asset_Type__c == 'New')
                productIdSet.add(ast.CEP_Product_Map__c);
        }
       system.debug('prosetID ====>'+productIdSet); 
        map<String,CEP_Auto_Apply_Contracts__c> autpApplyContMap = new map<String,CEP_Auto_Apply_Contracts__c>([SELECT Id,CEP_Contract_Master__r.CEP_Special_Services__c,CEP_Contract_Master__c,CEP_Country__c,CEP_Region__c,CEP_Product_Mappings__c,CEP_Contract_Master__r.CEP_Multiplier__c,CEP_Contract_Master__r.CEP_Configuration_Type__c,
                                                                                                                CEP_Contract_Master__r.CEP_Duration__c,CEP_Contract_Master__r.CEP_Region__c,CEP_Contract_Master__r.Name,CEP_Contract_Master__r.CEP_Cost__c,CEP_Contract_Master__r.CEP_Country__c,
                                                                                                                CEP_Contract_Master__r.CurrencyIsoCode,CEP_Contract_Master__r.CEP_Type__c,CEP_Purchase_StartDate__c, CEP_Purchase_EndDate__c FROM CEP_Auto_Apply_Contracts__c
                                                                                                                WHERE CEP_Product_Mappings__c IN :productIdSet]);         /*added line by yuvaraj 01-31-19*/                                                                                            
                                                                                                                
    system.debug('autpApplyContMap ====>'+autpApplyContMap );      
    system.debug('entitlementOnCountryChange===>'+entitlementOnCountryChange);  
    system.debug('In Trigger.new ===>'+triggerNew);
                                                         
        for(asset ast :triggerNew){
            if((productIdSet.contains(ast.CEP_Product_Map__c) && !ast.CEP_Auto_Contarcts_Created__c) || (entitlementOnCountryChange && productIdSet.contains(ast.CEP_Product_Map__c))){
                system.debug('product mapping** '+ast.CEP_Product_Map__c);
                for(CEP_Auto_Apply_Contracts__c apply : autpApplyContMap.values()){
                /*Yuvaraj added on 01/31/2019 ***START*****/
                    createContract = false;
                    system.debug('Purchase Start date'+apply.CEP_Purchase_StartDate__c);
                    system.debug('Purchase End date'+apply.CEP_Purchase_EndDate__c );
                    system.debug('assetpurchaseDate '+ ast.PurchaseDate );
                    
                    assetpurchaseDate = date.valueof(ast.PurchaseDate);    
                    ContractstartDate = Date.valueOf(apply.CEP_Purchase_StartDate__c);
                    ContractendDate = Date.valueOf(apply.CEP_Purchase_EndDate__c);  
                    
                    if(ContractstartDate == NULL && ContractendDate == NULL){
                    createContract = TRUE;
                    system.debug('Inside 1st condition both dates are null');
                    }
                    
                    if(ContractstartDate != NULL &&  ContractendDate == NULL && assetpurchaseDate >= ContractstartDate){
                    createContract = TRUE;
                    system.debug('Inside 2nd condition start date is not null && asst date is greater than startdate ');
                    }
                    
                    if(ContractstartDate != NULL &&  ContractendDate != NULL && (assetpurchaseDate > = ContractstartDate && assetpurchaseDate <= ContractendDate)){
                    createContract = TRUE;
                    system.debug('Inside 3rd condition both date is not null && asst date is greater than/lesser than startdate ');
                    }
                    /*Yuvaraj end*****/
                    system.debug('product mapping2** '+apply.CEP_Product_Mappings__c);
                    system.debug('debug only'+apply.CEP_Region__c);
                    system.debug('debug only2'+apply.CEP_Country__c);
                    system.debug('debug only3'+apply.CEP_Contract_Master__c);
                    system.debug('debug only4'+apply.CEP_Contract_Master__r.CEP_Configuration_Type__c);
                    if(apply.CEP_Product_Mappings__c == ast.CEP_Product_Map__c && ((apply.CEP_Region__c!=null && ast.CEP_Region__c!=null && 
                       apply.CEP_Region__c.contains(ast.CEP_Region__c)) || (apply.CEP_Country__c!=null && ast.CEP_Country__c!=null &&
                       apply.CEP_Country__c.contains(ast.CEP_Country__c)) || (apply.CEP_Country__c==null && 
                       apply.CEP_Region__c==null)) && apply.CEP_Contract_Master__c!=null && 
                       apply.CEP_Contract_Master__r.CEP_Configuration_Type__c == 'Contract' &&
                       apply.CEP_Contract_Master__r.CEP_Special_Services__c ==NULL && createContract){   //Jagan added new line - 11/2/2018  /*Yuvaraj added new if condition - 01/31/2019*/
                        system.debug('inside if');
                        Contract cont = new Contract();
                        cont.Status = 'Draft';
                        cont.CEP_Status__c = 'Activated';
                        cont.AccountId = ast.AccountId;
                        cont.CEP_Asset__c = ast.Id;
                        cont.Name = apply.CEP_Contract_Master__r.Name;
                        cont.CEP_Entitlement_Configuration__c = apply.CEP_Contract_Master__c;
                        cont.CEP_Cost__c = apply.CEP_Contract_Master__r.CEP_Cost__c;
                        cont.CurrencyIsoCode = apply.CEP_Contract_Master__r.CurrencyIsoCode;
                        cont.StartDate = ast.PurchaseDate;
                        
                        if(apply.CEP_Contract_Master__r.CEP_Duration__c != null && apply.CEP_Contract_Master__r.CEP_Multiplier__c != null){
                            integer contractDays = (Integer.valueOf(apply.CEP_Contract_Master__r.CEP_Duration__c)*integer.valueOf(apply.CEP_Contract_Master__r.CEP_Multiplier__c));
                            cont.ContractTerm = 1;//adding junk value as this field is not being used but is mandatory
                            if(cont.startDate!=null)
                                cont.CEP_End_Date__c = cont.startDate.addDays(contractDays);
                        }
                        if(apply.CEP_Contract_Master__r.CEP_Type__c == 'RMA')
                            cont.CEP_Is_RMA_Auto_Apply_Contract__c = TRUE;
                        /*if(cont.Name.contains('Complimentary')){
                            cont.CEP_Is_RMA_Auto_Apply_Contract__c = TRUE;
                        }*/
                        
                        if(!entitlementOnCountryChange) // Added By Gokul
                        ast.CEP_Auto_Contarcts_Created__c = TRUE;
                        contractList.add(cont);
                    }
                      system.debug('contractList====>'+contractList);
                }
            }
        }
      
        try{
            system.debug('Getting contract list value ====>'+contractList);
            if(!contractList.isEmpty()) 
               insert contractList;
            /*for(contract cont :contractList){
                cont.CEP_Status__c = 'Activated';
                updateContractList.add(cont);
            }
            if(!updateContractList.isEmpty())
                update updateContractList;*/
        }
        catch(exception e){
            system.debug('error in auto apply contarct**** '+e.getMessage());
        }     
    }
    


//Jagan added new method - 11/1/2018 - Start

/************************************JAGANNATHAN - START******************************************************
* Method Name      :     createAdditionalFreeContracts
* Create By        :     Jagannathan A.P
* Create Date      :     11/01/2018
* Description      :     logic to create any additional free  contarcts on asset registration
* *****************************************************************************************/
    public static void createAdditionalFreeContracts(list<asset> triggerNew,Boolean entitlementOnCountryChange){     
       
        System.debug('free contracts --> Inside createAdditionalFreeContracts flow***');      
        
        set<Id> contractID = new set<ID>();
        Id assetRecId;   
        boolean createContract = false;
        Date assetpurchaseDate;
        Date startDate;
        Date endDate;  
        list<contract> contractList = new list<contract>();
        list<contract> updateContractList = new list<contract>();
        set<string> productIdSet = new Set<string>();
        String dataSource;
        String[] afterTrim;
        String trimmedValue;
        boolean exactValue=false;
        map<String,CEP_Entitlement_Association__c> EntitlementAssocMap = new map<String,CEP_Entitlement_Association__c>();
        map<String,CEP_Auto_Apply_Contracts__c> autpApplyContMap = new map<String,CEP_Auto_Apply_Contracts__c>();
        list<Id> contractSet = new list<Id>();
        Set<String> existingAutoApplyContractName = new Set<String>();
        // Commented by Gokul CEP-5898List<Contract> lstContractsPresent = new List<Contract>();
        for(asset ast :triggerNew){
            if(ast.CTS_Data_Source__c !=NULL && String.isNotBlank(ast.CEP_Product_Map__c) && ast.Status == 'Active' && String.isNotblank(ast.CEP_Asset_Type__c) && ast.CEP_Asset_Type__c == 'New'){
                productIdSet.add(ast.CEP_Product_Map__c);
                dataSource = ast.CTS_Data_Source__c;
                assetpurchaseDate = date.valueof(ast.PurchaseDate);    
                assetRecId = ast.id;    
            }            
        }
        System.debug('free contracts --> productIdSet***' + productIdSet);
        System.debug('free contracts --> dataSource***' + dataSource);
        System.debug('assetRecId ***' + assetRecId ); 
        
        /* Commented by Gokul CEP-5898 Asset contractAsset = [SELECT Id,AccountId,PurchaseDate FROM asset WHERE Id=:assetRecId];
        System.debug('contractAsset ***' + contractAsset );
        
        lstContractsPresent = [Select id,name,CEP_Asset__c from contract where CEP_Asset__c =:assetRecId and CEP_Status__c  = 'Activated'];*/
        if(!productIdSet.isEmpty()){
        for(Contract c : [Select id,name,CEP_Asset__c from contract where CEP_Asset__c =:assetRecId and CEP_Status__c  = 'Activated']){ 
            existingAutoApplyContractName.add(c.name);
        }
        System.debug('existingAutoApplyContractName***' + existingAutoApplyContractName);
         
        //To remove _ / - from asset data source...
        if(dataSource !=NULL && dataSource.contains('_')){
            System.debug('Inside _ underscore flow**');
            afterTrim = dataSource.split('_');
            System.debug('After Trim***' + afterTrim);
            System.debug('After Trim[0]***' + afterTrim[0]);
            trimmedValue = afterTrim[0];
        }
        else if(dataSource !=NULL && dataSource.contains('-')){
            System.debug('Inside - hypen flow**');
            afterTrim = dataSource.split('-');
            System.debug('After Trim***' + afterTrim);
            System.debug('After Trim[0]***' + afterTrim[0]);
            trimmedValue = afterTrim[0];
        }
        else if( dataSource !=NULL && ( !dataSource.contains('_') || !dataSource.contains('-') ) ){
            System.debug('No need to trim flow**');  
            trimmedValue = dataSource;
        }
        
            System.debug('Trimmed value*');  
            
            autpApplyContMap = new map<String,CEP_Auto_Apply_Contracts__c>([SELECT Id,CEP_Contract_Master__r.CEP_Contract_Start_Date__c,CEP_Contract_Master__r.CEP_Special_Services__c,CEP_Purchase_StartDate__c,CEP_Purchase_EndDate__c,CEP_NoEndDate__c,CEP_Contract_Master__c,CEP_Country__c,CEP_Region__c,CEP_Product_Mappings__c,CEP_Contract_Master__r.CEP_Multiplier__c,CEP_Contract_Master__r.CEP_Configuration_Type__c,
                                                                                                                CEP_Contract_Master__r.CEP_Duration__c,CEP_Contract_Master__r.CEP_Region__c,CEP_Contract_Master__r.Name,CEP_Contract_Master__r.CEP_Cost__c,
                                                                                                                CEP_Contract_Master__r.CurrencyIsoCode,CEP_Contract_Master__r.CEP_Type__c
                                                                                                                FROM CEP_Auto_Apply_Contracts__c
                                                                                                                WHERE CEP_Contract_Master__r.Name NOT IN:existingAutoApplyContractName AND CEP_Contract_Master__r.CEP_Special_Services__c includes (: trimmedValue) AND CEP_Product_Mappings__c IN :productIdSet]);                                                                                                              
            system.debug('autpApplyContMap --> **' + autpApplyContMap);    
            system.debug('autpApplyContMap. size()**' + autpApplyContMap.size());       
                                                                                                              
        } 
        If(!autpApplyContMap.isEmpty()){
            map<string,string> entMp = CEP_EntitlementGenericController.getEntitlement(assetRecId); // Added by Gokul CEP-5898
        for(asset ast :triggerNew){        
            System.debug('free contracts --> ast.CEP_Auto_Contarcts_Created__c' + ast.CEP_Auto_Contarcts_Created__c);
            System.debug('productIdSet***' + productIdSet);
            System.debug('ast.CEP_Product_Map__c***' + ast.CEP_Product_Map__c);    
                    
            if((productIdSet.contains(ast.CEP_Product_Map__c))){ 
                           
                System.debug('free contracts --> product mapping** '+ast.CEP_Product_Map__c);  
                
                    System.debug('Number of times - iterate EntitlementAssocMap**');  
                                  
                    for(CEP_Auto_Apply_Contracts__c apply : autpApplyContMap.values()){  
                                          
                        System.debug('Number of times - iterate auto apply***');   
                                         
                        if(apply.CEP_Purchase_StartDate__c !=NULL){
                            startDate = Date.valueOf(apply.CEP_Purchase_StartDate__c);
                        }
                        if(apply.CEP_Purchase_EndDate__c !=NULL){
                            endDate = Date.valueOf(apply.CEP_Purchase_EndDate__c);  
                        }
                        if(apply.CEP_NoEndDate__c == True && assetpurchaseDate >= startDate ){
                            createContract = true;
                            System.debug('Inside assetpurchaseDate >= startDate' + createContract);    
                        }
                        else if(apply.CEP_NoEndDate__c == false &&  assetpurchaseDate !=null && assetpurchaseDate >= startDate && assetpurchaseDate <= endDate){
                            createContract = true;
                            System.debug('Inside assetpurchaseDate >= startDate && assetpurchaseDate <= endDate***' + createContract);
                        }
                        
                        System.debug('Final boolean value whether to create contract***' + createContract);                                                            
                        system.debug('free contracts --> apply.CEP_Product_Mappings__c ** '+apply.CEP_Product_Mappings__c);
                        system.debug('free contracts --> apply.CEP_Region__c'+apply.CEP_Region__c);
                        system.debug('free contracts --> apply.CEP_Country__c'+apply.CEP_Country__c);
                        system.debug('free contracts --> apply.CEP_Contract_Master__c'+apply.CEP_Contract_Master__c);
                        system.debug('free contracts --> apply.CEP_Contract_Master__r.CEP_Configuration_Type__c'+apply.CEP_Contract_Master__r.CEP_Configuration_Type__c);                        
                        system.debug( apply.CEP_Country__c + ast.CEP_Country__c);    
                                            
                        if(apply.CEP_Product_Mappings__c == ast.CEP_Product_Map__c && 
                            (( apply.CEP_Region__c!=null && ast.CEP_Region__c!=null && apply.CEP_Region__c.contains(ast.CEP_Region__c) ) ||
                            ( apply.CEP_Country__c!=null && ast.CEP_Country__c!=null && apply.CEP_Country__c.contains(ast.CEP_Country__c) ) || 
                            ( apply.CEP_Country__c==null && apply.CEP_Region__c==null )) 
                            && apply.CEP_Contract_Master__c!=null && 
                            apply.CEP_Contract_Master__r.CEP_Configuration_Type__c == 'Contract' 
                            && createContract){    
                                                    
                            System.debug('free contracts --> After all the initial level of check***');                            
                            Contract cont = new Contract();
                            cont.Status = 'Draft';
                            cont.CEP_Status__c = 'Activated';
                            cont.AccountId = ast.AccountId;
                            cont.CEP_Asset__c = ast.Id;
                            cont.Name = apply.CEP_Contract_Master__r.Name;
                            cont.CEP_Entitlement_Configuration__c = apply.CEP_Contract_Master__c;
                            cont.CEP_Cost__c = apply.CEP_Contract_Master__r.CEP_Cost__c;
                            cont.CurrencyIsoCode = apply.CEP_Contract_Master__r.CurrencyIsoCode;
                            
                            //Condition to set the contract start date and end date...
                            if(apply.CEP_Contract_Master__r.CEP_Contract_Start_Date__c == 'Contract Purchase Date/Expiry Date For Renewal')
                                cont.startDate = system.today();
                            else if(apply.CEP_Contract_Master__r.CEP_Contract_Start_Date__c == 'HW Expiry Date' && !entMp.isEmpty() && entMp.containsKey('hwDays')) // Modify By Gokukl CEP-4834
                                cont.startDate = Date.valueOf(entMp.get('hwDays') == 'LIFETIME'? String.valueof(ast.PurchaseDate.addDays(9999)):entMp.get('hwDays'));// Modify By Gokukl CEP-4834
                            else if(apply.CEP_Contract_Master__r.CEP_Contract_Start_Date__c == 'Product Purchase Date' )
                                cont.startDate = ast.PurchaseDate;      
                            else if(apply.CEP_Contract_Master__r.CEP_Contract_Start_Date__c == 'SW expiry date' && !entMp.isEmpty() && entMp.containsKey('phDays'))// Modify By Gokukl CEP-4834
                                cont.startDate = Date.valueOf(entMp.get('phDays') == 'LIFETIME'? String.valueof(ast.PurchaseDate.addDays(9999)):entMp.get('phDays'));// Modify By Gokukl CEP-4834
                            if(cont.startDate != null && apply.CEP_Contract_Master__r.CEP_Duration__c != null && apply.CEP_Contract_Master__r.CEP_Multiplier__c != null){
                                integer contractDays = (Integer.valueOf(apply.CEP_Contract_Master__r.CEP_Duration__c)*integer.valueOf(apply.CEP_Contract_Master__r.CEP_Multiplier__c));
                                cont.ContractTerm = 1;//Adding junk value as this field is not being used but is mandatory
                                cont.CEP_End_Date__c = cont.startDate.addDays(contractDays);
                            }                                                        
                            //Condition to set the contract start date and end date...
                                                                                                        
                            if(apply.CEP_Contract_Master__r.CEP_Type__c == 'RMA')
                                cont.CEP_Is_RMA_Auto_Apply_Contract__c = TRUE;
                            
                            if(cont.Name.contains('Complimentary')){
                                cont.CEP_Is_RMA_Auto_Apply_Contract__c = TRUE;
                            }                            
                            ast.CEP_Auto_Contarcts_Created__c = False; // ->Comment this to false.So that during edit -> new contract will not be created
                            contractList.add(cont);                            
                        }
                    } 
            }
        }
        }       
        try{
            if(!contractList.isEmpty())
                insert contractList;
                System.debug('free contracts --> Inserted Contract**' + contractList);                                
            for(contract cont :contractList){
                cont.CEP_Status__c = 'Activated';
                updateContractList.add(cont);
                contractID.add(cont.Id);
            }
            //updateAllEntitlements(contractID); // Commented by Gokul CEP-4834 //Pass contract ID to update entitlements method...
            sendEmailForCreatedContracts(contractID,dataSource,exactValue,trimmedValue); //Method to send email
            if(!updateContractList.isEmpty())
                update updateContractList;
        }
        catch(exception e){
            system.debug('free contracts --> error in free contract insertion**** '+e.getMessage());
            CEP_Error_Log__c erLog = new CEP_Error_Log__c(CEP_Class_Name__c = 'CEP_AssetHelper',
                                                            CEP_Exception_Message__c = e.getMessage(),
                                                            CEP_Method_Name__c = 'createAdditionalFreeContracts',
                                                            CEP_Module_Name__c = 'CEP_AssetHelper-createAdditionalFreeContracts'
                                                            );
            insert erLog;
        }    
    } 

public static void sendEmailForCreatedContracts(set<Id> contractid,String dataSource,boolean exactValue,String trimmedValue){

        System.debug('contractid' + contractid + 'dataSource' + dataSource + 'exactValue' + exactValue + 'trimmedValue' + trimmedValue);
        //set<id> contractIdSet = new set<id>();
        set<id> templateId = new set<id>();
        Map<Id,String> mapContractIdWithEmailTemplateName = new Map<Id,String>();
        List<String> customerEmail = new List<string>();      
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();     
        Messaging.SendEmailResult[] results;
        boolean result =  false;
        
        List<Contract> lstContract = [SELECT id,name,accountid,CEP_Email_Template_Name__c,Account.CTS_Email__c from contract where id =: contractid];
        for(Contract contr : lstContract){  
            if(exactValue == False){                     
                mapContractIdWithEmailTemplateName.put(contr.id,contr.CEP_Email_Template_Name__c+'-'+trimmedValue);
            }else{
                mapContractIdWithEmailTemplateName.put(contr.id,contr.CEP_Email_Template_Name__c+'-'+dataSource);
            }      
            customerEmail.add(contr.Account.CTS_Email__c);                      
            System.debug('customeremail during iteration***' + customerEmail);
        }
        System.debug('mapContractIdWithEmailTemplateName***' + mapContractIdWithEmailTemplateName);  
        System.debug('String customeremail***' + customerEmail);
    
        List<EmailTemplate> lstEmailTemplates = new List<EmailTemplate>();
    OrgWideEmailAddress[] owa = new OrgWideEmailAddress[]{};
        //if(!Test.isRunningTest()){
        lstEmailTemplates = [Select id,name from EmailTemplate WHERE NAME IN: mapContractIdWithEmailTemplateName.values()];
        owa = [select Id from OrgWideEmailAddress where Address = 'do_not_reply@netgear.com'];
        //}
        list<Contact> contList = [SELECT Id FROM contact LIMIT 1];
        for(EmailTemplate temp : lstEmailTemplates){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(customerEmail);              
            if(contList.size() > 0)
                email.setTargetObjectId(contList[0].Id);
                //email.setWhatId(targetObjId);
                email.setSaveAsActivity(false);
                email.setTemplateId(temp.id);
                email.setTreatTargetObjectAsRecipient(false);            
            if ( owa.size() > 0 ) {
                email.setOrgWideEmailAddressId(owa.get(0).Id);
            }
            lstEmail.add(email);
        }
        System.debug('templateId***' + templateId);
        try{
                results  = Messaging.sendEmail(lstEmail);
                result = (results[0].success == true) ? true : false;
                System.debug('Result**' + result);
        }                
        catch(exception e){
                CEP_Error_Log__c erLog = new CEP_Error_Log__c(CEP_Class_Name__c = 'CEP_AssetHelper',
                                                                CEP_Exception_Message__c = e.getMessage(),
                                                                CEP_Method_Name__c = 'SendEmail',
                                                                CEP_Module_Name__c = 'Sending email for auto apply contracts'
                                                                );
                insert erLog;
        }
}       

/*********************************JAGANNATHAN - END****************************************

    * Method Name      :     populateProdMapping
    * Created By       :     Nitesh Halliyal
    * Create Date      :     3/15/2018
    * Description      :     Method to populate the prodMapping record on asset
    * ***********************************************************************/
    public Static void populateProdMapping(List<Asset> triggerNewList){
       set<String> prod2IdSet = new set<String>();
       set<String> ProdFamilyStrSet = new set<String>();
       map<String,String> prodFamilyIdMap = new map<String,String>();
       map<String,String> prodMapIdMap = new map<String,String>();
       List<Asset> readyNasAstList = new list<Asset>();
       set<String> readyNasProdCodeSet = new set<String>();
       map<String,String> readyNasprodIdMap = new map<String,String>();
       map<String,String> readyNasprodMap = new map<String,String>();
       map<String,String> prodVersionMap = new map<String,String>();
       for(asset ast :triggerNewList){
           system.debug('asthardwareversion**** '+ast.CEP_Hardware_Version__c);
           /*if(ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c)){
                prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c);
           }*/   
           if(ast.CEP_Product_Map__c == null){
           if(String.IsNotBlank(ast.CEP_Hardware_Version__c) && (!ast.CEP_Hardware_Version__c.toUpperCase().contains('V1'))){
               system.debug('Inside H/w version+++');
               if(ast.CEP_Hardware_Version__c.length() > 2){
                   system.debug('Inside H/w version+++ length>2');
                   if(!ast.CEP_Is_Bundle_Product__c && String.IsBlank(ast.CEP_Product_ID__c)){
                        system.debug('Inside H/w version+++ not bundle');
                        prodVersionMap.put(ast.Product2Id,ast.CEP_Hardware_Version__c.substring(0,2));
                        prod2IdSet.add(ast.Product2Id);
                   }
                   else if(ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c))
                        prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c+ast.CEP_Hardware_Version__c.substring(0,2));
                   else if(!ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c)) 
                        prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c+ast.CEP_Hardware_Version__c.substring(0,2));          
               }
                else if(ast.CEP_Hardware_Version__c.length() == 2){
                    if(!ast.CEP_Is_Bundle_Product__c && String.IsBlank(ast.CEP_Product_ID__c)){
                        prodVersionMap.put(ast.Product2Id,ast.CEP_Hardware_Version__c);
                        prod2IdSet.add(ast.Product2Id);
                    }
                   else if(ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c))
                        prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c+ast.CEP_Hardware_Version__c);
                   else if(!ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c)) 
                        prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c+ast.CEP_Hardware_Version__c);         
                }    
           }
            else if(ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c)){
                  system.debug('Inside else if1+++');
                  prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c);
            }
            else if(!ast.CEP_Is_Bundle_Product__c && String.IsNotBlank(ast.CEP_Product_ID__c)){
                  system.debug('Inside else if2+++');
                  prodFamilyIdMap.put(ast.Product2Id,ast.CEP_Product_ID__c);
            }  
            else {   
                system.debug('Inside else+++');
                prod2IdSet.add(ast.Product2Id);
           }
           }
       }
       system.debug('prod version map**** '+prodVersionMap);
       for(product2 prod : [SELECT Id,ProductCode,Family,CEP_Is_Bundle_Product__c,CEP_Product_ID__c FROM Product2 WHERE Id IN:prod2IdSet]){
           if(String.isNotBlank(prod.ProductCode)){
               String productFamilyStr = '';
               if(!prodFamilyIdMap.containsKey(prod.Id)){
                    if(prodVersionMap.containsKey(prod.Id)){
                            if(prod.ProductCode.Contains('-'))
                                productFamilyStr = prod.ProductCode.subStringBefore('-')+prodVersionMap.get(prod.Id);
                            else
                                productFamilyStr = prod.Family+prodVersionMap.get(prod.Id);
                    }
                    else{
                            if(prod.ProductCode.Contains('-'))
                                productFamilyStr = prod.ProductCode.subStringBefore('-');
                            else
                                productFamilyStr = prod.Family;    
                    }
               }
               prodFamilyIdMap.put(prod.Id,productFamilyStr);
           }
       }
       system.debug('prod family map**** '+prodFamilyIdMap);
       for(CEP_Product_Mapping__c prodMap : [SELECT Id,Name FROM CEP_Product_Mapping__c WHERE Name IN:prodFamilyIdMap.values()]){
           String nametoUppercase = prodMap.Name.toUppercase();
            prodMapIdMap.put(nametoUppercase,prodMap.Id);    
       }
       system.debug('prod mapping map**** '+prodMapIdMap);
       for(Asset ast : triggerNewList){
           if(String.isNotBlank(ast.Product2Id)){
               if(prodFamilyIdMap.containsKey(ast.Product2Id) &&  prodMapIdMap.containsKey(prodFamilyIdMap.get(ast.Product2Id))){
                   
                   ast.CEP_Product_Map__c = prodMapIdMap.get(prodFamilyIdMap.get(ast.Product2Id));
                    system.debug('ast.CEP_Product_Map__c'+ast.CEP_Product_Map__c);

               }
               else{
                   if(prodFamilyIdMap.containsKey(ast.Product2Id)){
                        String checkRNStr = prodFamilyIdMap.get(ast.Product2Id).substring(0,2);
                        if(prodFamilyIdMap.get(ast.Product2Id).substring(0,2) == 'RN'){
                           readyNasAstList.add(ast);
                           String HardwareVersionStr = '';
                           if(String.isNotBlank(ast.CEP_Hardware_Version__c) && (!ast.CEP_Hardware_Version__c.toUpperCase().contains('V1'))){
                                if(ast.CEP_Hardware_Version__c.length() > 2)
                                    HardwareVersionStr = 'ReadyNAS'+prodFamilyIdMap.get(ast.Product2Id)+ast.CEP_Hardware_Version__c.substring(0,2);
                                else if(ast.CEP_Hardware_Version__c.length() == 2)
                                     HardwareVersionStr = 'ReadyNAS'+prodFamilyIdMap.get(ast.Product2Id)+ast.CEP_Hardware_Version__c;
                           }
                           else
                               HardwareVersionStr = 'ReadyNAS'+prodFamilyIdMap.get(ast.Product2Id);
                           readyNasprodIdMap.put(ast.Product2Id,HardwareVersionStr);
                        }
                   }  
               }
           }
       }
       system.debug('redynas prod mapping map*** '+readyNasprodIdMap);
        if(!readyNasAstList.isEmpty() && !readyNasprodIdMap.isEmpty()){
            for(CEP_Product_Mapping__c prodMap : [SELECT Id,Name FROM CEP_Product_Mapping__c WHERE Name IN:readyNasprodIdMap.values()]){
                readyNasprodMap.put(prodMap.Name,prodMap.Id);    
            }
            for(Asset ast : readyNasAstList){
                if(String.isNotBlank(ast.Product2Id)){
                    if(readyNasprodIdMap.containsKey(ast.Product2Id) &&  readyNasprodMap.containsKey(readyNasprodIdMap.get(ast.Product2Id))){
                        ast.CEP_Product_Map__c = readyNasprodMap.get(readyNasprodIdMap.get(ast.Product2Id));
                    }    
                }   
            }
        }
        
        Map<String,String> snMap = new Map<String,String>();
        Map<String,String> serialPrefxMap = new Map<String,String>();

        for(Asset ast : triggerNewList){
            System.debug('ast.CEP_Product_Map__c==>'+ast.CEP_Product_Map__c);
            If(ast.CEP_Product_Map__c == null && ast.serialNumber!=null)
                snMap.put(ast.serialNumber,ast.serialNumber.left(3));
        }
        System.debug('snMap==>'+snMap);
        if(snMap.size()>0){
            for(CEP_Serial_Prefix__c serialPrefix : [SELECT Id,CEP_Prefix__c, CEP_Filter_SubProduct__c, CEP_NativeProduct__c, CEP_NativeVersion__c,CEP_Product_Mappings__c 
                                                        FROM CEP_Serial_Prefix__c 
                                                            where CEP_Prefix__c =: snMap.values() ]){
                    serialPrefxMap.put(serialPrefix.CEP_Prefix__c , serialPrefix.CEP_Product_Mappings__c);
            }
            System.debug('serialPrefxMap==>'+serialPrefxMap);
            if(serialPrefxMap.size()>0){
                for(Asset ast : triggerNewList){
                    if(snMap.containsKey(ast.serialNumber) && serialPrefxMap.containsKey(snMap.get(ast.serialNumber))){
                        ast.CEP_Product_Map__c = serialPrefxMap.get(snMap.get(ast.serialNumber));
                        ast.Is_Product_Map_by_Serial_Prefix__c = True;
                    }   
                    System.debug('ast==>'+ast);
                }
            }
        }
    }
 /*********************************************************************************************
    * Method Name      :     populateCountryOnAsset
    * Created By       :     Nitesh Halliyal
    * Create Date      :     3/30/2018
    * Description      :     Method to populate the country on asset to account country if blank
    * ******************************************************************************************/ 
    public static void populateCountryOnAsset(List<Asset> triggerNewList){
        set<String> accountIdSet = new set<String>();
        set<String> assetIdSet = new set<String>();
        map<Id,Account> accountMap = new map<Id,Account>(); // Added by Gokul CEP-5898
         Map<string,CEP_Country_Region_Mapping__c> countryRegionMap = new Map<string,CEP_Country_Region_Mapping__c>(CEP_Country_Region_Mapping__c.getAll());
        for(Asset ast : triggerNewList){
            if(String.Isblank(ast.SerialNumber)){
                ast.CEP_Asset_Type__c='Refurbished – without SN';
                ast.CTS_Data_Source__c ='SupportAgent';        
            }
            if(String.isBlank(ast.CEP_Country__c)){
                accountIdSet.add(ast.AccountId);
            }
        }   
        If(!accountIdSet.isEmpty())// Added by Gokul CEP-5898
            accountMap = new map<Id,Account>([SELECT Id,Countries__c FROM Account WHERE Id IN :accountIdSet]);
        
        for(Asset updateAst : triggerNewList){
            if(!accountMap.isEmpty() && accountMap.containsKey(updateAst.AccountId) && String.IsNotBlank(accountMap.get(updateAst.AccountId).Countries__c))
                updateAst.CEP_Country__c = accountMap.get(updateAst.AccountId).Countries__c;
            if(String.IsBlank(updateAst.CEP_region__c)){
                if(countryRegionMap.containsKey(updateAst.CEP_Country__c))
                    updateAst.CEP_region__c = countryRegionMap.get(updateAst.CEP_Country__c).Region__c;
            }
        }
    }
/*********************************************************************************************
    * Method Name      :     updateEntitlementsContarctsDates
    * Created By       :     Nitesh Halliyal
    * Create Date      :     4/17/2018
    * Description      :     Method to update start and end date if purchase date is changed
    * ******************************************************************************************/
    public static void updateEntitlementsContarctsDates(List<Asset> triggerNewList,map<Id,asset> triggerOldMap){
        Set<String> udpatedAstIdSet = new set<String>();
        //map<String,list<Entitlement>> astEntitlementMap = new map<String,list<Entitlement>>(); // Commented by Gokul CEP-4834
        map<String,list<contract>> astContractMap = new map<String,list<contract>>();
        //list<Entitlement> updateEntList = new list<Entitlement>(); // Commented by Gokul CEP-4834
        list<contract> updateContList = new list<contract>();
        for(Asset ast : triggerNewList){
            if(ast.PurchaseDate != null && triggerOldMap.get(ast.Id).PurchaseDate != null){
                if(ast.PurchaseDate != triggerOldMap.get(ast.Id).PurchaseDate)
                    udpatedAstIdSet.add(ast.Id);   
            }
        }
        
        /*Commented by Gokul CEP-4834
        //Moving SOQL out of For
        List<Entitlement> lEnt = [SELECT Id,AssetId,StartDate,EndDate FROM Entitlement WHERE AssetId IN:udpatedAstIdSet];
        for(Entitlement ent : lEnt){
            if(astEntitlementMap.containsKey(ent.AssetId))
                astEntitlementMap.get(ent.AssetId).add(ent);
            else
                astEntitlementMap.put(ent.AssetId, new list<Entitlement>{ent});    
        }
        system.debug('entitlementmap****** '+astEntitlementMap);
        */
        for(Contract cont : [SELECT Id,CEP_Asset__c,StartDate,CEP_End_Date__c FROM Contract WHERE CEP_Asset__c IN:udpatedAstIdSet AND CEP_Status__c = 'Activated']){
            if(astContractMap.containsKey(cont.CEP_Asset__c))
                astContractMap.get(cont.CEP_Asset__c).add(cont);
            else
                astContractMap.put(cont.CEP_Asset__c, new list<contract>{cont});    
        }
        for(asset ast :triggerNewList){
            if(udpatedAstIdSet.contains(ast.id)){
                system.debug('inside days extend^^^^ '+triggerOldMap.get(ast.Id).PurchaseDate.daysBetween(ast.PurchaseDate));
                Integer dateDiffDays = triggerOldMap.get(ast.Id).PurchaseDate.daysBetween(ast.PurchaseDate);
                /*Commented by Gokul CEP-4834
                if(astEntitlementMap.containskey(ast.Id) && astEntitlementMap.get(ast.Id).size() > 0){
                    for(Entitlement ent : astEntitlementMap.get(ast.Id)){
                        if(ent.StartDate != null && ent.EndDate != null){
                            ent.StartDate = ent.StartDate.addDays(dateDiffDays);
                            ent.EndDate = ent.EndDate.addDays(dateDiffDays);
                            updateEntList.add(ent);
                        }
                    }
                }*/
                if(astContractMap.containsKey(ast.Id) && astContractMap.get(ast.Id).size() > 0){
                    for(contract cont : astContractMap.get(ast.Id)){
                        if(cont.StartDate != null && cont.CEP_End_Date__c != null){
                            cont.StartDate = cont.StartDate.addDays(dateDiffDays);
                            cont.CEP_End_Date__c = cont.CEP_End_Date__c.addDays(dateDiffDays);
                            updateContList.add(cont);
                        }
                    }
                }
            }
        }
        try{
            /*Commented by Gokul CEP-4834
            if(!updateEntList.isEmpty()){
                update updateEntList;
            }
            */
            if(!updateContList.isEmpty()){
                update updateContList;
            }
        }
        catch(exception e){
            system.debug('error in purchase date update** '+e.getMessage());
        }
    }
    
    /*********************************************************************************************
    * Method Name      :     updateEntitlementsOnCountryUpdate
    * Created By       :     Neha Jain
    * Create Date      :     4/17/2018
    * Description      :     Method to update Entitlements if country on Asset is changed
    * ******************************************************************************************/
    
    public static void updateEntitlementsOnCountryUpdate(List<Asset> newAssetList){  
    
        /*Commented by Gokul CEP-4834 List<Entitlement> oldEntList = new List<Entitlement>(); */
        List<Contract> oldContList = new List<Contract>();
        if(newAssetList.size()>0){
     /*       for(Asset asst : newAssetList){
                system.debug('+++asst'+asst.CEP_Entitlements_Created__c);
                asst.CEP_Entitlements_Created__c = FALSE;
                asst.CEP_Auto_Contarcts_Created__c = FALSE;
                system.debug('test');
            } */
            /*Commented by Gokul CEP-4834
            for(Entitlement ent : [SELECT ID,Name FROM Entitlement WHERE AssetID IN : newAssetList]){
                oldEntList.add(ent);
            }
            system.debug('+++oldEntList'+oldEntList);
            */
            for(Contract cont : [SELECT ID,Name,CEP_Entitlement_Configuration__r.CEP_Free_RMAs__c 
                                    FROM Contract 
                                    WHERE CEP_Asset__c IN : newAssetList 
                                    AND (CEP_Is_RMA_Auto_Apply_Contract__c=TRUE 
                                    OR CEP_Entitlement_Configuration__r.CEP_Plan_Type__c = 'Complimentary')]){ // Change by Gokul
                oldContList.add(cont);
            }
            system.debug('+++oldContList'+oldContList);
        }
        /*Commented by Gokul CEP-4834if(oldEntList.size()>0){
            delete oldEntList;
        }*/
        if(oldContList.size()>0){
            delete oldContList;
        }
        if(newAssetList.size()>0){
            system.debug('test----');
           // update newAssetList;
           /*Commented by Gokul CEP-4834createEntitlementRefurbishedProduct(newAssetList,true);
           createEntitlementsContarcts(newAssetList,true);*/
           createAutoApplyContracts(newAssetList,true);
        } 
    }
    
/*******************************************************************************************
* Method Name      :     updateRegionOnAsset
* Created By       :     Jharna Sinha
* Return           :     Void
* Description      :     Update Region based on Country
*******************************************************************************************/   
    
    public static void updateRegionOnAsset(List<Asset> assets){
        
        List<Asset> assetToUpdate = new List<Asset>();
        Map<string,CEP_Country_Region_Mapping__c> CountryRegionMap = new Map<string,CEP_Country_Region_Mapping__c>();
        CountryRegionMap = CEP_Country_Region_Mapping__c.getAll();
        
        for(Asset asst:assets){
            if(asst.CEP_Country__c != null && CountryRegionMap.containsKey(asst.CEP_Country__c) && CountryRegionMap.get(asst.CEP_Country__c).Region__c!=null){
                asst.CEP_Region__c= CountryRegionMap.get(asst.CEP_Country__c).Region__c;
                System.debug('My Region '+asst.CEP_Region__c);
            } 
        }
        
     
    }   
    
    /*******************************************************************************************
* Method Name      :     updateRegKey
* Created By       :     Gokula Krishnan
* Return           :     Void
* Description      :     Update Regestration Key
*******************************************************************************************/   
    
    public static void updateRegKey(list<asset> triggerNew, map<Id,asset> triggerOld){
         
        set<id> prdmp = new set<id>();
        Map<id,boolean> prdmpWithRegKey = new Map<id,boolean>();
        for(Asset asst : triggerNew){
            if(asst.CEP_Product_Map__c != null && (asst.CEP_Registration_Key__c == null ||  asst.CEP_Product_Map__c != triggerOld.get(asst.id).CEP_Product_Map__c)){
                prdmp.add(asst.CEP_Product_Map__c);
                system.debug('<<Registration Key>>');
            } 
        }
        
        if(!prdmp.isEmpty()){
            For(CEP_Product_Mapping__c prd : [select id,CEP_Registration_Key_Required__c from CEP_Product_Mapping__c where id =: prdmp]){
                if(prd.CEP_Registration_Key_Required__c )
                    prdmpWithRegKey.put(prd.id,True);
                else
                    prdmpWithRegKey.put(prd.id,false);
            }
        }
        
        for(Asset asst : triggerNew){
            if(prdmpWithRegKey.containskey(asst.CEP_Product_Map__c)){
                if(prdmpWithRegKey.get(asst.CEP_Product_Map__c))
                    asst.CEP_Registration_Key__c = CEP_GenerateRegistrationKey.getRegistrationKey(asst.serialnumber);
                else
                    asst.CEP_Registration_Key__c = '';
            } 
        }
        
    }   
}