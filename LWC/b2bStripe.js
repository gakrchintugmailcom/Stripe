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
import { LightningElement,api,wire,track } from 'lwc';
import getPaymentInfo from '@salesforce/apex/B2BPaymentController.getPaymentInfo';
import { NavigationMixin } from 'lightning/navigation';
import setPaymentInfo from '@salesforce/apex/B2BPaymentController.setPaymentInfo';
import getPoLimit from '@salesforce/apex/B2BPaymentController.getPoLimit';
import getSingleContact from '@salesforce/apex/B2BPaymentController.getSingleContact';
import methodName from '@salesforce/apex/B2BPaymentController.methodName';
//import getBuyerInfo from '@salesforce/apex/B2B_InventoryController.getBuyerInfo';

import cartPoDetails from '@salesforce/apex/B2BPaymentController.cartPoDetails'
import getVFOrigin from '@salesforce/apex/B2BPaymentController.getVFOrigin';

import updatePAError from '@salesforce/apex/B2BPaymentController.updatePaymentAuthError';

import submitCreditCardOrder from '@salesforce/apex/B2BPaymentController.submitCreditCardOrder';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class B2bStripe extends LightningElement {

    @api cartId;
    @api recordId;
    @api Account;
    @track purchaseNumber = '';
    @api purchaseNumber;
    @api orderNo;
    PoLimit;
    aval;

    purchaseNumber;
    cart;
    iframeUrl;
    showPo;
    
    // Wire getVFOrigin Apex method to a Property
    @wire(getVFOrigin)
    vfOrigin;
    @wire(getSingleContact) 
    result({data,error})
    {
        if(data)
        {
           this.showPo = data;
            console.log(data);
            cartPoDetails({cartId:this.cartId,cartPoNumber:this.purchaseNumber})
            .then((result)=>{console.log(result)})
            .catch((error)=>{console.log(error.message)});
             getPoLimit({cartId:this.cartId}) 
            .then((result)=>{
               this.PoLimit = result;
               console.log('PodetailsCheck',this.PoLimit)})
            .catch((error)=>{console.log(error.message)});
        }
        if(error)
        {
            console.log(error)
        }
    }
    
    // @track pono = '';
    // @track showpo;
    canPay = false;
    stripeCustomerId = '';
    iframeUrl;
    showSpinner = false;
    connectedCallback() {
        window.addEventListener("message", this.handleVFResponse.bind(this));
        let dataMap = {
            cartId: this.cartId
        };
        this.showSpinner = true;
        getPaymentInfo({
            dataMap: dataMap
        }).then((result) => {
                this.showSpinner = false;
                console.log(result);
                if (result && result.isSuccess) {
                    this.canPay = result.canPay;
                    this.cart = result.cart;
                    this.stripeCustomerId = result.stripeCustomerId ;
                    this.iframeUrl = result.iframeUrl;
                } else {
                    this.showToast('No payment Methods Found', 'error');
                }
            })
            .catch((e) => {
                this.showToast(
                    'Some Error occured while processing this Opportunity,Please contact System admin.',
                    'error'
                );
            });
    }

    showToast(message ,variant) {
        let title = variant == 'error' ? 'Error' : 'Success';
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleVFResponse(message){
        console.log('handleVFResponse');
        console.log(message);
        var cmp = this;
        if (this.vfOrigin.data.indexOf(message.origin)!==-1) {
            let receivedMessage = message.data;

            if(receivedMessage && receivedMessage != null){
                if(receivedMessage.hasOwnProperty('paId')){
                    let dataMap = {
                        paId: receivedMessage.paId
                    }
                    updatePAError({dataMap: dataMap})
                    .then(function (result) {
                        cmp.showSpinner = false;
                    });
                }else{
                    if(receivedMessage.cToken && receivedMessage.cToken != null &&  receivedMessage.cToken.token && receivedMessage.cToken.token != null){
                        if(this.submitOrderCalled){
                            return ;
                        }
                        this.submitOrderCalled = true;
                        this.submitCCOrder(receivedMessage);
                    }
                }
            }
        }
    }
    



    submitCCOrder(receivedMessage){
        let dataMap = {
            "cartId": this.cartId,
            "paymentMethod": 'CC',
            "stripeCustomerId": this.stripeCustomerId,
            "cToken": receivedMessage.cToken.token,
            "cPay" : receivedMessage.cPay.paymentIntent,
            "cTokenId": receivedMessage.cToken.token.id,
            "cPayId" : receivedMessage.cPay.paymentIntent.id
        };
        submitCreditCardOrder({
            dataMap: dataMap
        }).then((result) => {
            this.showSpinner = false;
            if(result && result.isSuccess){
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }else{
                this.showToast(result.msg,'error');
            }
        }).catch((e) => {
            this.showToast(
                e.message,
                'error'
            );
        });
    }

    errorCallback(err) {
        alert(err);
    }

    submitOrder(){
        let dataMap = {
            "cartId": this.cartId,
            "paymentMethod": 'CC',
            "stripeCustomerId": this.stripeCustomerId
        };
        this.showSpinner = true;
        setPaymentInfo({
            dataMap: dataMap
        }).then((result) => {
            console.log(result);
            if(result && result.PI_Secret){
                result.billing_details = {
                    name : this.cart.CreatedBy.Name,
                    email : this.cart.CreatedBy.Email
                };
                this.handleFiretoVF(result);
            }
        }).catch((e) => {
            this.showToast(
                e.message,
                'error'
            );
        });
        
       
    }


    handleFiretoVF(message) {
        console.log('handleFiretoVF');
        this.template.querySelector("iframe").contentWindow.postMessage(message, this.vfOrigin.data);
    }
//     handlePoInput(event)
//     {
//      this.pono = event.target.value;   
//     }



  
    getPoNum(event){
        this.purchaseNumber = event.target.value;
        console.log(this.purchaseNumber);
    }
 CreditLimit
 @wire(methodName) 
 results({data,error})
  { if(data){
    this.CreditLimit = data;
    console.log(this.CreditLimit);
  } 
  if(error){
    console.log(error);
  }

 }
   
 submitOrderPo()

 {
     
     const navigateNextEvent  = new FlowNavigationNextEvent();this.dispatchEvent(navigateNextEvent);


 }
}