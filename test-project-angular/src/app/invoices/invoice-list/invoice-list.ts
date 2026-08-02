import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { InvoiceStore } from '../invoice-store';
import { canVoid } from '../invoice-totals';
import type { Invoice } from '../invoice.model';

@Component({
  selector: 'app-invoice-list',
  imports: [CurrencyPipe, DatePipe],
  templateUrl: './invoice-list.html',
  styleUrl: './invoice-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InvoiceList implements OnInit {
  protected readonly store = inject(InvoiceStore);

  ngOnInit(): void {
    void this.store.load();
  }

  protected canVoid(invoice: Invoice): boolean {
    return canVoid(invoice);
  }

  protected nextPage(): void {
    void this.store.load(this.store.page() + 1);
  }
}
