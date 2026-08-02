import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import type { Credentials } from '../domain/types';
import { login } from '../infrastructure/authApi';
import { authKeys } from './useSession';

export function useLogin() {
  const queryClient = useQueryClient();
  const router = useRouter();

  return useMutation({
    mutationFn: (credentials: Credentials) => login(credentials),
    onSuccess: (user) => {
      queryClient.setQueryData(authKeys.session, user);
      router.replace('/dashboard');
    },
  });
}
