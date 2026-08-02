import { LoginForm } from '@/features/auth/presentation/components/LoginForm';

/** The page composes the feature. No business logic lives in `app/`. */
export default function LoginPage() {
  return (
    <main>
      <LoginForm />
    </main>
  );
}
