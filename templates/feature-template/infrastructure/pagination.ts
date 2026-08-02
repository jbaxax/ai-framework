/**
 * Generic pagination contract — shared by every feature.
 *
 * In a real project this file belongs in `lib/api/pagination.ts`, not inside a
 * feature. It is here so the template is self-contained.
 *
 * The point is to type the envelope ONCE. Every feature passes its own item
 * schema and gets a validated, typed page back.
 */

import { z } from 'zod';

/** Pagination metadata, in domain vocabulary. */
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
 * Builds a schema for a paginated response of `itemSchema`, and maps each item
 * to the domain with `toDomain`.
 *
 * Unlike a cast, this validates every item. If the backend renames a field
 * inside an item, the failure happens here with the exact path — not as an
 * `undefined` several layers up in a component.
 *
 * @example
 *   const schema = paginatedSchema(invoiceDtoSchema, toDomainInvoice);
 *   const page = schema.parse(response); // Page<Invoice>
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
 * Same contract for endpoints that are DOCUMENTED as paginated but actually
 * return a bare array. Use this only after verifying the real response.
 *
 * Two rules this deliberately follows:
 *
 *  1. Items are still validated. Tolerating a missing envelope is not the same
 *     as trusting the payload.
 *  2. An unrecognized shape THROWS. It must never be normalized into an empty
 *     page — a broken response rendered as "no results" is a silent failure
 *     that costs hours to trace. Loud beats convenient.
 *
 * Reaching for this is a signal to report the mismatch to the backend author,
 * not a reason to stop reporting it.
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
 * The reason to prefer a cursor for feeds is correctness, not fashion. With
 * `page/limit`, a row inserted while the user is browsing shifts everything
 * down, so page 2 repeats an item page 1 already showed. A cursor points at a
 * concrete record, so insertions do not shift the window.
 *
 * Trade-off: no total count and no jumping to an arbitrary page. If the screen
 * needs "page 7 of 30", cursor pagination is the wrong tool.
 */
export interface CursorPage<T, TCursor = string> {
  readonly items: readonly T[];
  /** Pass to the next request. `null` means the end was reached. */
  readonly nextCursor: TCursor | null;
  readonly hasMore: boolean;
}

/**
 * @example
 *   const schema = cursorPaginatedSchema(invoiceDtoSchema, toDomainInvoice);
 *   // with React Query:
 *   useInfiniteQuery({
 *     queryKey: invoiceKeys.all,
 *     queryFn: ({ pageParam }) => fetchInvoicePage(pageParam),
 *     initialPageParam: null,
 *     getNextPageParam: (last) => last.nextCursor,
 *   });
 */
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
