import type { LoginAttemptState, Session, User } from './types';

export const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

export const MAX_FAILED_ATTEMPTS = 5;
export const LOCKOUT_MS = 15 * 60 * 1000;

export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

export function createSession(user: User, now: number): Session {
  return {
    user,
    issuedAt: now,
    expiresAt: now + SESSION_TTL_MS,
  };
}

export function isSessionExpired(session: Session, now: number): boolean {
  return now >= session.expiresAt;
}

export function lockoutRemainingMs(state: LoginAttemptState, now: number): number {
  if (state.failedAttempts < MAX_FAILED_ATTEMPTS || state.lastFailedAt === null) {
    return 0;
  }

  const remaining = state.lastFailedAt + LOCKOUT_MS - now;
  return remaining > 0 ? remaining : 0;
}

export function canAttemptLogin(state: LoginAttemptState, now: number): boolean {
  return lockoutRemainingMs(state, now) === 0;
}

export function registerFailure(state: LoginAttemptState, now: number): LoginAttemptState {
  const expired = state.lastFailedAt !== null && now >= state.lastFailedAt + LOCKOUT_MS;

  return {
    failedAttempts: expired ? 1 : state.failedAttempts + 1,
    lastFailedAt: now,
  };
}

export function clearFailures(): LoginAttemptState {
  return { failedAttempts: 0, lastFailedAt: null };
}
