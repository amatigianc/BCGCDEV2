import { LightningElement, wire, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUSDPricebookEntry from '@salesforce/apex/PricebookManagerController.getUSDPricebookEntry';
import toggleActivation from '@salesforce/apex/PricebookManagerController.toggleActivation';
import deletePricebookEntry from '@salesforce/apex/PricebookManagerController.deletePricebookEntry';
import PricebookEntryModal from 'c/pricebookEntryModal';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Toggle Activation', name: 'toggle-activation' },
    { label: 'Delete', name: 'delete' }
];

const pricebookColumns = [
    { label: 'Active', fieldName: 'IsActive', type: 'boolean' },
    { label: 'Pricebook', fieldName: 'Pricebook_Name__c' },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];

export default class PricebookManager extends LightningElement {
    @api recordId;
    @track hasStandardEntry = false;
    @track isLoaded = false;
    hasCustomEntry = false;

    @track pricebookEntries;
    pricebookColumns = pricebookColumns;

    connectedCallback () {
        this.refreshData();
    }

    refreshData () {
        this.isLoaded = false;
        this.pricebookEntries = undefined;
        this.hasStandardEntry = false;
        this.hasCustomEntry = false;
        getUSDPricebookEntry({ recordId: this.recordId }).then(res => {
            res.forEach(entry => {
                if (entry.Pricebook_Name__c == 'Standard Price Book') {
                    this.hasStandardEntry = true;
                }
                if (entry.Pricebook_Name__c != 'Standard Price Book') {
                    this.hasCustomEntry = true;
                }
            });
            this.pricebookEntries = res;
            this.isLoaded = true;
        }).catch(error => {
            this.isLoaded = true;
        });        
    }

    handleRowAction (event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'delete':
                this.deleteRow(row.Id);
                break;
            case 'toggle-activation':
                this.toggleActivation(row.Id);
                break;
            case 'edit':
                this.editRow(row.Id);
                break;
            default:
        }
    }

    async deleteRow (rowId) {
        var pricebookEntry = this.getPricebookEntryFromRow(rowId);

        if (
            this.hasCustomEntry &&
            pricebookEntry.Pricebook_Name__c == 'Standard Price Book'
        ) {
            //throw error they can't delete standard before all custom ones
            const event = new ShowToastEvent({
                title: 'Error',
                message:
                    'Unable to delete. Delete all other Pricebook Entries before deleting the Standard Pricebook Entry',
                variant: 'error',
                mode: 'pester'
            });
            this.dispatchEvent(event);
            console.error(
                'Unable to delete standard price book while other pricebooks exist'
            );
            return;
        }

        if (pricebookEntry) {
            const result = await LightningConfirm.open({
                message:
                    'Are you sure you want to delete this Pricebook Entry?',
                variant: 'header',
                theme: 'warning',
                label: 'Do you want to delete this Pricebook Entry'
            });

            if (result) {
                deletePricebookEntry({ pbe: pricebookEntry }).then(res => {
                    this.refreshData();
                });
            }
        }
    }

    async editRow (rowId) {
        var pricebookEntry = this.getPricebookEntryFromRow(rowId);

        if (pricebookEntry) {
            const result = await PricebookEntryModal.open({
                size: 'medium',
                label: 'Edit Pricebook Entry',
                description: 'Edit a Pricebook Entry',
                pricebookEntry: pricebookEntry,
                actionType: 'edit'
            });

            this.refreshData();
        }
    }

    toggleActivation (rowId) {
        var pricebookEntry = this.getPricebookEntryFromRow(rowId);

        if (pricebookEntry) {
            toggleActivation({ pbe: pricebookEntry }).then(res => {
                this.refreshData();
            });
        }
    }

    getPricebookEntryFromRow (rowId) {
        return this.pricebookEntries.find(element => element.Id == rowId);
    }

    async handleCreatePricebookEntry () {
        const result = await PricebookEntryModal.open({
            size: 'medium',
            label: 'Create Pricebook Entry',
            description: 'Create Pricebook Entry',
            content: 'These are not the droids you are looking for',
            actionType: 'create-pricebook',
            productId: this.recordId
        });

        this.refreshData();
    }

    async handleCreateStandardEntry () {
        const result = await PricebookEntryModal.open({
            size: 'medium',
            label: 'Create Standard Entry',
            description: 'Create Standard Entry',
            content: 'Hello There',
            actionType: 'create-standard',
            productId: this.recordId
        });

        this.refreshData();
    }
}