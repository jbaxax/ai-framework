/**
 * Domain types. No framework, no library, no I/O.
 *
 * These types are owned by the feature. They never mirror the backend payload —
 * `infrastructure/` maps the API response onto these. If the API renames a field
 * or the database vendor changes, nothing in this file changes.
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

/**
 * Input required to create an invoice.
 *
 * `presentation/` builds its validation schema to satisfy this type — never the
 * other way around. An inner layer must not import from an outer one.
 */
export interface NewInvoice {
  readonly customerId: string;
  readonly series: string;
  readonly lines: readonly InvoiceLine[];
}
