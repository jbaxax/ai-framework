import { z } from 'zod';

export interface PageMeta {
  readonly total: number;
  readonly page: number;
  readonly limit: number;
  readonly totalPages: number;
}

export interface Page<T> {
  readonly items: readonly T[];
  readonly meta: PageMeta;
}

const pageMetaDtoSchema = z.object({
  total: z.coerce.number().int().nonnegative(),
  page: z.coerce.number().int().positive(),
  limit: z.coerce.number().int().positive(),
  total_pages: z.coerce.number().int().nonnegative(),
});

function toDomainMeta(dto: z.infer<typeof pageMetaDtoSchema>): PageMeta {
  return {
    total: dto.total,
    page: dto.page,
    limit: dto.limit,
    totalPages: dto.total_pages,
  };
}

export function paginatedSchema<TDto, TDomain>(
  itemSchema: z.ZodType<TDto>,
  toDomain: (dto: TDto) => TDomain,
) {
  return z
    .object({
      data: z.array(itemSchema),
      meta: pageMetaDtoSchema,
    })
    .transform(
      (dto): Page<TDomain> => ({
        items: dto.data.map(toDomain),
        meta: toDomainMeta(dto.meta),
      }),
    );
}

export function tolerantPaginatedSchema<TDto, TDomain>(
  itemSchema: z.ZodType<TDto>,
  toDomain: (dto: TDto) => TDomain,
) {
  const enveloped = paginatedSchema(itemSchema, toDomain);

  const bareArray = z.array(itemSchema).transform(
    (items): Page<TDomain> => ({
      items: items.map(toDomain),
      meta: {
        total: items.length,
        page: 1,
        limit: items.length,
        totalPages: 1,
      },
    }),
  );

  return z.union([enveloped, bareArray]);
}

export interface CursorPage<T, TCursor = string> {
  readonly items: readonly T[];
  readonly nextCursor: TCursor | null;
  readonly hasMore: boolean;
}

export function cursorPaginatedSchema<TDto, TDomain>(
  itemSchema: z.ZodType<TDto>,
  toDomain: (dto: TDto) => TDomain,
) {
  return z
    .object({
      data: z.array(itemSchema),
      meta: z.object({
        next_cursor: z.string().nullish(),
        has_more: z.boolean(),
      }),
    })
    .transform(
      (dto): CursorPage<TDomain> => ({
        items: dto.data.map(toDomain),
        nextCursor: dto.meta.next_cursor ?? null,
        hasMore: dto.meta.has_more,
      }),
    );
}
