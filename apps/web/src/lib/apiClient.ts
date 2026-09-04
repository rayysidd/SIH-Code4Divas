/**
 * API Client — Authenticated fetch wrapper for LabelLens backend.
 * Attaches Bearer token, handles 401 with refresh, redirects to login on failure.
 */

import { useAuthStore } from '../store/authStore';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

type RequestOptions = Omit<RequestInit, 'headers'> & {
  headers?: Record<string, string>;
  skipAuth?: boolean;
};

async function refreshAndRetry(url: string, options: RequestInit): Promise<Response> {
  const { refreshToken, logout } = useAuthStore.getState();

  if (!refreshToken) {
    logout();
    window.location.href = '/login';
    throw new Error('No refresh token available');
  }

  const refreshRes = await fetch(`${API_BASE}/v1/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });

  if (!refreshRes.ok) {
    logout();
    window.location.href = '/login';
    throw new Error('Token refresh failed');
  }

  const newTokens = await refreshRes.json();

  // TODO: Production hardening — use httpOnly cookies instead of localStorage
  localStorage.setItem('ll_access_token', newTokens.access_token);
  localStorage.setItem('ll_refresh_token', newTokens.refresh_token);

  useAuthStore.setState({
    accessToken: newTokens.access_token,
    refreshToken: newTokens.refresh_token,
  });

  // Retry original request with new token
  const retryHeaders = new Headers(options.headers);
  retryHeaders.set('Authorization', `Bearer ${newTokens.access_token}`);

  return fetch(url, { ...options, headers: retryHeaders });
}

async function apiFetch(path: string, options: RequestOptions = {}): Promise<Response> {
  const { accessToken } = useAuthStore.getState();
  const { headers = {}, skipAuth, ...rest } = options;

  const mergedHeaders: Record<string, string> = { ...headers };

  if (!skipAuth && accessToken) {
    mergedHeaders['Authorization'] = `Bearer ${accessToken}`;
  }

  // Only set Content-Type for non-FormData bodies
  if (rest.body && !(rest.body instanceof FormData) && !mergedHeaders['Content-Type']) {
    mergedHeaders['Content-Type'] = 'application/json';
  }

  const url = path.startsWith('http') ? path : `${API_BASE}${path}`;
  const res = await fetch(url, { ...rest, headers: mergedHeaders });

  if (res.status === 401 && !skipAuth) {
    return refreshAndRetry(url, { ...rest, headers: mergedHeaders });
  }

  return res;
}

/**
 * Typed GET request
 */
export async function apiGet<T>(path: string, options?: RequestOptions): Promise<T> {
  const res = await apiFetch(path, { ...options, method: 'GET' });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail || `GET ${path} failed (${res.status})`);
  }
  return res.json();
}

/**
 * Typed POST request (JSON body)
 */
export async function apiPost<T>(path: string, body?: unknown, options?: RequestOptions): Promise<T> {
  const res = await apiFetch(path, {
    ...options,
    method: 'POST',
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail || `POST ${path} failed (${res.status})`);
  }
  return res.json();
}

/**
 * Typed PATCH request (JSON body)
 */
export async function apiPatch<T>(path: string, body?: unknown, options?: RequestOptions): Promise<T> {
  const res = await apiFetch(path, {
    ...options,
    method: 'PATCH',
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail || `PATCH ${path} failed (${res.status})`);
  }
  return res.json();
}

/**
 * Typed DELETE request
 */
export async function apiDelete<T>(path: string, options?: RequestOptions): Promise<T> {
  const res = await apiFetch(path, {
    ...options,
    method: 'DELETE',
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail || `DELETE ${path} failed (${res.status})`);
  }
  return res.json();
}

/**
 * Multipart upload (for image scans)
 */
export async function apiUpload<T>(path: string, formData: FormData, options?: RequestOptions): Promise<T> {
  const res = await apiFetch(path, {
    ...options,
    method: 'POST',
    body: formData,
    // Don't set Content-Type — browser sets it with boundary for multipart
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail || `Upload to ${path} failed (${res.status})`);
  }
  return res.json();
}

/**
 * Health check (no auth required)
 */
export async function checkHealth() {
  try {
    const res = await fetch(`${API_BASE}/health`);
    return await res.json();
  } catch {
    return { status: 'offline' };
  }
}

export { API_BASE };
