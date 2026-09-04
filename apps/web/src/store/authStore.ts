/**
 * Auth Store — Zustand state management for JWT authentication.
 * Manages access/refresh tokens, user profile, and auth lifecycle.
 *
 * Token storage: localStorage for hackathon demo.
 * // TODO: Production hardening — use httpOnly cookies set by the backend
 * // to prevent XSS-based token theft. localStorage is not secure for
 * // sensitive tokens in a production environment.
 */

import { create } from 'zustand';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export interface AuthUser {
  user_id: string;
  username: string;
  full_name: string;
  role: 'ADMIN' | 'INSPECTOR' | 'QA_MANAGER' | 'ECOM_LEAD' | 'CITIZEN';
}

export interface RegisterResult {
  role: string;
  message: string;
}

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: AuthUser | null;
  isLoading: boolean;
  error: string | null;

  login: (username: string, password: string) => Promise<void>;
  register: (
    username: string,
    password: string,
    fullName: string,
    email: string,
    inviteCode?: string,
  ) => Promise<RegisterResult>;
  logout: () => void;
  rehydrate: () => Promise<void>;
  clearError: () => void;
}

/**
 * Shared helper: store tokens in localStorage and fetch user profile via /me.
 * Used by both login and register to avoid duplicating this logic.
 */
async function _storeTokensAndFetchProfile(
  accessToken: string,
  refreshToken: string,
  set: (partial: Partial<AuthState>) => void,
): Promise<void> {
  // TODO: Production hardening — tokens should be set as httpOnly cookies
  localStorage.setItem('ll_access_token', accessToken);
  localStorage.setItem('ll_refresh_token', refreshToken);

  set({ accessToken, refreshToken });

  const meRes = await fetch(`${API_BASE}/v1/auth/me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (meRes.ok) {
    const user = await meRes.json();
    set({ user, isLoading: false });
  } else {
    throw new Error('Failed to fetch user profile');
  }
}

export const useAuthStore = create<AuthState>((set, get) => ({
  accessToken: null,
  refreshToken: null,
  user: null,
  isLoading: false,
  error: null,

  login: async (username: string, password: string) => {
    set({ isLoading: true, error: null });
    try {
      const res = await fetch(`${API_BASE}/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Login failed');
      }

      const tokens = await res.json();
      await _storeTokensAndFetchProfile(tokens.access_token, tokens.refresh_token, set);
    } catch (err: any) {
      set({ isLoading: false, error: err.message || 'Login failed' });
      throw err;
    }
  },

  register: async (
    username: string,
    password: string,
    fullName: string,
    email: string,
    inviteCode?: string,
  ): Promise<RegisterResult> => {
    set({ isLoading: true, error: null });
    try {
      const body: Record<string, string> = {
        username,
        password,
        full_name: fullName,
        email,
      };
      if (inviteCode?.trim()) {
        body.invite_code = inviteCode.trim();
      }

      const res = await fetch(`${API_BASE}/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Registration failed');
      }

      const data = await res.json();

      // Register returns tokens — reuse the shared helper
      await _storeTokensAndFetchProfile(data.access_token, data.refresh_token, set);

      return { role: data.role, message: data.message };
    } catch (err: any) {
      set({ isLoading: false, error: err.message || 'Registration failed' });
      throw err;
    }
  },

  logout: () => {
    localStorage.removeItem('ll_access_token');
    localStorage.removeItem('ll_refresh_token');
    set({
      accessToken: null,
      refreshToken: null,
      user: null,
      isLoading: false,
      error: null,
    });
  },

  rehydrate: async () => {
    const accessToken = localStorage.getItem('ll_access_token');
    const refreshToken = localStorage.getItem('ll_refresh_token');

    if (!accessToken) {
      set({ isLoading: false });
      return;
    }

    set({ isLoading: true, accessToken, refreshToken });

    try {
      const meRes = await fetch(`${API_BASE}/v1/auth/me`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (meRes.ok) {
        const user = await meRes.json();
        set({ user, isLoading: false });
        return;
      }

      // Access token expired — try refresh
      if (meRes.status === 401 && refreshToken) {
        const refreshRes = await fetch(`${API_BASE}/v1/auth/refresh`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refresh_token: refreshToken }),
        });

        if (refreshRes.ok) {
          const newTokens = await refreshRes.json();
          localStorage.setItem('ll_access_token', newTokens.access_token);
          localStorage.setItem('ll_refresh_token', newTokens.refresh_token);

          const retryMe = await fetch(`${API_BASE}/v1/auth/me`, {
            headers: { Authorization: `Bearer ${newTokens.access_token}` },
          });

          if (retryMe.ok) {
            const user = await retryMe.json();
            set({
              accessToken: newTokens.access_token,
              refreshToken: newTokens.refresh_token,
              user,
              isLoading: false,
            });
            return;
          }
        }
      }

      // All attempts failed — clear state
      get().logout();
    } catch {
      get().logout();
    }
  },

  clearError: () => set({ error: null }),
}));

