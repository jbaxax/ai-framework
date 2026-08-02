/** Domain types. No framework, no library, no I/O. */

export interface User {
  readonly id: string;
  readonly email: string;
  readonly displayName: string;
}

export interface Session {
  readonly user: User;
  readonly issuedAt: number;
  readonly expiresAt: number;
}

/** Input for a login attempt, in domain vocabulary. */
export interface Credentials {
  readonly email: string;
  readonly password: string;
}

/** Why a login attempt was rejected. Never exposed verbatim to the user. */
export type AuthFailure = 'invalid-credentials' | 'locked-out';

export interface LoginAttemptState {
  readonly failedAttempts: number;
  readonly lastFailedAt: number | null;
}
