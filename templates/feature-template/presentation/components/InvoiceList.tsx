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
