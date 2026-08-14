import { LightningElement, track } from 'lwc';
import getNewStoriesTiles from '@salesforce/apex/NewStoriesController.getNewStoriesTiles';

export default class NewStoriesTiles extends LightningElement {
    @track stories = [];
    @track isLoading = false;
    @track error;

    pageSize = 12;
    offset = 0;
    hasMore = true;
    _observer;
    _sentinel;

    connectedCallback() {
        this.loadStories();
    }

    renderedCallback() {
        this.setupInfiniteScroll();
    }

    disconnectedCallback() {
        this.disconnectObserver();
    }

    setupInfiniteScroll() {
        const sentinel = this.template.querySelector('.auto-scroll-sentinel');
        if (!sentinel) return;
        if (this._sentinel === sentinel) return;
        this.disconnectObserver();
        this._sentinel = sentinel;
        if (typeof IntersectionObserver === 'undefined') {
            return;
        }
        this._observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting && this.hasMore && !this.isLoading) {
                        this.loadStories();
                    }
                });
            },
            { root: null, rootMargin: '200px', threshold: 0 }
        );
        this._observer.observe(sentinel);
    }

    disconnectObserver() {
        if (this._observer) {
            try {
                this._observer.disconnect();
            } catch (e) {
                // ignore
            }
            this._observer = null;
        }
        this._sentinel = null;
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
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.setupInfiniteScroll(), 50);
        }
        if (!this.hasMore) {
            this.disconnectObserver();
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
