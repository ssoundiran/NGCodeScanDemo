/************************************************************************
 * Name :CEP_AssetHandler
 * Author:Nitesh Halliyal
 * Date : 23rd december 2017
 * Desc : This is a handler class for all trigger logic on asset.
 *
 * 
 *************************************************************************/
public class CEP_AssetHandler {
    
    Public Static Boolean afterUpdateRun = FALSE;
    Public Static Boolean beforeUpdateRun = FALSE;
    Public Static Boolean afterRunOnce = TRUE;
    public static void beforeInsertHandler(list<asset> triggerNew){
        //NHALLIYAL:populate Country on asset from account country 
        CEP_AssetHelper.populateCountryOnAsset(triggerNew);
        //NHALLIYAL:Method for populating Product Mapping on Asset
        system.debug('triggerNew-->'+triggerNew);
        CEP_AssetHelper.populateProdMapping(triggerNew);
        CEP_AssetHelper.updateRegionOnAsset(triggerNew);
    }
    
    public static void AfterInsertHandler(list<asset> triggerNew){
        list<Asset> refurbAssetList = new list<Asset>();
        /* Commented by Gokul CEP-5898
        for(Asset assetObj : triggerNew){
            system.debug('after insert handler - before refurb');
            if(assetObj.CEP_Legacy_Asset_ID__c == null){
                refurbAssetList.add(assetObj);           
                system.debug('after insert handler - inside if refurb'+refurbAssetList);
            }
        }
        //Logic to create
        if(refurbAssetList.size()>0){
            //CEP_AssetHelper.createEntitlementRefurbishedProduct(triggerNew,false); // Commented by Gokul CEP-4834
        }
        */
        //Naveen VM : Method to Calculate Annual Revenue on Insert
        if(afterRunOnce) // Added by gokul CEP-5898
        CEP_AssetHelper.rollupSummary(triggerNew, new map<Id,asset>());
        afterRunOnce = false; // Added by gokul CEP-5898
         /* Commented by Gokul CEP-5898
         //Code to create entitlements for Arlo Assets
         list<Asset> updateAstList = new list<asset>();
            for(asset ast : triggerNew){
                if(ast.CTS_Data_Source__c == 'Arlo')
                    updateAstList.add(ast);        
            }
            if(!updateAstList.isEmpty()){
                //update updateAstList;
            }
        */
        
        // Congo project added by jagan.Update order line with asset - Guest order/Gift order...       
        CEP_AssetHelper.updateOrderLineItem(triggerNew);
    }
    
     public static void afterDeleteHandler(list<asset> triggerOld){
        //Naveen VM : Method to Calculate Annual Revenue on Delete
        CEP_AssetHelper.rollupSummary(triggerOld, new map<Id,asset>());        
    }
    
     public static void afterUnDeleteHandler(list<asset> triggerNew, map<Id,asset> triggerOld){
        //Naveen VM : Method to Calculate Annual Revenue on Un-Delete
        CEP_AssetHelper.rollupSummary(triggerNew, triggerOld);        
    }
    
    
    public static void beforeUpdateHandler(list<asset> triggerNew, map<Id,asset> triggerOld){
        System.debug('CEP_AssetHandler --> class**');
        CEP_AssetHelper.assetTransferBeforeUpdate(triggerNew, triggerOld);
        //NHALLIYAL:populating entitlementson update
        //CEP_AssetHelper.createEntitlementsContarcts(triggerNew,false); // Commented by Gokul CEP-4834
        //NHALLIYAL: Mehtod to create contracts for Auto Apply Contract        
        CEP_AssetHelper.createAutoApplyContracts(triggerNew,false);
        CEP_AssetHelper.createAdditionalFreeContracts(triggerNew,false); //Jagan added- 11/1/2018...
        CEP_AssetHelper.updateRegionOnAsset(triggerNew);
        list<Asset> refurbAssetList = new list<Asset>();
        CEP_AssetHelper.updateRegKey(triggerNew,triggerOld); // Added by Gokul 6.11.2018
     /*   for(Asset assetObj : triggerNew){
            if(assetObj.CEP_Legacy_Asset_ID__c == null){
                refurbAssetList.add(assetObj);                
            }
        }
        //Logic to create
        if(refurbAssetList.size()>0){
            CEP_AssetHelper.createEntitlementRefurbishedProduct(refurbAssetList,false);
        }  */

    }
    
    public static void afterUpdateHandler(list<asset> triggerNew, map<Id,asset> triggerOld){
        if(!afterUpdateRun){
            //Naveen VM : Method to Calculate Annual Revenue on Update
            CEP_AssetHelper.rollupSummary(triggerNew, triggerOld);
            //NHALLIYAL : to update entitlement and contarcts start date absed in purchase date
            CEP_AssetHelper.updateEntitlementsContarctsDates(triggerNew,triggerOld);
            afterUpdateRun = TRUE;
            
            List<Asset> assetList = new List<Asset>();
            for(Asset asst : triggerNew){ // Changed by Gokul CEP-5898
                if(asst.CEP_Country__c!=triggerOld.get(asst.Id).CEP_Country__c || asst.CEP_Product_Map__c!=triggerOld.get(asst.Id).CEP_Product_Map__c){
                    assetList.add(asst);
                }
            }
            CEP_AssetHelper.updateEntitlementsOnCountryUpdate(assetList);
            CEP_AssetHelper.assetTransferafterUpdate(triggerNew, triggerOld);
        }    
    }
}