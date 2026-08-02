import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createInvoice } from '../infrastructure/invoiceApi';
import type { NewInvoice } from '../domain/types';
import { invoiceKeys } from './useInvoices';

export function useCreateInvoice() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: NewInvoice) => createInvoice(input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: invoiceKeys.all });
    },
  });
}
