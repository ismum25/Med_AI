import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PUBLIC_PATHS = ['/login', '/register'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public paths
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Check for token in cookies (set server-side) or allow client-side hydration
  const token = request.cookies.get('access_token')?.value;

  if (!token && pathname !== '/') {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Role-based route protection
  const role = request.cookies.get('user_role')?.value;
  if (role === 'patient' && pathname.startsWith('/doctor')) {
    return NextResponse.redirect(new URL('/patient/dashboard', request.url));
  }
  if (role === 'doctor' && pathname.startsWith('/patient')) {
    return NextResponse.redirect(new URL('/doctor/dashboard', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
