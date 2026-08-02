/**
 * Business logic. Pure functions only.
 *
 * This file imports nothing but its own types — no React, no Axios, no Zod.
 * That is what makes it testable in milliseconds without mounting anything,
 * and it is the reason the layer exists at all.
 *
 * This exact file is valid in React and in Angular without a single change.
 */

import type { Invoice, InvoiceLine, InvoiceTotals } from './types';

/** Peru general sales tax. Passed as a parameter so the rate is never assumed. */
export const IGV_RATE = 0.18;

/**
 * Rounds to 2 decimals. Money must never be compared or accumulated as raw
 * floating point: `0.1 + 0.2` is `0.30000000000000004`, and that cent shows up
 * on an invoice.
 */
function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function lineSubtotal(line: InvoiceLine): number {
  return round2(line.quantity * line.unitPrice);
}

export function lineDiscount(line: InvoiceLine): number {
  return round2(lineSubtotal(line) * line.discountRate);
}

/**
 * Rounds each line before accumulating, so the printed line amounts always add
 * up to the printed total. Summing raw values and rounding once at the end
 * produces invoices whose lines do not match their total.
 */
export function calculateTotals(
  lines: readonly InvoiceLine[],
  taxRate: number = IGV_RATE,
): InvoiceTotals {
  const subtotal = round2(lines.reduce((acc, line) => acc + lineSubtotal(line), 0));
  const discount = round2(lines.reduce((acc, line) => acc + lineDiscount(line), 0));
  const taxableBase = round2(subtotal - discount);
  const tax = round2(taxableBase * taxRate);
  const total = round2(taxableBase + tax);

  return { subtotal, discount, taxableBase, tax, total };
}

/**
 * A state rule, not a calculation. Business logic is not only arithmetic —
 * "what is allowed right now" belongs in the domain too.
 */
export function canVoid(invoice: Invoice): boolean {
  return invoice.status === 'issued';
}
