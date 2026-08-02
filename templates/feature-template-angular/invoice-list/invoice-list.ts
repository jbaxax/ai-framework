/**
 * Presentation. Generated with:
 *   ng g component features/invoice/invoice-list
 *
 * The CLI creates the folder — a component is three files (.ts/.html/.scss),
 * so it gets its own directory. Services stay flat beside them.
 *
 * This component talks to the store and the domain. It never injects
 * InvoiceApi, never sees HttpClient, and never computes a total by hand.
 */

import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { InvoiceStore } from '../invoice-store';
import { calculateTotals } from '../invoice-totals';
import type { Invoice } from '../invoice.model';

@Component({
  selector: 'app-invoice-list',
  imports: [CurrencyPipe],
  templateUrl: './invoice-list.html',
  styleUrl: './invoice-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InvoiceList implements OnInit {
  private readonly store = inject(InvoiceStore);

  protected readonly invoices = this.store.invoices;
  protected readonly loading = this.store.loading;
  protected readonly error = this.store.error;
  protected readonly grandTotal = this.store.grandTotal;

  ngOnInit(): void {
    this.store.load();
  }

  /** Delegates to the domain. If the tax rate changes, this file does not. */
  protected totalFor(invoice: Invoice): number {
    return calculateTotals(invoice.lines).total;
  }
}
