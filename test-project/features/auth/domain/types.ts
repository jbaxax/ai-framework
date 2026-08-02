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

export interface Credentials {
  readonly email: string;
  readonly password: string;
}

export type AuthFailure = 'invalid-credentials' | 'locked-out';

export interface LoginAttemptState {
  readonly failedAttempts: number;
  readonly lastFailedAt: number | null;
}
