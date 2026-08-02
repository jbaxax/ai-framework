'use client';

import { useLogout } from '../../application/useLogout';

export function LogoutButton() {
  const logout = useLogout();

  return (
    <button type="button" onClick={() => logout.mutate()} disabled={logout.isPending}>
      {logout.isPending ? 'Signing out…' : 'Sign out'}
    </button>
  );
}
