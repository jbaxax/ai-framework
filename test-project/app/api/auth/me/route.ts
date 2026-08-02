import { NextResponse } from 'next/server';
import { toUserDto } from '@/features/auth/infrastructure/authSchemas';
import { readSession } from '@/features/auth/infrastructure/session.server';

export async function GET() {
  const session = await readSession();

  if (!session) {
    return NextResponse.json({ error: 'Not authenticated.' }, { status: 401 });
  }

  return NextResponse.json({ user: toUserDto(session.user) });
}
