import { z } from 'zod';
import type { Invoice, InvoiceLine, InvoiceStatus } from '../domain/types';

const invoiceLineDtoSchema = z.object({
  producto_id: z.string(),
  descripcion: z.string(),
  cantidad: z.coerce.number().nonnegative(),
  precio_unitario: z.coerce.number().nonnegative(),
  tasa_descuento: z.coerce.number().min(0).max(1).default(0),
});

export const invoiceDtoSchema = z.object({
  id: z.string(),
  serie: z.string(),
  numero: z.coerce.number().int(),
  cliente_id: z.string(),
  fecha_emision: z.iso.datetime(),
  estado: z.enum(['borrador', 'emitida', 'pagada', 'anulada']),
  items: z.array(invoiceLineDtoSchema),
});

export const invoiceResponseSchema = invoiceDtoSchema;

export type InvoiceDto = z.infer<typeof invoiceDtoSchema>;
type InvoiceLineDto = z.infer<typeof invoiceLineDtoSchema>;

const STATUS_BY_API_VALUE: Record<InvoiceDto['estado'], InvoiceStatus> = {
  borrador: 'draft',
  emitida: 'issued',
  pagada: 'paid',
  anulada: 'voided',
};

function toDomainLine(dto: InvoiceLineDto): InvoiceLine {
  return {
    productId: dto.producto_id,
    description: dto.descripcion,
    quantity: dto.cantidad,
    unitPrice: dto.precio_unitario,
    discountRate: dto.tasa_descuento,
  };
}

export function toDomainInvoice(dto: InvoiceDto): Invoice {
  return {
    id: dto.id,
    series: dto.serie,
    number: dto.numero,
    customerId: dto.cliente_id,
    issuedAt: new Date(dto.fecha_emision),
    status: STATUS_BY_API_VALUE[dto.estado],
    lines: dto.items.map(toDomainLine),
  };
}
