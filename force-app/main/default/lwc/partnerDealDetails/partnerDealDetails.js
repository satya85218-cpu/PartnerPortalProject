import { LightningElement, api, wire } from 'lwc';
import getPartnerDealDetails from '@salesforce/apex/PartnerDealController.getPartnerDealDetails';

export default class PartnerDealDetails extends LightningElement {

    @api recordId;

    deal;
    error;

    @wire(getPartnerDealDetails, { dealId: '$recordId' })
    wiredDeal({ data, error }) {

        if (data) {

            this.deal = {
                ...data,

                customerName: data.Customer_Account__r
                    ? data.Customer_Account__r.Name
                    : '',

                partnerName: data.Partner_Account__r
                    ? data.Partner_Account__r.Name
                    : ''
            };

            this.error = undefined;

        } else if (error) {

            this.error = error;
            this.deal = undefined;
        }
    }
}