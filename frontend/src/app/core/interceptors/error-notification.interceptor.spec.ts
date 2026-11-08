import {
  HttpErrorResponse,
  HttpHandlerFn,
  HttpInterceptorFn,
  HttpRequest,
  HttpResponse,
} from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { ToastService } from '@shared/ui/toast/toast.service';

import { errorNotificationInterceptor } from './error-notification.interceptor';
import { provideTestTransloco } from '@testing/test-transloco';

describe('errorNotificationInterceptor', () => {
  const interceptor: HttpInterceptorFn = (req, next) =>
    TestBed.runInInjectionContext(() => errorNotificationInterceptor(req, next));

  let toastService: ToastService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideTestTransloco()],
    });

    toastService = TestBed.inject(ToastService);
  });

  it('shows a toast translated from the backend error code', () => {
    const next: HttpHandlerFn = () =>
      throwError(
        () =>
          new HttpErrorResponse({
            status: 401,
            url: '/api/auth/login',
            error: { errorCode: 'auth.invalid_credentials' },
          }),
      );

    interceptor(new HttpRequest('POST', '/api/auth/login', {}), next).subscribe({
      error: () => {
        // Expected: the interceptor must still propagate the error.
      },
    });

    expect(toastService.toasts()).toEqual([
      { id: 0, variant: 'error', message: 'Invalid email or password' },
    ]);
  });

  it('falls back to a generic message when there is no error code', () => {
    const next: HttpHandlerFn = () =>
      throwError(() => new HttpErrorResponse({ status: 0, url: '/api/transactions' }));

    interceptor(new HttpRequest('GET', '/api/transactions'), next).subscribe({
      error: () => {
        // Expected: the interceptor must still propagate the error.
      },
    });

    expect(toastService.toasts()).toEqual([
      { id: 0, variant: 'error', message: 'An unexpected error occurred.' },
    ]);
  });

  it('still propagates the error to the caller', () => {
    const errors: unknown[] = [];
    const next: HttpHandlerFn = () =>
      throwError(() => new HttpErrorResponse({ status: 500, url: '/api/accounts' }));

    interceptor(new HttpRequest('GET', '/api/accounts'), next).subscribe({
      error: (error) => errors.push(error),
    });

    expect(errors).toHaveLength(1);
  });

  it.each(['/api/auth/refresh', '/api/auth/logout'])(
    'does not show a toast for silent calls to %s',
    (url) => {
      const next: HttpHandlerFn = () =>
        throwError(() => new HttpErrorResponse({ status: 401, url }));

      interceptor(new HttpRequest('POST', url, {}), next).subscribe({
        error: () => {
          // Expected: silent calls still propagate their error, just without a toast.
        },
      });

      expect(toastService.toasts()).toEqual([]);
    },
  );

  it('does not show a toast for non-API calls', () => {
    const next: HttpHandlerFn = () =>
      throwError(() => new HttpErrorResponse({ status: 500, url: '/i18n/en.json' }));

    interceptor(new HttpRequest('GET', '/i18n/en.json'), next).subscribe({
      error: () => {
        // Expected: non-API calls (e.g. translation files) are left alone.
      },
    });

    expect(toastService.toasts()).toEqual([]);
  });

  it('does not show a toast for a successful call', () => {
    const next: HttpHandlerFn = () => of(new HttpResponse({ status: 200 }));

    interceptor(new HttpRequest('GET', '/api/transactions'), next).subscribe();

    expect(toastService.toasts()).toEqual([]);
  });
});
