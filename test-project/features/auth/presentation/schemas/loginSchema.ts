import { z } from 'zod';
import type { Credentials } from '../../domain/types';
import { normalizeEmail } from '../../domain/session';

export const loginSchema = z.object({
  email: z.email('Enter a valid email'),
  password: z.string().min(1, 'Enter your password'),
});

export type LoginForm = z.infer<typeof loginSchema>;

export function toCredentials(form: LoginForm): Credentials {
  return {
    email: normalizeEmail(form.email),
    password: form.password,
  };
}
