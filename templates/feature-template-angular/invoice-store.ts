/**
 * Application layer. Holds state, orchestrates, exposes read-only signals.
 *
 * Generate it with:
 *   ng g service features/invoice/invoice-store
 *
 * It knows `InvoiceApi` and the domain. It does not know HttpClient, does not
 * know the API's field names, and does not build URLs.
 */

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

  // Writable signals stay private. Consumers get read-only views.
  readonly invoices = this._invoices.asReadonly();
  readonly meta = this._meta.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  // Derived state is computed, never stored — a stored copy goes stale.
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
        // A message for a human. Never the raw HTTP error, never a token.
        this._error.set('Could not load invoices.');
        this._loading.set(false);
      },
    });
  }

  create(input: NewInvoice): void {
    this.api.create(input).subscribe({
      // Refetch instead of hand-patching: the server stays the source of truth.
      next: () => this.load(),
      error: () => this._error.set('Could not create the invoice.'),
    });
  }
}
