'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { ApiError } from '@/lib/api/client';
import { useLogin } from '../../application/useLogin';
import { loginSchema, toCredentials, type LoginForm as LoginFormValues } from '../schemas/loginSchema';

/** One message for every rejection. Naming the cause enumerates accounts. */
const GENERIC_ERROR = 'Invalid email or password.';
const RATE_LIMITED = 'Too many attempts. Try again later.';

export function LoginForm() {
  const login = useLogin();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await login.mutateAsync(toCredentials(values));
    } catch {
      // Handled through `login.error` below; nothing is logged.
    }
  });

  const failureMessage =
    login.error instanceof ApiError && login.error.kind === 'rate-limited'
      ? RATE_LIMITED
      : GENERIC_ERROR;

  return (
    <form onSubmit={onSubmit} noValidate>
      <h1>Sign in</h1>

      <label htmlFor="email">Email</label>
      <input id="email" type="email" autoComplete="email" {...register('email')} />
      {errors.email && <p role="alert">{errors.email.message}</p>}

      <label htmlFor="password">Password</label>
      <input
        id="password"
        type="password"
        autoComplete="current-password"
        {...register('password')}
      />
      {errors.password && <p role="alert">{errors.password.message}</p>}

      <button type="submit" disabled={isSubmitting || login.isPending}>
        {login.isPending ? 'Signing in…' : 'Sign in'}
      </button>

      {login.isError && <p role="alert">{failureMessage}</p>}
    </form>
  );
}
