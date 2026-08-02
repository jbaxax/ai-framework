/**
 * Business rules for authentication. Pure functions only.
 *
 * No React, no cookies, no crypto, no I/O. Time is passed in rather than read,
 * so every rule here is deterministic and testable without a clock.
 */

import type { LoginAttemptState, Session, User } from './types';

/** Sessions last one day and are not renewed. Re-login is expected tomorrow. */
export const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

export const MAX_FAILED_ATTEMPTS = 5;
export const LOCKOUT_MS = 15 * 60 * 1000;

/**
 * Emails are compared case-insensitively and without surrounding whitespace.
 * Without this, "Walter@Mail.com " and "walter@mail.com" are two accounts.
 */
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

/**
 * Milliseconds left before another attempt is allowed. `0` means unlocked.
 *
 * Rate limiting is a business rule, not a UI concern: it must hold no matter
 * which screen or client made the request.
 */
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

/** A successful login clears the counter; a lockout that expired resets too. */
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
