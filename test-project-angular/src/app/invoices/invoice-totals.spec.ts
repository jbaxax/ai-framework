import { describe, expect, it } from 'vitest';
import { calculateTotals, canVoid, isOverdue, lineSubtotal } from './invoice-totals';
import type { Invoice, InvoiceLine, InvoiceStatus } from './invoice.model';

const line = (quantity: number, unitPrice: number): InvoiceLine => ({
  productId: 'p1',
  description: 'Producto',
  quantity,
  unitPrice,
});

const invoice = (status: InvoiceStatus, issuedAt: Date): Invoice => ({
  id: 'i1',
  series: 'F001',
  number: 1,
  status,
  issuedAt,
  customerName: 'Cliente',
  lines: [],
});

describe('calculateTotals', () => {
  it('rounds each line before accumulating so printed lines match the printed total', () => {
    const totals = calculateTotals([line(3, 0.335), line(3, 0.335), line(3, 0.335)]);

    expect(totals.subtotal).toBe(3.03);
  });

  it('applies IGV at 18%', () => {
    const totals = calculateTotals([line(1, 100)]);

    expect(totals).toEqual({ subtotal: 100, tax: 18, total: 118 });
  });

  it('returns zeros for an invoice with no lines', () => {
    expect(calculateTotals([])).toEqual({ subtotal: 0, tax: 0, total: 0 });
  });
});

describe('lineSubtotal', () => {
  it('rounds to cents', () => {
    expect(lineSubtotal(line(3, 0.335))).toBe(1.01);
  });
});

describe('canVoid', () => {
  it.each([
    ['draft', true],
    ['issued', true],
    ['paid', false],
    ['void', false],
  ] as const)('%s -> %s', (status, expected) => {
    expect(canVoid(invoice(status, new Date()))).toBe(expected);
  });
});

describe('isOverdue', () => {
  const issuedAt = new Date('2026-01-01T00:00:00.000Z');

  it('is overdue once the term has passed', () => {
    expect(isOverdue(invoice('issued', issuedAt), new Date('2026-02-01T00:00:00.000Z'), 30)).toBe(
      true,
    );
  });

  it('is not overdue on the last day of the term', () => {
    expect(isOverdue(invoice('issued', issuedAt), new Date('2026-01-31T00:00:00.000Z'), 30)).toBe(
      false,
    );
  });

  it('is never overdue when the invoice is already paid', () => {
    expect(isOverdue(invoice('paid', issuedAt), new Date('2027-01-01T00:00:00.000Z'), 30)).toBe(
      false,
    );
  });
});
