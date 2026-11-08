import { EnvironmentProviders, Provider, inject, provideAppInitializer } from '@angular/core';
import {
  provideTransloco,
  Translation,
  TranslocoLoader,
  TranslocoService,
} from '@jsverse/transloco';
import { Observable, of } from 'rxjs';

import en from '../../public/i18n/en.json';
import es from '../../public/i18n/es.json';

const TRANSLATIONS: Record<string, Translation> = { en, es };

class TranslocoTestLoader implements TranslocoLoader {
  getTranslation(lang: string): Observable<Translation> {
    return of(TRANSLATIONS[lang] ?? en);
  }
}

/**
 * Test replacement for the app's Transloco setup (`app.config.ts`). It serves the real
 * dictionaries from `public/i18n` and preloads both languages synchronously during TestBed
 * initialization, so synchronous `TranslocoService.translate()` calls resolve real values
 * instead of logging `Missing translation for '...'` warnings. Any warning that still shows
 * up after this indicates a key that is genuinely missing from the JSON files.
 */
export function provideTestTransloco(): Array<Provider | EnvironmentProviders> {
  return [
    provideTransloco({
      config: {
        availableLangs: ['en', 'es'],
        defaultLang: 'en',
        reRenderOnLangChange: true,
        prodMode: true,
      },
      loader: TranslocoTestLoader,
    }),
    provideAppInitializer(() => {
      const transloco = inject(TranslocoService);
      transloco.setTranslation(en as Translation, 'en', { emitChange: false });
      transloco.setTranslation(es as Translation, 'es', { emitChange: false });
    }),
  ];
}
