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
    cliente_nombre: 'Panadería del Sur',
    lineas: [{ producto_id: 'p3', descripcion: 'Pan francés', cantidad: 100, precio_unitario: 0.5 }],
  },
];

const RETURN_BARE_ARRAY = Bun.env['BARE_ARRAY'] === '1';

const server = Bun.serve({
  port: Number(Bun.env['PORT'] ?? 4100),
  fetch(request) {
    const url = new URL(request.url);

    if (url.pathname !== '/api/comprobantes') {
      return new Response('Not found', { status: 404 });
    }

    if (RETURN_BARE_ARRAY) {
      return Response.json(INVOICES);
    }

    const page = Number(url.searchParams.get('pagina') ?? 1);
    const limit = Number(url.searchParams.get('por_pagina') ?? 20);

    return Response.json({
      data: INVOICES.slice((page - 1) * limit, page * limit),
      meta: {
        pagina: page,
        por_pagina: limit,
        total: INVOICES.length,
        total_paginas: Math.ceil(INVOICES.length / limit),
      },
    });
  },
});

console.log(`stub backend on http://localhost:${server.port}`);
