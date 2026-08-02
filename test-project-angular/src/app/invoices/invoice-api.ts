import { Service, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import type { Invoice } from './invoice.model';
import { invoiceSchema } from './invoice-schemas';
import { parsePage, type Page } from './pagination';

@Service()
export class InvoiceApi {
  private readonly http = inject(HttpClient);

  async list(page: number, limit: number): Promise<Page<Invoice>> {
    const raw = await firstValueFrom(
      this.http.get<unknown>('/api/comprobantes', {
        params: { pagina: page, por_pagina: limit },
      }),
    );

    return parsePage(raw, invoiceSchema);
  }
}
