/**
 * Presentation. Generated with:
 *   ng g component features/invoice/invoice-form
 *
 * Validation lives here because it describes what the FORM accepts.
 * The domain type is the target the form must satisfy — the dependency points
 * inward, never outward.
 */

import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { InvoiceStore } from '../invoice-store';
import { calculateTotals } from '../invoice-totals';
import type { InvoiceLine, NewInvoice } from '../invoice.model';

@Component({
  selector: 'app-invoice-form',
  imports: [ReactiveFormsModule, CurrencyPipe],
  templateUrl: './invoice-form.html',
  styleUrl: './invoice-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InvoiceForm {
  private readonly fb = inject(FormBuilder);
  private readonly store = inject(InvoiceStore);

  protected readonly form = this.fb.nonNullable.group({
    customerId: ['', Validators.required],
    series: ['F001', Validators.required],
  });

  protected readonly lines = signal<readonly InvoiceLine[]>([]);

  // Preview uses the same function the invoice will use. Duplicating the
  // arithmetic in the template is how preview and invoice drift apart.
  protected readonly totals = computed(() => calculateTotals(this.lines()));

  protected submit(): void {
    if (this.form.invalid || this.lines().length === 0) {
      this.form.markAllAsTouched();
      return;
    }

    const input: NewInvoice = {
      ...this.form.getRawValue(),
      lines: this.lines(),
    };

    this.store.create(input);
  }
}
