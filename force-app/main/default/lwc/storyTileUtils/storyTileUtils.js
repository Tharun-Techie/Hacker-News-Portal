/**
 * Shared utilities for story tile LWCs (top/best/new)
 * Eliminates ~320 lines of JS duplication across 3 components
 */
export function createInfiniteScrollState() {
    return { observer: null, sentinel: null };
}

export function setupInfiniteScroll({ template, hasMore, isLoading, loadFn, state }) {
    const sentinel = template.querySelector('.auto-scroll-sentinel');
    if (!sentinel) return;
    if (state.sentinel === sentinel) return;
    disconnectObserver(state);
    state.sentinel = sentinel;
    if (typeof IntersectionObserver === 'undefined') return;
    state.observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting && hasMore && !isLoading) {
                    loadFn();
                }
            });
        },
        { root: null, rootMargin: '200px', threshold: 0 }
    );
    state.observer.observe(sentinel);
}

export function disconnectObserver(state) {
    if (state.observer) {
        try { state.observer.disconnect(); } catch (e) { /* ignore */ }
        state.observer = null;
    }
    state.sentinel = null;
}

export async function loadStoriesUtil({ apexFn, state, pageSize, offsetKey = 'offset', hasMoreKey = 'hasMore', storiesKey = 'stories' }) {
    if (state.isLoading || !state[hasMoreKey]) return;
    state.isLoading = true;
    state.error = null;
    try {
        const result = await apexFn({ pageSize: state.pageSize, offset: state[offsetKey] });
        if (result && result.length > 0) {
            state[storiesKey] = [...state[storiesKey], ...result];
            state[offsetKey] += result.length;
            if (result.length < state.pageSize) state[hasMoreKey] = false;
        } else {
            state[hasMoreKey] = false;
        }
    } catch (e) {
        state.error = e.body?.message || e.message || 'Unknown error';
    } finally {
        state.isLoading = false;
    }
}

export function handleOpenUrl(event) {
    const url = event.currentTarget.dataset.url;
    if (url) window.open(url, '_blank');
}
