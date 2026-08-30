import { apiClient } from '@/lib/api/client';
import type { Invoice, NewInvoice } from '../domain/types';
import { type Page, tolerantPaginatedSchema } from './pagination';
import { invoiceDtoSchema, invoiceResponseSchema, toApiPayload, toDomainInvoice } from './invoiceSchemas';

const invoiceListSchema = tolerantPaginatedSchema(invoiceDtoSchema, toDomainInvoice);

export async function fetchInvoices(): Promise<Page<Invoice>> {
  const { data } = await apiClient.get('/invoices');

  return invoiceListSchema.parse(data);
}

export async function fetchInvoice(id: string): Promise<Invoice> {
  const { data } = await apiClient.get(`/invoices/${id}`);

  return toDomainInvoice(invoiceResponseSchema.parse(data));
}

export async function createInvoice(input: NewInvoice): Promise<Invoice> {
  const { data } = await apiClient.post('/invoices', toApiPayload(input));

  return toDomainInvoice(invoiceResponseSchema.parse(data));
}
