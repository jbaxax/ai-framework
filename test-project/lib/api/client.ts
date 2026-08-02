/**
 * The shared HTTP client. One configured instance, never `axios.get(...)` ad hoc.
 *
 * `withCredentials` sends the session cookie. No `Authorization` header is ever
 * assembled here, because no token is ever readable by this code — that is the
 * point of an `HttpOnly` cookie.
 */

import axios from 'axios';

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL ?? '/api',
  timeout: 10_000,
  withCredentials: true,
});

/** Errors crossing into the domain, so no layer above sees an `AxiosError`. */
export type ApiErrorKind =
  | 'unauthorized'
  | 'forbidden'
  | 'not-found'
  | 'validation'
  | 'rate-limited'
  | 'server'
  | 'network';

export class ApiError extends Error {
  constructor(
    readonly kind: ApiErrorKind,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

const KIND_BY_STATUS: Record<number, ApiErrorKind> = {
  401: 'unauthorized',
  403: 'forbidden',
  404: 'not-found',
  422: 'validation',
  429: 'rate-limited',
};

apiClient.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    if (!axios.isAxiosError(error)) {
      return Promise.reject(new ApiError('network', 'Unexpected error.'));
    }

    const status = error.response?.status;

    if (status === undefined) {
      return Promise.reject(new ApiError('network', 'Could not reach the server.'));
    }

    const kind = KIND_BY_STATUS[status] ?? 'server';

    // Never log or forward headers, tokens, or the raw request body.
    return Promise.reject(new ApiError(kind, 'The request failed.'));
  },
);
