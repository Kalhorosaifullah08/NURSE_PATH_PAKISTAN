import { createHash } from 'node:crypto';
import { canPublish, validateItem } from './policy.mjs';

export function buildSemesterPackage({ semester, curriculumVersion, packageVersion, items }) {
  if (!Number.isInteger(semester) || semester < 1 || semester > 8) throw new Error('Semester must be between 1 and 8');
  if (!Array.isArray(items) || items.length === 0) throw new Error('A package requires content');
  for (const item of items) {
    const result = validateItem(item);
    if (!result.valid) throw new Error(`Invalid item ${item.id}: ${result.errors.join(', ')}`);
    if (item.semester !== semester) throw new Error(`Item ${item.id} belongs to another semester`);
    if (!canPublish(item)) throw new Error(`Item ${item.id} has not passed release policy`);
  }
  const payload = {
    formatVersion: 1,
    curriculumVersion,
    packageVersion,
    semester,
    createdAt: new Date().toISOString(),
    items: [...items].sort((a, b) => a.id.localeCompare(b.id)),
  };
  const canonical = JSON.stringify(payload);
  return {
    manifest: {
      formatVersion: 1,
      curriculumVersion,
      packageVersion,
      semester,
      itemCount: items.length,
      sha256: createHash('sha256').update(canonical).digest('hex'),
    },
    payload,
  };
}
