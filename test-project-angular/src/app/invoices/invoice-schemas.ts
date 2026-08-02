import { z } from 'zod';
import type { Invoice, InvoiceStatus } from './invoice.model';

const STATUS_BY_API_VALUE: Record<string, InvoiceStatus> = {
  borrador: 'draft',
  emitida: 'issued',
  pagada: 'paid',
  anulada: 'void',
};

const invoiceLineDtoSchema = z.object({
  producto_id: z.string(),
  descripcion: z.string(),
  cantidad: z.number().positive(),
  precio_unitario: z.number().nonnegative(),
});

export const invoiceDtoSchema = z.object({
  id: z.string(),
  serie: z.string(),
  numero: z.number().int().positive(),
  estado: z.string(),
  fecha_emision: z.iso.datetime(),
  cliente_nombre: z.string(),
  lineas: z.array(invoiceLineDtoSchema),
});

export type InvoiceDto = z.infer<typeof invoiceDtoSchema>;

export function toDomainInvoice(dto: InvoiceDto): Invoice {
  const status = STATUS_BY_API_VALUE[dto.estado];

  if (!status) {
    throw new Error(`Unknown invoice status from API: "${dto.estado}"`);
  }

  return {
    id: dto.id,
    series: dto.serie,
    number: dto.numero,
    status,
    issuedAt: new Date(dto.fecha_emision),
    customerName: dto.cliente_nombre,
    lines: dto.lineas.map((line) => ({
      productId: line.producto_id,
      description: line.descripcion,
      quantity: line.cantidad,
      unitPrice: line.precio_unitario,
    })),
  };
}

export const invoiceSchema = invoiceDtoSchema.transform(toDomainInvoice);
