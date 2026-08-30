import type { ZodType } from 'zod';

export type CheckStatus = 'pass' | 'fail' | 'warn' | 'skip';

export type ContractCheck = {
  name: string;
  status: CheckStatus;
  detail: string;
};

export type ContractDefinition<TDocumented, TDomain> = {
  name: string;
  url: string;
  init?: RequestInit;
  documented: ZodType<TDocumented>;
  wireVocabulary?: readonly string[];
  map?: (documented: TDocumented) => TDomain;
};

export type ContractResult = {
  name: string;
  url: string;
  status: number | null;
  checks: ContractCheck[];
  verdict: 'PASS' | 'DRIFT' | 'UNREACHABLE';
  rawSample: string;
};

const SAMPLE_LENGTH = 400;

function collectKeys(value: unknown, into: Set<string>): Set<string> {
  if (Array.isArray(value)) {
    for (const entry of value) collectKeys(entry, into);
    return into;
  }
  if (value !== null && typeof value === 'object' && !(value instanceof Date)) {
    for (const [key, child] of Object.entries(value)) {
      into.add(key);
      collectKeys(child, into);
    }
  }
  return into;
}

function describeIssues(error: unknown): string {
  const issues = (error as { issues?: unknown }).issues;
  if (!Array.isArray(issues)) return String(error);

  return issues
    .map((raw) => {
      const issue = raw as {
        path?: unknown[];
        message?: string;
        expected?: string;
        received?: string;
      };
      const path = Array.isArray(issue.path) && issue.path.length > 0 ? issue.path.join('.') : '(root)';
      const expected = issue.expected ? ` expected \`${issue.expected}\`` : '';
      const received = issue.received ? `, received \`${issue.received}\`` : '';
      return `- \`${path}\`:${expected}${received} — ${issue.message ?? 'invalid'}`;
    })
    .join('\n');
}

export async function verifyContract<TDocumented, TDomain>(
  definition: ContractDefinition<TDocumented, TDomain>,
): Promise<ContractResult> {
  const checks: ContractCheck[] = [];
  let status: number | null = null;
  let rawSample = '';

  let raw: unknown;
  try {
    const response = await fetch(definition.url, definition.init);
    status = response.status;
    raw = await response.json();
    rawSample = JSON.stringify(raw).slice(0, SAMPLE_LENGTH);

    checks.push({
      name: 'Endpoint reachable',
      status: response.ok ? 'pass' : 'fail',
      detail: `HTTP ${response.status} ${response.statusText}`,
    });

    if (!response.ok) {
      return { name: definition.name, url: definition.url, status, checks, verdict: 'UNREACHABLE', rawSample };
    }
  } catch (error) {
    checks.push({
      name: 'Endpoint reachable',
      status: 'fail',
      detail: error instanceof Error ? error.message : String(error),
    });
    return { name: definition.name, url: definition.url, status, checks, verdict: 'UNREACHABLE', rawSample };
  }

  const parsed = definition.documented.safeParse(raw);

  checks.push({
    name: 'Response matches documented shape',
    status: parsed.success ? 'pass' : 'fail',
    detail: parsed.success ? 'every documented field present with the promised type' : describeIssues(parsed.error),
  });

  if (!parsed.success) {
    return { name: definition.name, url: definition.url, status, checks, verdict: 'DRIFT', rawSample };
  }

  const wireKeys = collectKeys(raw, new Set<string>());
  const documentedKeys = collectKeys(parsed.data, new Set<string>());
  const undocumented = [...wireKeys].filter((key) => !documentedKeys.has(key));

  checks.push({
    name: 'No undocumented fields',
    status: undocumented.length === 0 ? 'pass' : 'warn',
    detail:
      undocumented.length === 0
        ? 'the response carries nothing the documentation did not promise'
        : `present in the response, absent from the documentation: ${undocumented.join(', ')}`,
  });

  if (!definition.map) {
    checks.push({ name: 'Wire vocabulary stops at infrastructure', status: 'skip', detail: 'no map supplied' });
  } else {
    const domainKeys = collectKeys(definition.map(parsed.data), new Set<string>());
    const vocabulary = definition.wireVocabulary ?? [...wireKeys];
    const leaked = vocabulary.filter((key) => domainKeys.has(key));

    checks.push({
      name: 'Wire vocabulary stops at infrastructure',
      status: leaked.length === 0 ? 'pass' : 'fail',
      detail:
        leaked.length === 0
          ? 'backend field names did not reach the mapped result'
          : `leaked into the domain: ${leaked.join(', ')}`,
    });
  }

  const failed = checks.some((check) => check.status === 'fail');
  return {
    name: definition.name,
    url: definition.url,
    status,
    checks,
    verdict: failed ? 'DRIFT' : 'PASS',
    rawSample,
  };
}

export function toDriftReport(results: readonly ContractResult[]): string {
  const drifted = results.filter((result) => result.verdict !== 'PASS');
  const stamp = new Date().toISOString();

  if (drifted.length === 0) {
    return `# Contract verification — ${stamp}\n\nAll ${results.length} contract(s) match the documentation.\n`;
  }

  const sections = drifted.map((result) => {
    const rows = result.checks
      .map((check) => `**${check.name}** — ${check.status.toUpperCase()}\n\n${check.detail}`)
      .join('\n\n');

    return [
      `## ${result.name}`,
      '',
      `- Endpoint: \`${result.url}\``,
      `- HTTP status: ${result.status ?? 'no response'}`,
      `- Verified at: ${stamp}`,
      '',
      rows,
      '',
      '<details><summary>Response received</summary>',
      '',
      '```json',
      result.rawSample,
      '```',
      '',
      '</details>',
    ].join('\n');
  });

  return [
    `# Contract drift — ${stamp}`,
    '',
    `${drifted.length} of ${results.length} contract(s) do not match the documentation.`,
    '',
    ...sections,
  ].join('\n');
}

export async function runContracts(
  definitions: readonly ContractDefinition<never, never>[],
): Promise<{ results: ContractResult[]; report: string; exitCode: number }> {
  const results: ContractResult[] = [];
  for (const definition of definitions) {
    results.push(await verifyContract(definition));
  }

  const report = toDriftReport(results);
  const exitCode = results.some((result) => result.verdict !== 'PASS') ? 1 : 0;
  return { results, report, exitCode };
}
