/**
 * Infrastructure. Stands in for a database.
 *
 * In a real project this is Prisma or Supabase. The point of keeping it here is
 * that `domain/` never learns how users are stored — swapping this file for a
 * real database changes nothing else in the feature.
 *
 * Password hashing uses `node:crypto`. Never hand-roll crypto.
 */

import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import type { LoginAttemptState, Session, User } from '../domain/types';
import { clearFailures } from '../domain/session';

interface StoredUser extends User {
  readonly passwordSalt: string;
  readonly passwordHash: string;
}

function hashPassword(password: string, salt: string): string {
  return scryptSync(password, salt, 64).toString('hex');
}

function seedUser(email: string, password: string, displayName: string): StoredUser {
  const passwordSalt = randomBytes(16).toString('hex');

  return {
    id: randomBytes(8).toString('hex'),
    email,
    displayName,
    passwordSalt,
    passwordHash: hashPassword(password, passwordSalt),
  };
}

// Demo data. A real project seeds through migrations, never in application code.
const users = new Map<string, StoredUser>();
const demo = seedUser('walter@example.com', 'correct-horse-battery', 'Walter');
users.set(demo.email, demo);

const attemptsByEmail = new Map<string, LoginAttemptState>();
const sessionsByToken = new Map<string, Session>();

export function findUserByEmail(email: string): StoredUser | null {
  return users.get(email) ?? null;
}

/**
 * Constant-time comparison. A plain `===` leaks how much of the hash matched
 * through response timing.
 */
export function verifyPassword(user: StoredUser, password: string): boolean {
  const candidate = Buffer.from(hashPassword(password, user.passwordSalt), 'hex');
  const expected = Buffer.from(user.passwordHash, 'hex');

  return candidate.length === expected.length && timingSafeEqual(candidate, expected);
}

export function getAttemptState(email: string): LoginAttemptState {
  return attemptsByEmail.get(email) ?? clearFailures();
}

export function setAttemptState(email: string, state: LoginAttemptState): void {
  attemptsByEmail.set(email, state);
}

export function createSessionToken(session: Session): string {
  const token = randomBytes(32).toString('hex');
  sessionsByToken.set(token, session);
  return token;
}

export function findSession(token: string): Session | null {
  return sessionsByToken.get(token) ?? null;
}

export function revokeSession(token: string): void {
  sessionsByToken.delete(token);
}

/** Server-side sessions can be revoked. A stateless JWT cannot. */
export function toPublicUser(user: StoredUser): User {
  return { id: user.id, email: user.email, displayName: user.displayName };
}
