/**
 * The only file in this feature allowed to touch the HTTP client.
 *
 * Everything it returns is a domain type. Nothing it throws is an `AxiosError`.
 * `application/` and `presentation/` therefore never learn that HTTP exists.
 */

import { apiClient } from '@/lib/api/client';
import type { Invoice, NewInvoice } from '../domain/types';
import { type Page, tolerantPaginatedSchema } from './pagination';
import { invoiceDtoSchema, invoiceResponseSchema, toDomainInvoice } from './invoiceSchemas';

/**
 * The envelope is typed once in `pagination.ts` and reused by every feature.
 * This endpoint is documented as paginated but currently returns a bare array —
 * verified against a real response, and reported to the backend author.
 * `tolerantPaginatedSchema` accepts both shapes while still validating items.
 */
const invoiceListSchema = tolerantPaginatedSchema(invoiceDtoSchema, toDomainInvoice);

export async function fetchInvoices(): Promise<Page<Invoice>> {
  const { data } = await apiClient.get('/invoices');

  // Parse before use. If the API drifts, this line fails with the exact field
  // that changed — not a blank screen three layers up.
  return invoiceListSchema.parse(data);
}

export async function fetchInvoice(id: string): Promise<Invoice> {
  const { data } = await apiClient.get(`/invoices/${id}`);

  return toDomainInvoice(invoiceResponseSchema.parse(data));
}

export async function createInvoice(input: NewInvoice): Promise<Invoice> {
  // Mapping runs in both directions: domain vocabulary in, API vocabulary out.
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
