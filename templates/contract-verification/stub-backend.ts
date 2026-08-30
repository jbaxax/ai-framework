type Drift = 'none' | 'bare-array' | 'date-format' | 'missing-field' | 'wrong-type' | 'extra-field';

const DRIFT = (Bun.env['DRIFT'] ?? 'none') as Drift;
const PORT = Number(Bun.env['PORT'] ?? 4100);

const INVOICES = [
  {
    id: 'inv-1',
    serie: 'F001',
    numero: 45,
    estado: 'emitida',
    fecha_emision: '2026-03-01T10:00:00.000Z',
    cliente_nombre: 'Comercial Los Andes SAC',
    lineas: [
      { producto_id: 'p1', descripcion: 'Torta de chocolate', cantidad: 2, precio_unitario: 45.5 },
      { producto_id: 'p2', descripcion: 'Caja de alfajores', cantidad: 3, precio_unitario: 0.335 },
    ],
  },
  {
    id: 'inv-2',
    serie: 'F001',
    numero: 46,
    estado: 'pagada',
    fecha_emision: '2026-03-02T09:30:00.000Z',
    cliente_nombre: 'Panaderia del Sur',
    lineas: [{ producto_id: 'p3', descripcion: 'Pan frances', cantidad: 100, precio_unitario: 0.5 }],
  },
];

function applyDrift(): unknown {
  const envelope = { items: INVOICES, pagina: 1, por_pagina: 20, total: 2, total_paginas: 1 };

  switch (DRIFT) {
    case 'bare-array':
      return INVOICES;
    case 'date-format':
      return { ...envelope, items: INVOICES.map((i) => ({ ...i, fecha_emision: '01/03/2026' })) };
    case 'missing-field':
      return { ...envelope, items: INVOICES.map(({ cliente_nombre: _drop, ...rest }) => rest) };
    case 'wrong-type':
      return { ...envelope, items: INVOICES.map((i) => ({ ...i, numero: String(i.numero) })) };
    case 'extra-field':
      return { ...envelope, items: INVOICES.map((i) => ({ ...i, moneda_interna: 'PEN' })) };
    default:
      return envelope;
  }
}

const server = Bun.serve({
  port: PORT,
  fetch(request) {
    const url = new URL(request.url);
    if (url.pathname !== '/api/comprobantes') {
      return new Response(JSON.stringify({ mensaje: 'no encontrado' }), {
        status: 404,
        headers: { 'content-type': 'application/json' },
      });
    }
    return new Response(JSON.stringify(applyDrift()), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    });
  },
});

console.log(`stub backend on :${server.port} — drift mode: ${DRIFT}`);
