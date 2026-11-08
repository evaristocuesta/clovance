import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ToastContainer } from './toast-container';
import { ToastService } from './toast.service';
import { provideTestTransloco } from '@testing/test-transloco';

describe('ToastContainer', () => {
  let fixture: ComponentFixture<ToastContainer>;
  let toastService: ToastService;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ToastContainer],
      providers: [provideTestTransloco()],
    }).compileComponents();

    fixture = TestBed.createComponent(ToastContainer);
    toastService = TestBed.inject(ToastService);
  });

  it('renders no toasts initially', () => {
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).querySelectorAll('app-toast').length).toBe(0);
  });

  it('renders a toast added through the service', () => {
    toastService.success('Saved');
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain('Saved');
  });

  it('dismisses a toast from the service when the toast emits dismissed', () => {
    toastService.success('Saved');
    fixture.detectChanges();

    (fixture.nativeElement as HTMLElement)
      .querySelector('button')
      ?.dispatchEvent(new Event('click'));
    fixture.detectChanges();

    expect(toastService.toasts().length).toBe(0);
  });
});
