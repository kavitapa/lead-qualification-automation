import { LightningElement, track, wire } from 'lwc';
import getQualifiedLeads from '@salesforce/apex/LeadDashboardController.getQualifiedLeads';
import assignToMe from '@salesforce/apex/LeadDashboardController.assignToMe';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class LeadDashboard extends LightningElement {
    @track leads = [];
    @track filteredLeads = [];
    @track isLoading = true;
    
    scoreFilter = 0;
    industryFilter = '';
    qualifiedOnly = false;
    wiredLeadsResult;

    columns = [
        { 
            label: 'Name', 
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        { 
            label: 'Email', 
            fieldName: 'Email',
            type: 'email'
        },
        { 
            label: 'Score', 
            fieldName: 'Lead_Score__c', 
            type: 'number',
            sortable: true,
            cellAttributes: {
                class: { fieldName: 'scoreClass' }
            }
        },
        { 
            label: 'Industry', 
            fieldName: 'Industry',
            type: 'text'
        },
        { 
            label: 'Status', 
            fieldName: 'statusLabel',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            }
        },
        {
            type: 'button',
            typeAttributes: {
                label: 'Assign to Me',
                name: 'assign',
                variant: 'brand',
                disabled: { fieldName: 'isAssignDisabled' }
            }
        }
    ];

    industryOptions = [
        { label: 'All Industries', value: '' },
        { label: 'Technology', value: 'Technology' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Manufacturing', value: 'Manufacturing' },
        { label: 'Retail', value: 'Retail' }
    ];

    @wire(getQualifiedLeads)
    wiredLeads(result) {
        this.wiredLeadsResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.leads = result.data.map(lead => ({
                ...lead,
                statusLabel: lead.Qualified__c ? 'Qualified' : 'Not Qualified',
                statusClass: lead.Qualified__c ? 'slds-text-color_success' : 'slds-text-color_weak',
                scoreClass: this.getScoreClass(lead.Lead_Score__c),
                isAssignDisabled: false
            }));
            this.applyFilters();
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
            console.error('Error fetching leads:', result.error);
            this.showToast('Error', 'Failed to fetch leads: ' + this.getErrorMessage(result.error), 'error');
        }
    }

    getScoreClass(score) {
        if (score >= 90) return 'slds-text-color_success';
        if (score >= 80) return 'slds-text-color_warning';
        return 'slds-text-color_weak';
    }

    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        return 'Unknown error occurred';
    }

    get hasLeads() {
        return this.filteredLeads && this.filteredLeads.length > 0;
    }

    get resultsLabel() {
        const count = this.filteredLeads ? this.filteredLeads.length : 0;
        return `${count} Lead${count !== 1 ? 's' : ''} Found`;
    }

    get qualifiedLabel() {
        const qualifiedCount = this.filteredLeads ? 
            this.filteredLeads.filter(lead => lead.Qualified__c).length : 0;
        return `${qualifiedCount} Qualified`;
    }

    get hasQualifiedLeads() {
        return this.filteredLeads && this.filteredLeads.some(lead => lead.Qualified__c);
    }

    handleScoreChange(event) {
        this.scoreFilter = parseInt(event.target.value, 10);
        this.applyFilters();
    }

    handleIndustryChange(event) {
        this.industryFilter = event.target.value;
        this.applyFilters();
    }

    handleQualifiedChange(event) {
        this.qualifiedOnly = event.target.checked;
        this.applyFilters();
    }

    applyFilters() {
        if (!this.leads) {
            this.filteredLeads = [];
            return;
        }

        this.filteredLeads = this.leads.filter(lead => {
            const scoreMatch = !this.scoreFilter || (lead.Lead_Score__c >= this.scoreFilter);
            const industryMatch = !this.industryFilter || lead.Industry === this.industryFilter;
            const qualifiedMatch = !this.qualifiedOnly || lead.Qualified__c;
            
            return scoreMatch && industryMatch && qualifiedMatch;
        });
    }

    async handleRowAction(event) {
        const leadId = event.detail.row.Id;
        const leadName = event.detail.row.Name;
        
        try {
            await assignToMe({ leadId });
            this.showToast('Success', `Lead "${leadName}" has been assigned to you`, 'success');
            
            // Refresh the data
            await refreshApex(this.wiredLeadsResult);
        } catch (error) {
            console.error('Assignment error:', error);
            this.showToast('Error', 'Failed to assign lead: ' + this.getErrorMessage(error), 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}