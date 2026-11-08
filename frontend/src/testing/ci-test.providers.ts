import { provideHttpClient } from '@angular/common/http';
import { DIALOG_DATA, DialogRef } from '@angular/cdk/dialog';
import { EnvironmentProviders, Provider } from '@angular/core';
import { provideRouter } from '@angular/router';

import { provideTestTransloco } from '@testing/test-transloco';

const providers: Array<Provider | EnvironmentProviders> = [
  provideHttpClient(),
  provideRouter([]),
  provideTestTransloco(),
  {
    provide: DialogRef,
    useValue: {
      close: () => {
        // No-op DialogRef used for unit tests that instantiate dialog components directly.
      },
    },
  },
  {
    provide: DIALOG_DATA,
    useValue: {},
  },
];

export default providers;
