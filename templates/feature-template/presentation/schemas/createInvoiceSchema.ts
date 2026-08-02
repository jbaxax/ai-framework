/**
 * Form validation. Lives in `presentation/` because it describes what the FORM
 * accepts, which is a UI concern.
 *
 * The direction matters: this schema is built to satisfy the domain type.
 * The domain never imports this file.
 *
 * Getting this backwards — `application/` importing a schema type from
 * `presentation/` — is a dependency-rule violation. It is the exact leak this
 * template exists to prevent.
 */

import { z } from 'zod';
import type { NewInvoice } from '../../domain/types';

export const invoiceLineFormSchema = z.object({
  productId: z.string().min(1, 'Select a product'),
  description: z.string().min(1, 'Description is required'),
  quantity: z.coerce.number().positive('Quantity must be greater than zero'),
  unitPrice: z.coerce.number().nonnegative('Price cannot be negative'),
  discountRate: z.coerce.number().min(0).max(1).default(0),
});

export const createInvoiceSchema = z.object({
  customerId: z.string().min(1, 'Select a customer'),
  series: z.string().min(1, 'Series is required'),
  lines: z.array(invoiceLineFormSchema).min(1, 'Add at least one line'),
});

export type CreateInvoiceForm = z.infer<typeof createInvoiceSchema>;

/**
 * Converts form values into the domain input.
 *
 * This function is the seam between the two shapes. If the domain gains a
 * required field, this stops compiling — the form is forced to catch up instead
 * of drifting silently.
 *
 * It also gives conversions an obvious home: form inputs arrive as strings,
 * dates arrive as text, and the domain wants neither.
 */
export function toNewInvoice(form: CreateInvoiceForm): NewInvoice {
  return {
    customerId: form.customerId,
    series: form.series,
    lines: form.lines,
  };
}
