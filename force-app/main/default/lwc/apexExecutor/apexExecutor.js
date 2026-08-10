import { LightningElement, track } from 'lwc';
import executeSnippet from '@salesforce/apex/ApexExecutorController.executeSnippet';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApexExecutor extends LightningElement {
    @track codeSnippet = '';
    @track executionResult = '';
    @track isExecuting = false;

    handleCodeChange(event) {
        this.codeSnippet = event.target.value;
    }

    async handleExecute() {
        if (!this.codeSnippet) {
            this.showToast('Warning', 'Please enter some Apex code to execute.', 'warning');
            return;
        }

        this.isExecuting = true;
        this.executionResult = '';

        try {
            const result = await executeSnippet({ apexCode: this.codeSnippet });
            this.executionResult = result;
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isExecuting = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}