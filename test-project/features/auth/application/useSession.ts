import { useQuery } from '@tanstack/react-query';
import { fetchCurrentUser } from '../infrastructure/authApi';

export const authKeys = {
  session: ['auth', 'session'] as const,
};

export function useSession() {
  return useQuery({
    queryKey: authKeys.session,
    queryFn: fetchCurrentUser,
    staleTime: 5 * 60 * 1000,
    retry: false,
  });
}
