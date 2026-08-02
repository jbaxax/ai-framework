import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PUBLIC_PATHS = ['/login'];

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isPublic = PUBLIC_PATHS.includes(pathname);
  const hasSessionCookie = request.cookies.has('session');

  if (!hasSessionCookie && !isPublic) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (hasSessionCookie && isPublic) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/((?!_next|api|favicon.ico).*)',
};
