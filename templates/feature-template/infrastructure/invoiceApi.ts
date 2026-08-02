import { apiClient } from '@/lib/api/client';
import type { Invoice, NewInvoice } from '../domain/types';
import { type Page, tolerantPaginatedSchema } from './pagination';
import { invoiceDtoSchema, invoiceResponseSchema, toDomainInvoice } from './invoiceSchemas';

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
  const { data } = await apiClient.post('/invoices', {
    cliente_id: input.customerId,
    serie: input.series,
    items: input.lines.map((line) => ({
      producto_id: line.productId,
      descripcion: line.description,
      cantidad: line.quantity,
      precio_unitario: line.unitPrice,
      tasa_descuento: line.discountRate,
    })),
  });

  return toDomainInvoice(invoiceResponseSchema.parse(data));
}
