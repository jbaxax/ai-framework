import { NextResponse } from 'next/server';
import { z } from 'zod';
import {
  canAttemptLogin,
  clearFailures,
  createSession,
  normalizeEmail,
  registerFailure,
} from '@/features/auth/domain/session';
import { toUserDto } from '@/features/auth/infrastructure/authSchemas';
import {
  createSessionToken,
  findUserByEmail,
  getAttemptState,
  setAttemptState,
  toPublicUser,
  verifyPassword,
} from '@/features/auth/infrastructure/userStore.server';
import { setSessionCookie } from '@/features/auth/infrastructure/session.server';

const requestSchema = z.object({
  email: z.string().transform(normalizeEmail).pipe(z.email()),
  password: z.string().min(1),
});

export async function POST(request: Request) {
  const parsed = requestSchema.safeParse(await request.json().catch(() => null));

  if (!parsed.success) {
    return NextResponse.json({ error: 'Invalid request.' }, { status: 422 });
  }

  const now = Date.now();
  const email = parsed.data.email; // already normalized by the schema
  const attempts = getAttemptState(email);

  if (!canAttemptLogin(attempts, now)) {
    return NextResponse.json({ error: 'Too many attempts.' }, { status: 429 });
  }

  const user = findUserByEmail(email);
  const authenticated = user !== null && verifyPassword(user, parsed.data.password);

  if (!user || !authenticated) {
    setAttemptState(email, registerFailure(attempts, now));

    return NextResponse.json({ error: 'Invalid credentials.' }, { status: 401 });
  }

  setAttemptState(email, clearFailures());

  const session = createSession(toPublicUser(user), now);
  const token = createSessionToken(session);
  await setSessionCookie(token, session.expiresAt);

  return NextResponse.json({ user: toUserDto(session.user) });
}
