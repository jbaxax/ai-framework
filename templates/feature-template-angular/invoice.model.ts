/**
 * Domain types. No Angular, no RxJS, no HTTP.
 *
 * Same content as the React template's `domain/types.ts`. The layer is carried
 * by the file, not by a folder — Angular's style guide asks for a flat feature
 * directory, and the dependency rule lives in the imports either way.
 */

export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'voided';

export interface InvoiceLine {
  readonly productId: string;
  readonly description: string;
  readonly quantity: number;
  readonly unitPrice: number;
  /** Fraction between 0 and 1. `0.1` means 10% off this line. */
  readonly discountRate: number;
}

export interface Invoice {
  readonly id: string;
  readonly series: string;
  readonly number: number;
  readonly customerId: string;
  readonly issuedAt: Date;
  readonly status: InvoiceStatus;
  readonly lines: readonly InvoiceLine[];
}

export interface InvoiceTotals {
  readonly subtotal: number;
  readonly discount: number;
  readonly taxableBase: number;
  readonly tax: number;
  readonly total: number;
}

/** Input required to create an invoice. The form schema satisfies this type. */
export interface NewInvoice {
  readonly customerId: string;
  readonly series: string;
  readonly lines: readonly InvoiceLine[];
}
