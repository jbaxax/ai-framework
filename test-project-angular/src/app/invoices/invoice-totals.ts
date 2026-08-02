import type { Invoice, InvoiceLine, InvoiceStatus, InvoiceTotals } from './invoice.model';

export const IGV_RATE = 0.18;

function roundToCents(value: number): number {
  return Math.round(value * 100) / 100;
}

export function lineSubtotal(line: InvoiceLine): number {
  return roundToCents(line.quantity * line.unitPrice);
}

export function calculateTotals(lines: readonly InvoiceLine[]): InvoiceTotals {
  const subtotal = roundToCents(lines.reduce((sum, line) => sum + lineSubtotal(line), 0));
  const tax = roundToCents(subtotal * IGV_RATE);

  return { subtotal, tax, total: roundToCents(subtotal + tax) };
}

const VOIDABLE_STATUSES: readonly InvoiceStatus[] = ['draft', 'issued'];

export function canVoid(invoice: Invoice): boolean {
  return VOIDABLE_STATUSES.includes(invoice.status);
}

export function isOverdue(invoice: Invoice, now: Date, termDays: number): boolean {
  if (invoice.status !== 'issued') return false;

  const dueMs = invoice.issuedAt.getTime() + termDays * 24 * 60 * 60 * 1000;
  return now.getTime() > dueMs;
}
