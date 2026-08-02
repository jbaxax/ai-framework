import { z, type ZodType } from 'zod';

export interface Page<T> {
  readonly items: readonly T[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
  readonly totalPages: number;
}

const envelopeSchema = z.object({
  data: z.array(z.unknown()),
  meta: z.object({
    pagina: z.number().int().positive(),
    por_pagina: z.number().int().positive(),
    total: z.number().int().nonnegative(),
    total_paginas: z.number().int().nonnegative(),
  }),
});

export function parsePage<T>(raw: unknown, itemSchema: ZodType<T>): Page<T> {
  const envelope = envelopeSchema.parse(raw);

  return {
    items: envelope.data.map((item) => itemSchema.parse(item)),
    page: envelope.meta.pagina,
    limit: envelope.meta.por_pagina,
    total: envelope.meta.total,
    totalPages: envelope.meta.total_paginas,
  };
}

export interface CursorPage<T> {
  readonly items: readonly T[];
  readonly nextCursor: string | null;
}

const cursorEnvelopeSchema = z.object({
  data: z.array(z.unknown()),
  meta: z.object({ siguiente_cursor: z.string().nullable() }),
});

export function parseCursorPage<T>(raw: unknown, itemSchema: ZodType<T>): CursorPage<T> {
  const envelope = cursorEnvelopeSchema.parse(raw);

  return {
    items: envelope.data.map((item) => itemSchema.parse(item)),
    nextCursor: envelope.meta.siguiente_cursor,
  };
}
