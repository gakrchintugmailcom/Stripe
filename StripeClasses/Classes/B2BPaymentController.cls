/**
 * @description       :
 * @author            : Abhishek
 * @group             : RafterOne
 * @last modified on  : 01-13-2023
 * @last modified by  : Abhishek
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   01-13-2023   Abhishek   Initial Version
**/
public with sharing class B2BPaymentController {

    @AuraEnabled
    public static map<String,Object> getPaymentInfo(map<String,Object> dataMap){
        String methodName = 'getPaymentInfo';
        String supportData = '';
        
        try{
            dataMap = B2BStripeIntegrationController.getPaymentOptions(dataMap);
        } catch (Exception ex) {
            dataMap = dataMap==null ? new Map<String,Object>() : dataMap ;
            dataMap.put(B2BConstants.IS_SUCCESS,false);
            dataMap.put(B2BConstants.MESSAGE,ex.getMessage()+' '+ex.getStackTraceString());
        }
        return dataMap;
    }

    @AuraEnabled(cacheable=true)
    public static string getVFOrigin() {
        Site site = [SELECT Id FROM Site WHERE UrlPathPrefix = 'Bike' LIMIT 1];
        String communityUrl = [SELECT SecureURL FROM SiteDetail WHERE DurableId =: site.Id].SecureUrl;
        System.debug('Community url: ' + communityUrl);
        return communityUrl;

    }
    @AuraEnabled(cacheable=true)
    public static Boolean  getSingleContact(){
     String accountId = [SELECT Accountid FROM User WHERE id = :userInfo.getUserId()].accountId;
     Account act = [SELECT Id,PO__c,PurchaseOrderWallet__c From Account where Id= :accountId];
     Boolean ShowPo = act.PO__c;
     return ShowPo;

    }
    @AuraEnabled
    public static Boolean  getPoLimit(string cartId){
   try{
    String accountId = [SELECT Accountid FROM User WHERE id = :userInfo.getUserId()].accountId;
    Account act = [SELECT Id,PO__c,PurchaseOrderWallet__c From Account where Id= :accountId];
    Decimal PoDetails = act.PurchaseOrderWallet__c;
    Decimal CartTotal = [Select id,GrandTotalAmount from webcart where id =: cartId].GrandTotalAmount;
    if(PoDetails<= CartTotal){
        return true;
    }
    return false;
   }
   catch (Exception e) {
    throw new AuraHandledException('error in cartPoDetails'+e.getMessage());
} 
       }
       @AuraEnabled(cacheable=true)
       public static decimal  getPoLimitCredit(){
        try{
           // String accountId = [SELECT Accountid FROM User WHERE id = :userInfo.getUserId()].accountId;
       
        String accountId = '0013C00000muMHqQAM';
         Account act = [SELECT Id,PO__c,PurchaseOrderWallet__c From Account where Id= :accountId];
         Decimal PoDetails = act.PurchaseOrderWallet__c;
         //Decimal CartTotal = [Select id,GrandTotalAmount from webcart where id =: cartId].GrandTotalAmount;
         
             return PoDetails;
        
        }
        catch (Exception e) {
         throw new AuraHandledException('error in cartPoDetails'+e.getMessage());
     } 
            }

    @AuraEnabled
    public static string cartPoDetails(string cartId,string cartPoNumber){
        try {
            WebCart cart = [select id,PoNumber From WebCart where id = :cartId];
            cart.PoNumber = cartPoNumber;
            update cart;
            return 'Update Successfully';
            
        } catch (Exception e) {
            throw new AuraHandledException('error in cartPoDetails'+e.getMessage());
        }
    }



    @AuraEnabled
    public static map<String,Object> setPaymentInfo(map<String,Object> dataMap){
        String methodName = 'setPaymentInfo';
        String supportData = '';
        try{
            dataMap = B2BStripeIntegrationController.setPaymentInfo(dataMap);
        } catch (Exception ex) {
            dataMap = dataMap==null ? new Map<String,Object>() : dataMap ;
            dataMap.put(B2BConstants.IS_SUCCESS,false);
            dataMap.put(B2BConstants.MESSAGE,ex.getMessage());
        }
        return dataMap;
    }

    @AuraEnabled
    public static map<String,Object> updatePaymentAuthError(map<String,Object> dataMap){
        String methodName = 'updatePaymentAuthError';
        String supportData = '';
        try{
            String paId = (String)dataMap.get('paId') ;
            List<PaymentAuthorization> paList = [SELECT Id, Status, GatewayAuthCode, SfResultCode FROM PaymentAuthorization WHERE Id =: paId LIMIT 100];
            for(PaymentAuthorization pa: paList){ pa.status = 'Canceled';
            }
            if(!paList.isEmpty()){ update paList;
            }
        } catch (Exception ex) {
            dataMap = dataMap==null ? new Map<String,Object>() : dataMap ;
            dataMap.put(B2BConstants.IS_SUCCESS,false);
            dataMap.put(B2BConstants.MESSAGE,ex.getMessage());
        }finally
        {
            //B2BUtils.handleApplicationLogging(dataMap);
        }
        return dataMap;
    }

    @AuraEnabled
    public static map<String,Object> submitCreditCardOrder(map<String,Object> dataMap){
        String methodName = 'submitCreditCardOrder';
        String supportData = '';
        try{
            dataMap = B2BStripeIntegrationController.chargeCustomer(dataMap);
            updateOrderInformation(dataMap);
        } catch (Exception ex) {
            dataMap = dataMap==null ? new Map<String,Object>() : dataMap ;
            dataMap.put(B2BConstants.IS_SUCCESS,false);
            dataMap.put(B2BConstants.MESSAGE,ex.getMessage());
        }finally
        {
            //B2BUtils.handleApplicationLogging(dataMap);
        }
        return dataMap;
    }

    public static map<String,Object> updateOrderInformation(map<String,Object> dataMap){
        String cartId = (String)dataMap.get(B2BConstants.CART_ID) ;
        String paymentMethod = (String)dataMap.get('paymentMethod') ;
        List<CartCheckoutSession> sessions = B2BStripeIntegrationController.getActiveCheckoutSessions(cartId);
            if(!sessions.isEmpty() && String.isNotBlank(sessions.get(0).OrderId)){
                String orderId = sessions.get(0).OrderId;
                Order o = new Order();
                o.Id = orderId;
                o.Stripe_Transaction_ID__c =  (String)dataMap.get('chargeId')   ;
                update o;
            }
        return dataMap;
    }
    @AuraEnabled(cacheable = true)
    public static Decimal methodName(){
        try {
            //String accountId = [SELECT Accountid FROM User WHERE id = :userInfo.getUserId()].accountId;
            string accountId= '0013C00000muMHqQAM';
            Account act = [SELECT Id,PO__c,PurchaseOrderWallet__c From Account where Id= :accountId];
            Decimal PoDetails = act.PurchaseOrderWallet__c;
            return PoDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}