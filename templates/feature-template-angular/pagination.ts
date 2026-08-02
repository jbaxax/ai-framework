/**
 * Generic pagination contract — shared by every feature.
 *
 * In a real project this belongs in `core/pagination.ts`: it IS cross-cutting,
 * which is what `core/` is actually for. It is kept here so the template is
 * self-contained.
 *
 * Type the envelope ONCE. Each feature passes its own item schema.
 */

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

/**
 * Describe the envelope AS THE BACKEND SENDS IT, verified against a real call.
 * Adjust these field names per project — do not copy them from a `.md`.
 */
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

/**
 * Validates every item, unlike a cast. If the backend renames a field inside an
 * item, this fails here with the exact path.
 */
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

/**
 * For endpoints DOCUMENTED as paginated that actually return a bare array.
 * Use only after verifying the real response.
 *
 *  1. Items are still validated. Tolerating a missing envelope is not trusting
 *     the payload.
 *  2. An unrecognized shape THROWS. Never normalize a broken response into an
 *     empty page — "no results" hides the failure and costs hours to trace.
 */
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

/* ------------------------------------------------------------------------- *
 * Cursor pagination — "load more" / infinite scroll
 * ------------------------------------------------------------------------- */

/**
 * A different contract, not a variant of the one above. Choose deliberately:
 *
 *   page/limit  → the user picks a page; you can show "page 3 of 12"
 *   cursor      → the user scrolls; you only know whether more exists
 *
 * The reason to prefer a cursor for feeds is correctness. With `page/limit`, a
 * row inserted while the user browses shifts everything down, so page 2 repeats
 * an item page 1 already showed. A cursor points at a concrete record.
 *
 * Trade-off: no total count and no jumping to an arbitrary page. If the screen
 * needs "page 7 of 30", cursor pagination is the wrong tool.
 *
 * In a store, accumulate instead of replacing:
 *   this._items.update((current) => [...current, ...page.items]);
 *   this._cursor.set(page.nextCursor);
 */
export interface CursorPage<T, TCursor = string> {
  readonly items: readonly T[];
  /** Pass to the next request. `null` means the end was reached. */
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
        // Describe the real payload. Some backends omit the field at the end,
        // others send null — accept both rather than guessing.
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
