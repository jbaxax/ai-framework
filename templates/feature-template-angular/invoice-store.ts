import { inject, Service, computed, signal } from '@angular/core';
import type { Invoice, NewInvoice } from './invoice.model';
import type { PageMeta } from './pagination';
import { calculateTotals } from './invoice-totals';
import { InvoiceApi } from './invoice-api';

@Service()
export class InvoiceStore {
  private readonly api = inject(InvoiceApi);

  private readonly _invoices = signal<readonly Invoice[]>([]);
  private readonly _meta = signal<PageMeta | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  readonly invoices = this._invoices.asReadonly();
  readonly meta = this._meta.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  readonly grandTotal = computed(() =>
    this._invoices().reduce((acc, invoice) => acc + calculateTotals(invoice.lines).total, 0),
  );

  load(): void {
    this._loading.set(true);
    this._error.set(null);

    this.api.getAll().subscribe({
      next: (page) => {
        this._invoices.set(page.items);
        this._meta.set(page.meta);
        this._loading.set(false);
      },
      error: () => {
        this._error.set('Could not load invoices.');
        this._loading.set(false);
      },
    });
  }

  create(input: NewInvoice): void {
    this.api.create(input).subscribe({
      next: () => this.load(),
      error: () => this._error.set('Could not create the invoice.'),
    });
  }
}
