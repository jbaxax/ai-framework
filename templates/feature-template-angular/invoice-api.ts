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

const invoiceListSchema = tolerantPaginatedSchema(invoiceDtoSchema, toDomainInvoice);

@Service()
export class InvoiceApi {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/invoices`;

  getAll(): Observable<Page<Invoice>> {
    return this.http.get(this.baseUrl).pipe(map((response) => invoiceListSchema.parse(response)));
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
