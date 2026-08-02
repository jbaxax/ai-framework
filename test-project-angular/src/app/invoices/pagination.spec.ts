import { describe, expect, it } from 'vitest';
import { z } from 'zod';
import { parsePage } from './pagination';
import { invoiceSchema } from './invoice-schemas';

const itemSchema = z.object({ id: z.string() });

const envelope = (data: unknown[]) => ({
  data,
  meta: { pagina: 1, por_pagina: 20, total: data.length, total_paginas: 1 },
});

describe('parsePage', () => {
  it('maps the backend envelope to the domain page shape', () => {
    const page = parsePage(envelope([{ id: 'a' }, { id: 'b' }]), itemSchema);

    expect(page).toEqual({
      items: [{ id: 'a' }, { id: 'b' }],
      page: 1,
      limit: 20,
      total: 2,
      totalPages: 1,
    });
  });

  it('throws when the backend returns a bare array instead of an envelope', () => {
    expect(() => parsePage([{ id: 'a' }], itemSchema)).toThrow();
  });

  it('throws when an item does not match its schema', () => {
    expect(() => parsePage(envelope([{ id: 42 }]), itemSchema)).toThrow();
  });

  it('rejects an envelope whose meta is missing', () => {
    expect(() => parsePage({ data: [] }, itemSchema)).toThrow();
  });
});

describe('parsePage with the invoice schema', () => {
  const dto = {
    id: 'inv-1',
    serie: 'F001',
    numero: 45,
    estado: 'emitida',
    fecha_emision: '2026-03-01T10:00:00.000Z',
    cliente_nombre: 'Comercial Los Andes SAC',
    lineas: [{ producto_id: 'p1', descripcion: 'Torta', cantidad: 2, precio_unitario: 45.5 }],
  };

  it('parses and maps the API vocabulary to domain names in one step', () => {
    const page = parsePage(envelope([dto]), invoiceSchema);
    const invoice = page.items[0]!;

    expect(invoice.series).toBe('F001');
    expect(invoice.status).toBe('issued');
    expect(invoice.customerName).toBe('Comercial Los Andes SAC');
    expect(invoice.issuedAt).toBeInstanceOf(Date);
    expect(invoice.lines[0]!.unitPrice).toBe(45.5);
  });

  it('throws on an unmapped status instead of defaulting', () => {
    expect(() => parsePage(envelope([{ ...dto, estado: 'rechazada' }]), invoiceSchema)).toThrow(
      /Unknown invoice status/,
    );
  });
});
