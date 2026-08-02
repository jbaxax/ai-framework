import { describe, expect, it } from 'vitest';
import { calculateTotals, canVoid, IGV_RATE, lineSubtotal } from './invoiceTotals';
import type { Invoice, InvoiceLine } from './types';

function line(overrides: Partial<InvoiceLine> = {}): InvoiceLine {
  return {
    productId: 'p-1',
    description: 'Item',
    quantity: 1,
    unitPrice: 100,
    discountRate: 0,
    ...overrides,
  };
}

describe('calculateTotals', () => {
  it('returns all zeros when there are no lines', () => {
    expect(calculateTotals([])).toEqual({
      subtotal: 0,
      discount: 0,
      taxableBase: 0,
      tax: 0,
      total: 0,
    });
  });

  it('applies tax over the amount left after the discount', () => {
    const totals = calculateTotals([line({ unitPrice: 200, discountRate: 0.1 })]);

    expect(totals.subtotal).toBe(200);
    expect(totals.discount).toBe(20);
    expect(totals.taxableBase).toBe(180);
    expect(totals.tax).toBe(32.4);
    expect(totals.total).toBe(212.4);
  });

  it('sums 0.1 and 0.2 to exactly 0.3, not 0.30000000000000004', () => {
    const totals = calculateTotals([line({ unitPrice: 0.1 }), line({ unitPrice: 0.2 })]);

    expect(totals.subtotal).toBe(0.3);
  });

  it('accepts a tax rate other than the default', () => {
    const totals = calculateTotals([line()], 0);

    expect(totals.tax).toBe(0);
    expect(totals.total).toBe(100);
  });

  it('exposes the default rate used by the business', () => {
    expect(IGV_RATE).toBe(0.18);
  });
});

describe('lineSubtotal', () => {
  it('multiplies quantity by unit price', () => {
    expect(lineSubtotal(line({ quantity: 3, unitPrice: 25.5 }))).toBe(76.5);
  });

  it('returns zero for a zero quantity', () => {
    expect(lineSubtotal(line({ quantity: 0 }))).toBe(0);
  });
});

describe('canVoid', () => {
  function invoice(status: Invoice['status']): Invoice {
    return {
      id: 'inv-1',
      series: 'F001',
      number: 1,
      customerId: 'c-1',
      issuedAt: new Date('2026-01-01'),
      status,
      lines: [],
    };
  }

  it('allows voiding an issued invoice', () => {
    expect(canVoid(invoice('issued'))).toBe(true);
  });

  it.each(['draft', 'paid', 'voided'] as const)('rejects a %s invoice', (status) => {
    expect(canVoid(invoice(status))).toBe(false);
  });
});
