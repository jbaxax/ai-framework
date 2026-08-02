/**
 * Infrastructure. The only file in this feature that touches HttpClient.
 *
 * Generate it with:
 *   ng g service features/invoice/invoice-api
 *
 * Note what this class does NOT hold: state. No signals live here. Splitting
 * transport from state is what lets `invoice-store` be reasoned about without
 * the network, and it is where an existing project's `core/services/*` currently mixes both.
 *
 * It lives beside the feature, not in `core/`. `core/` is for what the whole
 * application needs — auth, interceptors, guards. A service used by one feature
 * was never core.
 */

import { HttpClient } from '@angular/common/http';
import { inject, Service } from '@angular/core';
import { map, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { Invoice, NewInvoice } from './invoice.model';
import { type Page, tolerantPaginatedSchema } from './pagination';
import {
  invoiceDtoSchema,
  invoiceResponseSchema,
  toApiPayload,
  toDomainInvoice,
} from './invoice-schemas';

/**
 * The envelope is typed once in `pagination.ts` and reused by every feature.
 * This endpoint is documented as paginated but currently returns a bare array —
 * verified against a real response, and reported to the backend author.
 */
const invoiceListSchema = tolerantPaginatedSchema(invoiceDtoSchema, toDomainInvoice);

@Service()
export class InvoiceApi {
  // Field injection with inject(). Never constructor parameter injection.
  private readonly http = inject(HttpClient);

  // Base URL from environment. Never a hardcoded host or IP.
  private readonly baseUrl = `${environment.apiUrl}/invoices`;

  getAll(): Observable<Page<Invoice>> {
    return this.http.get(this.baseUrl).pipe(
      // Parse before use: if the API drifts, this fails with the exact field
      // that changed, not with an undefined in a template.
      map((response) => invoiceListSchema.parse(response)),
    );
  }

  getById(id: string): Observable<Invoice> {
    return this.http
      .get(`${this.baseUrl}/${id}`)
      .pipe(map((response) => toDomainInvoice(invoiceResponseSchema.parse(response))));
  }

  create(input: NewInvoice): Observable<Invoice> {
    return this.http
      .post(this.baseUrl, toApiPayload(input))
      .pipe(map((response) => toDomainInvoice(invoiceResponseSchema.parse(response))));
  }
}
