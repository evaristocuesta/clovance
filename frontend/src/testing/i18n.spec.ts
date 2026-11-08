import en from '../../public/i18n/en.json';
import es from '../../public/i18n/es.json';

type TranslationNode = string | { [key: string]: TranslationNode };

function flattenKeys(node: TranslationNode, prefix = ''): Map<string, string> {
  const entries = new Map<string, string>();

  if (typeof node === 'string') {
    entries.set(prefix, node);
    return entries;
  }

  for (const [key, child] of Object.entries(node)) {
    const path = prefix ? `${prefix}.${key}` : key;
    for (const [nestedKey, value] of flattenKeys(child, path)) {
      entries.set(nestedKey, value);
    }
  }

  return entries;
}

describe('i18n dictionaries', () => {
  const enKeys = flattenKeys(en as TranslationNode);
  const esKeys = flattenKeys(es as TranslationNode);

  it('has a Spanish translation for every English key', () => {
    const missingInSpanish = [...enKeys.keys()].filter((key) => !esKeys.has(key));

    expect(missingInSpanish).toEqual([]);
  });

  it('has an English translation for every Spanish key', () => {
    const orphanedInSpanish = [...esKeys.keys()].filter((key) => !enKeys.has(key));

    expect(orphanedInSpanish).toEqual([]);
  });

  it('has no empty translation values', () => {
    const emptyKeys = [...enKeys, ...esKeys]
      .filter(([, value]) => value.trim() === '')
      .map(([key]) => key);

    expect([...new Set(emptyKeys)]).toEqual([]);
  });
});
