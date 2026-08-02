'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useCreateInvoice } from '../../application/useCreateInvoice';
import { calculateTotals } from '../../domain/invoiceTotals';
import {
  createInvoiceSchema,
  toNewInvoice,
  type CreateInvoiceForm,
} from '../schemas/createInvoiceSchema';

export function CreateInvoiceForm() {
  const createInvoice = useCreateInvoice();

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<CreateInvoiceForm>({
    resolver: zodResolver(createInvoiceSchema),
    defaultValues: {
      customerId: '',
      series: 'F001',
      lines: [{ productId: '', description: '', quantity: 1, unitPrice: 0, discountRate: 0 }],
    },
  });

  // Totals are previewed with the same function the server-side rule uses.
  // Duplicating the arithmetic here is how the preview and the invoice diverge.
  const totals = calculateTotals(watch('lines') ?? []);

  const onSubmit = handleSubmit(async (values) => {
    // Form shape in, domain shape out. The mapping is explicit and type-checked.
    await createInvoice.mutateAsync(toNewInvoice(values));
  });

  return (
    <form onSubmit={onSubmit}>
      <label htmlFor="customerId">Customer</label>
      <input id="customerId" {...register('customerId')} />
      {errors.customerId && <p role="alert">{errors.customerId.message}</p>}

      <label htmlFor="series">Series</label>
      <input id="series" {...register('series')} />
      {errors.series && <p role="alert">{errors.series.message}</p>}

      <dl>
        <dt>Taxable base</dt>
        <dd>{totals.taxableBase.toFixed(2)}</dd>
        <dt>Tax</dt>
        <dd>{totals.tax.toFixed(2)}</dd>
        <dt>Total</dt>
        <dd>{totals.total.toFixed(2)}</dd>
      </dl>

      <button type="submit" disabled={isSubmitting || createInvoice.isPending}>
        Create invoice
      </button>

      {createInvoice.isError && <p role="alert">Could not create the invoice.</p>}
    </form>
  );
}
