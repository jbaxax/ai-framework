/**
 * Presentation imports `application` and `domain`. Never `infrastructure`.
 *
 * This component does not know the API exists, does not know a token exists,
 * and does not compute totals itself — it asks the domain.
 */

'use client';

import { useInvoices } from '../../application/useInvoices';
import { calculateTotals } from '../../domain/invoiceTotals';

export function InvoiceList() {
  const { data: page, isPending, isError } = useInvoices();

  if (isPending) return <p>Loading invoices…</p>;
  if (isError) return <p role="alert">Could not load invoices. Try again.</p>;
  if (page.items.length === 0) return <p>No invoices yet.</p>;

  return (
    <table>
      <thead>
        <tr>
          <th scope="col">Number</th>
          <th scope="col">Status</th>
          <th scope="col">Total</th>
        </tr>
      </thead>
      <tbody>
        {page.items.map((invoice) => {
          // The rule lives in the domain. If the tax changes, this file does not.
          const { total } = calculateTotals(invoice.lines);

          return (
            <tr key={invoice.id}>
              <td>
                {invoice.series}-{invoice.number}
              </td>
              <td>{invoice.status}</td>
              <td>{total.toFixed(2)}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
