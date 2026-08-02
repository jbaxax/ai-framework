import type { Invoice, InvoiceLine, InvoiceTotals } from './invoice.model';

export const IGV_RATE = 0.18;

function roundToCents(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function lineSubtotal(line: InvoiceLine): number {
  return roundToCents(line.quantity * line.unitPrice);
}

export function lineDiscount(line: InvoiceLine): number {
  return roundToCents(lineSubtotal(line) * line.discountRate);
}

export function calculateTotals(
  lines: readonly InvoiceLine[],
  taxRate: number = IGV_RATE,
): InvoiceTotals {
  const subtotal = roundToCents(lines.reduce((acc, line) => acc + lineSubtotal(line), 0));
  const discount = roundToCents(lines.reduce((acc, line) => acc + lineDiscount(line), 0));
  const taxableBase = roundToCents(subtotal - discount);
  const tax = roundToCents(taxableBase * taxRate);
  const total = roundToCents(taxableBase + tax);

  return { subtotal, discount, taxableBase, tax, total };
}

export function canVoid(invoice: Invoice): boolean {
  return invoice.status === 'issued';
}
