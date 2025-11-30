import { LightningElement, api, wire } from 'lwc';
import getAccountHealth from '@salesforce/apex/AccountHealthController.getAccountHealth';

export default class AccountHealthDashboard extends LightningElement {
    @api recordId;
    
    healthData;
    error;
    isLoading = true;
    
    @wire(getAccountHealth, { accountId: '$recordId' })
    wiredHealth({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.healthData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.healthData = undefined;
        }
    }
    
    get hasData() {
        return this.healthData && !this.isLoading;
    }
    
    get hasError() {
        return this.error && !this.isLoading;
    }
    
    get errorMessage() {
        return this.error?.body?.message || 'An error occurred loading account health data.';
    }
    
    get formattedLastActivity() {
        if (!this.healthData?.lastActivityDate) {
            return 'None';
        }
        const date = new Date(this.healthData.lastActivityDate);
        return date.toLocaleDateString();
    }
    
    get healthScoreClass() {
        const score = this.healthData?.healthScore || 0;
        let colorClass = 'score-low';
        if (score >= 70) {
            colorClass = 'score-high';
        } else if (score >= 40) {
            colorClass = 'score-medium';
        }
        return `score-circle ${colorClass}`;
    }
}