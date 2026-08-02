import { useQuery } from '@tanstack/react-query';
import { fetchCurrentUser } from '../infrastructure/authApi';

export const authKeys = {
  session: ['auth', 'session'] as const,
};

/**
 * The session is server state, so React Query owns it. Copying the user into a
 * Context would create a second source of truth that goes stale on logout.
 */
export function useSession() {
  return useQuery({
    queryKey: authKeys.session,
    queryFn: fetchCurrentUser,
    staleTime: 5 * 60 * 1000,
    retry: false,
  });
}
