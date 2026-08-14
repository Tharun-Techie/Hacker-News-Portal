import { LightningElement, track } from 'lwc';
import getNewStoriesTiles from '@salesforce/apex/NewStoriesController.getNewStoriesTiles';

export default class NewStoriesTiles extends LightningElement {
    @track stories = [];
    @track isLoading = false;
    @track error;

    pageSize = 12;
    offset = 0;
    hasMore = true;

    connectedCallback() {
        this.loadStories();
    }

    async loadStories() {
        if (this.isLoading || !this.hasMore) return;
        this.isLoading = true;
        this.error = null;
        try {
            const result = await getNewStoriesTiles({ pageSize: this.pageSize, offset: this.offset });
            if (result && result.length > 0) {
                // Append, ensure per-tile id unique
                this.stories = [...this.stories, ...result];
                this.offset += result.length;
                if (result.length < this.pageSize) {
                    this.hasMore = false;
                }
            } else {
                this.hasMore = false;
            }
        } catch (e) {
            this.error = e.body?.message || e.message || 'Unknown error';
        } finally {
            this.isLoading = false;
        }
    }

    handleLoadMore() {
        this.loadStories();
    }

    handleRefresh() {
        this.stories = [];
        this.offset = 0;
        this.hasMore = true;
        this.error = null;
        this.loadStories();
    }

    handleOpenUrl(event) {
        const url = event.currentTarget.dataset.url;
        if (url) {
            window.open(url, '_blank');
        }
    }

    get isEmpty() {
        return !this.isLoading && this.stories.length === 0 && !this.error;
    }

    get hasStories() {
        return this.stories.length > 0;
    }
}
