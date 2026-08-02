import { NextResponse } from 'next/server';
import { clearSessionCookie } from '@/features/auth/infrastructure/session.server';

export async function POST() {
  await clearSessionCookie();

  return new NextResponse(null, { status: 204 });
}
