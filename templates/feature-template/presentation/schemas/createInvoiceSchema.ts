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

export function toNewInvoice(form: CreateInvoiceForm): NewInvoice {
  return {
    customerId: form.customerId,
    series: form.series,
    lines: form.lines,
  };
}
