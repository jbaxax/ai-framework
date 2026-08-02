import { redirect } from 'next/navigation';
import { readSession } from '@/features/auth/infrastructure/session.server';
import { LogoutButton } from '@/features/auth/presentation/components/LogoutButton';

/**
 * The real security boundary. `proxy.ts` only checks that a cookie exists;
 * this verifies the session is known and unexpired, on the server.
 */
export default async function DashboardPage() {
  const session = await readSession();

  if (!session) {
    redirect('/login');
  }

  return (
    <main>
      <h1>Welcome, {session.user.displayName}</h1>
      <p>Signed in as {session.user.email}</p>
      <LogoutButton />
    </main>
  );
}
