import { runContracts, type ContractDefinition } from './contract';
import { invoicesContract } from './invoices.contract';

const CONTRACTS = [invoicesContract] as unknown as ContractDefinition<never, never>[];

const ICON: Record<string, string> = { pass: 'PASS', fail: 'FAIL', warn: 'WARN', skip: 'SKIP' };

const { results, report, exitCode } = await runContracts(CONTRACTS);

for (const result of results) {
  console.log(`\n${result.verdict}  ${result.name}`);
  for (const check of result.checks) {
    console.log(`  [${ICON[check.status]}] ${check.name}`);
    for (const line of check.detail.split('\n')) console.log(`         ${line}`);
  }
}

if (exitCode !== 0) {
  const path = Bun.env['REPORT'] ?? 'contract-drift.md';
  await Bun.write(path, report);
  console.log(`\nDrift report written to ${path} — send it to the backend author.`);
}

process.exit(exitCode);
