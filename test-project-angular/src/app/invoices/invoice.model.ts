export type InvoiceStatus = 'draft' | 'issued' | 'paid' | 'void';

export interface InvoiceLine {
  readonly productId: string;
  readonly description: string;
  readonly quantity: number;
  readonly unitPrice: number;
}

export interface Invoice {
  readonly id: string;
  readonly series: string;
  readonly number: number;
  readonly status: InvoiceStatus;
  readonly issuedAt: Date;
  readonly customerName: string;
  readonly lines: readonly InvoiceLine[];
}

export interface InvoiceTotals {
  readonly subtotal: number;
  readonly tax: number;
  readonly total: number;
}
