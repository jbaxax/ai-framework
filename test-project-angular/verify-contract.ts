import { parsePage } from './src/app/invoices/pagination';
import { invoiceSchema } from './src/app/invoices/invoice-schemas';
import { calculateTotals } from './src/app/invoices/invoice-totals';

const BASE = Bun.env['BASE'] ?? 'http://localhost:4100';

async function main(): Promise<void> {
  const response = await fetch(`${BASE}/api/comprobantes?pagina=1&por_pagina=20`);
  const raw: unknown = await response.json();

  console.log(`GET /api/comprobantes -> ${response.status}`);
  console.log('wire format:', JSON.stringify(raw).slice(0, 120), '…\n');

  const page = parsePage(raw, invoiceSchema);

  console.log(`parsed ${page.items.length} invoices, page ${page.page}/${page.totalPages}`);

  for (const invoice of page.items) {
    const totals = calculateTotals(invoice.lines);
    console.log(
      `  ${invoice.series}-${invoice.number}  ${invoice.customerName}  ` +
        `status=${invoice.status}  issuedAt=${invoice.issuedAt.toISOString()}  ` +
        `total=${totals.total}`,
    );
  }

  console.log('\nAPI vocabulary present in the parsed result?');

  const API_KEYS = ['serie', 'numero', 'estado', 'fecha_emision', 'cliente_nombre', 'lineas'];
  const keys = new Set<string>();
  const walk = (value: unknown): void => {
    if (Array.isArray(value)) return value.forEach(walk);
    if (value && typeof value === 'object' && !(value instanceof Date)) {
      for (const [key, child] of Object.entries(value)) {
        keys.add(key);
        walk(child);
      }
    }
  };
  walk(page);

  const leaked = API_KEYS.filter((key) => keys.has(key));
  console.log(
    leaked.length ? `  LEAK: ${leaked.join(', ')}` : '  no — API names stopped at infrastructure',
  );
  console.log(`  domain keys: ${[...keys].join(', ')}`);
}

await main();
