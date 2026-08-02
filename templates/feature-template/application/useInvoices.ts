/**
 * Server state lives in React Query and nowhere else.
 *
 * Copying this data into Context or a store would reintroduce the manual
 * synchronization React Query already solves.
 */

import { useQuery } from '@tanstack/react-query';
import { fetchInvoice, fetchInvoices } from '../infrastructure/invoiceApi';

/** Keys in one place so mutations can invalidate them without guessing. */
export const invoiceKeys = {
  all: ['invoices'] as const,
  detail: (id: string) => ['invoices', id] as const,
};

export function useInvoices() {
  return useQuery({
    queryKey: invoiceKeys.all,
    queryFn: fetchInvoices,
  });
}

export function useInvoice(id: string) {
  return useQuery({
    queryKey: invoiceKeys.detail(id),
    queryFn: () => fetchInvoice(id),
    enabled: Boolean(id),
  });
}
