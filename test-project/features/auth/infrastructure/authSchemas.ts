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
