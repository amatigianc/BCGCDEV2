import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import createUpdatePricebookEntries from '@salesforce/apex/PricebookManagerController.createUpdatePricebookEntries';

export default class PricebookEntryModal extends LightningModal {
    @api actionType;
    @api pricebookEntry;
    @api productId;

    trueValue = true;

    standardPricebookId = '01s8c000002oewFAAQ';

    handleOkay () {
        const stdBtn = this.template.querySelector('.hidden');
        if (stdBtn) {
            stdBtn.click();
        }
    }

    handleCreateUpdateSuccess (event) {
        let productId = event.detail.fields.Product2Id.value;
        let pricebookId = event.detail.fields.Pricebook2Id.value;
        let price = event.detail.fields.UnitPrice.value;

        createUpdatePricebookEntries({
            product2Id: productId,
            pricebook2Id: pricebookId,
            unitPrice: price
        }).then(() => {
            this.close('created-updated');
        });
    }

    get isEdit () {
        return this.actionType == 'edit';
    }

    get isCreateStandard () {
        return this.actionType == 'create-standard';
    }

    get isCreatePricebook () {
        return this.actionType == 'create-pricebook';
    }
}