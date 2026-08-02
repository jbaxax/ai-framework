import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { logout } from '../infrastructure/authApi';

export function useLogout() {
  const queryClient = useQueryClient();
  const router = useRouter();

  return useMutation({
    mutationFn: logout,
    onSuccess: () => {
      // Clear every cached query: another user must not inherit this one's data.
      queryClient.clear();
      router.replace('/login');
    },
  });
}
