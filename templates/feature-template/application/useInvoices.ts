import { useQuery } from '@tanstack/react-query';
import { fetchInvoice, fetchInvoices } from '../infrastructure/invoiceApi';

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
