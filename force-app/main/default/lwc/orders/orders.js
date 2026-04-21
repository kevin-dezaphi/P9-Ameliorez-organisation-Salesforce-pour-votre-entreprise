import { LightningElement, api } from 'lwc';
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

export default class Orders extends LightningElement {

    sumOrdersOfCurrentAccount;
    showError = false;
    @api recordId;

    connectedCallback() {
        this.fetchSumOrders();
    }

    fetchSumOrders() {
        getSumOrdersByAccount({ accountId: this.recordId })
            .then(result => {
                this.sumOrdersOfCurrentAccount = result;
                this.showError = !this.sumOrdersOfCurrentAccount || this.sumOrdersOfCurrentAccount <= 0;
            })
            .catch(error => {
                this.sumOrdersOfCurrentAccount = 0;
                this.showError = true;
                console.error('Error fetching sum of orders:', error);
            });
    }
}