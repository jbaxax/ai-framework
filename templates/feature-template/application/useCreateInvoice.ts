import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createInvoice } from '../infrastructure/invoiceApi';
import type { NewInvoice } from '../domain/types';
import { invoiceKeys } from './useInvoices';

export function useCreateInvoice() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: NewInvoice) => createInvoice(input),
    onSuccess: () => {
      // Invalidate rather than hand-patch the cache: the server stays the
      // source of truth, and the list picks up whatever it computed.
      void queryClient.invalidateQueries({ queryKey: invoiceKeys.all });
    },
  });
}
