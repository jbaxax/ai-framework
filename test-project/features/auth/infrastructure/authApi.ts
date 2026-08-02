import { apiClient } from '@/lib/api/client';
import type { Credentials, User } from '../domain/types';
import { sessionResponseSchema, toDomainUser } from './authSchemas';

export async function login(credentials: Credentials): Promise<User> {
  const { data } = await apiClient.post('/auth/login', {
    email: credentials.email,
    password: credentials.password,
  });

  return toDomainUser(sessionResponseSchema.parse(data).user);
}

export async function logout(): Promise<void> {
  await apiClient.post('/auth/logout');
}

export async function fetchCurrentUser(): Promise<User | null> {
  try {
    const { data } = await apiClient.get('/auth/me');
    return toDomainUser(sessionResponseSchema.parse(data).user);
  } catch {
    return null;
  }
}
