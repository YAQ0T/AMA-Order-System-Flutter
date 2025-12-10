const DEFAULT_API_PORT = '3004';

const normalizeBaseUrl = (url) => {
    if (!url) return null;
    return url.endsWith('/') ? url.slice(0, -1) : url;
};

const buildDefaultApiUrl = () => {
    const { protocol, hostname } = window.location;
    return `${protocol}//${hostname}:${DEFAULT_API_PORT}`;
};

export const API_BASE_URL = normalizeBaseUrl(import.meta.env.VITE_API_URL) || buildDefaultApiUrl();

export const updateItemStatus = async (itemId, status) => {
    const response = await fetch(`${API_BASE_URL}/api/items/${itemId}/status`, {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ status }),
    });

    if (!response.ok) {
        throw new Error('Failed to update item status');
    }

    return response.json();
};
