/**
 * Cookie handling. Server-only.
 *
 * The token lives in an `HttpOnly` cookie: unreadable by JavaScript, so an XSS
 * cannot exfiltrate the session. It is never placed in `localStorage`.
 */

import { cookies } from 'next/headers';
import type { Session } from '../domain/types';
import { isSessionExpired } from '../domain/session';
import { findSession, revokeSession } from './userStore.server';

const COOKIE_NAME = 'session';

export async function setSessionCookie(token: string, expiresAt: number): Promise<void> {
  const store = await cookies();

  store.set(COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    expires: new Date(expiresAt),
  });
}

export async function clearSessionCookie(): Promise<void> {
  const store = await cookies();
  const token = store.get(COOKIE_NAME)?.value;

  if (token) {
    // Revoke server-side too. Deleting only the cookie leaves the session valid.
    revokeSession(token);
  }

  store.delete(COOKIE_NAME);
}

/** Returns the live session, or null when missing, unknown, or expired. */
export async function readSession(now: number = Date.now()): Promise<Session | null> {
  const store = await cookies();
  const token = store.get(COOKIE_NAME)?.value;

  if (!token) return null;

  const session = findSession(token);
  if (!session) return null;

  if (isSessionExpired(session, now)) {
    revokeSession(token);
    return null;
  }

  return session;
}
