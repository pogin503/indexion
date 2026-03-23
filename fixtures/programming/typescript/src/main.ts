/**
 * Entry point — initializes the user service and runs a demo.
 */
import { UserRole } from './types';
import { UserService } from './service';
import { formatDisplayName } from './utils';

async function main(): Promise<void> {
  const service = new UserService();
  await service.addUser({
    id: "u1",
    name: "Alice",
    email: "alice@example.com",
    role: UserRole.Admin,
  });

  const user = service.getUser("u1");
  if (user) {
    const display = formatDisplayName(user.name, user.role);
    console.log(display);
  }

  const viewers = service.listUsers({ role: UserRole.Viewer });
  console.log("Viewers:", viewers.length);
}

export default main;
