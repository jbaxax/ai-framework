export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'voided';

export interface InvoiceLine {
  readonly productId: string;
  readonly description: string;
  readonly quantity: number;
  readonly unitPrice: number;
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

export interface NewInvoice {
  readonly customerId: string;
  readonly series: string;
  readonly lines: readonly InvoiceLine[];
}
