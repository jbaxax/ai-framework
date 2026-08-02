/**
 * The boundary. API payloads become domain objects here.
 *
 * Even though this backend is our own route handler, the response is still
 * parsed. The rule is not "distrust strangers" — it is "validate at the edge",
 * so a shape change fails here instead of in a component.
 */

import { z } from 'zod';
import type { User } from '../domain/types';

const userDtoSchema = z.object({
  id: z.string(),
  email: z.email(),
  display_name: z.string(),
});

export const sessionResponseSchema = z.object({
  user: userDtoSchema,
});

type UserDto = z.infer<typeof userDtoSchema>;

/** API vocabulary stops here: `display_name` never reaches the domain. */
export function toDomainUser(dto: UserDto): User {
  return {
    id: dto.id,
    email: dto.email,
    displayName: dto.display_name,
  };
}

export function toUserDto(user: User) {
  return {
    id: user.id,
    email: user.email,
    display_name: user.displayName,
  };
}
