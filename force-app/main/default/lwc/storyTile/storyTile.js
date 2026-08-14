import { LightningElement, api } from 'lwc';

export default class StoryTile extends LightningElement {
    @api story;
    @api variant = 'top'; // top | best | new

    get badgeClass() {
        return this.variant === 'top' ? 'slds-badge slds-theme_warning' : 'slds-badge slds-theme_success';
    }
    get headerStyle() {
        // top uses eef4ff, best/new use f3f6f9 - centralized
        return this.variant === 'top'
            ? 'background:#eef4ff; border-bottom:1px solid #d8dde6;'
            : 'background:#f3f6f9; border-bottom:1px solid #e5e5e5;';
    }
    handleOpenUrl(event) {
        const url = event.currentTarget.dataset.url;
        if (url) window.open(url, '_blank');
    }
}
