import { Service, inject, signal, computed } from '@angular/core';
import type { Invoice } from './invoice.model';
import { calculateTotals } from './invoice-totals';
import { InvoiceApi } from './invoice-api';

@Service()
export class InvoiceStore {
  private readonly api = inject(InvoiceApi);

  private readonly _invoices = signal<readonly Invoice[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);
  private readonly _page = signal(1);
  private readonly _totalPages = signal(0);

  readonly invoices = this._invoices.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly page = this._page.asReadonly();
  readonly totalPages = this._totalPages.asReadonly();

  readonly isEmpty = computed(() => !this._loading() && this._invoices().length === 0);
  readonly hasNextPage = computed(() => this._page() < this._totalPages());

  async load(page = 1): Promise<void> {
    this._loading.set(true);
    this._error.set(null);

    try {
      const result = await this.api.list(page, 20);
      this._invoices.set(result.items);
      this._page.set(result.page);
      this._totalPages.set(result.totalPages);
    } catch {
      this._error.set('No se pudieron cargar los comprobantes.');
      this._invoices.set([]);
    } finally {
      this._loading.set(false);
    }
  }

  totalsFor(invoice: Invoice) {
    return calculateTotals(invoice.lines);
  }
}
