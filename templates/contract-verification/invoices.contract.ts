import { z } from 'zod';
import type { ContractDefinition } from './contract';

const BASE = Bun.env['BASE'] ?? 'http://localhost:4100';

const documentedLine = z.object({
  producto_id: z.string(),
  descripcion: z.string(),
  cantidad: z.number(),
  precio_unitario: z.number(),
});

const documentedInvoice = z.object({
  id: z.string(),
  serie: z.string(),
  numero: z.number(),
  estado: z.enum(['emitida', 'pagada', 'anulada']),
  fecha_emision: z.iso.datetime(),
  cliente_nombre: z.string(),
  lineas: z.array(documentedLine),
});

const documentedPage = z.object({
  items: z.array(documentedInvoice),
  pagina: z.number(),
  por_pagina: z.number(),
  total: z.number(),
  total_paginas: z.number(),
});

export type DocumentedPage = z.infer<typeof documentedPage>;

export type InvoiceLine = {
  productId: string;
  description: string;
  quantity: number;
  unitPrice: number;
};

export type Invoice = {
  id: string;
  series: string;
  number: number;
  status: 'issued' | 'paid' | 'void';
  issuedAt: Date;
  customerName: string;
  lines: InvoiceLine[];
};

export type InvoicePage = {
  items: Invoice[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
};

const STATUS: Record<string, Invoice['status']> = {
  emitida: 'issued',
  pagada: 'paid',
  anulada: 'void',
};

export function toInvoicePage(documented: DocumentedPage): InvoicePage {
  return {
    items: documented.items.map((invoice) => ({
      id: invoice.id,
      series: invoice.serie,
      number: invoice.numero,
      status: STATUS[invoice.estado] ?? 'void',
      issuedAt: new Date(invoice.fecha_emision),
      customerName: invoice.cliente_nombre,
      lines: invoice.lineas.map((line) => ({
        productId: line.producto_id,
        description: line.descripcion,
        quantity: line.cantidad,
        unitPrice: line.precio_unitario,
      })),
    })),
    page: documented.pagina,
    pageSize: documented.por_pagina,
    total: documented.total,
    totalPages: documented.total_paginas,
  };
}

export const invoicesContract: ContractDefinition<DocumentedPage, InvoicePage> = {
  name: 'GET /api/comprobantes — invoice list',
  url: `${BASE}/api/comprobantes?pagina=1&por_pagina=20`,
  documented: documentedPage,
  wireVocabulary: [
    'serie',
    'numero',
    'estado',
    'fecha_emision',
    'cliente_nombre',
    'lineas',
    'producto_id',
    'descripcion',
    'cantidad',
    'precio_unitario',
    'pagina',
    'por_pagina',
    'total_paginas',
  ],
  map: toInvoicePage,
};
