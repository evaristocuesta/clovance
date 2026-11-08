import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Toast } from './toast';
import { ToastMessage } from './toast.model';
import { provideTestTransloco } from '@testing/test-transloco';

describe('Toast', () => {
  let fixture: ComponentFixture<Toast>;
  let component: Toast;

  const setToast = (toast: ToastMessage) => {
    fixture.componentRef.setInput('toast', toast);
    fixture.detectChanges();
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Toast],
      providers: [provideTestTransloco()],
    }).compileComponents();

    fixture = TestBed.createComponent(Toast);
    component = fixture.componentInstance;
  });

  it('renders the toast message', () => {
    setToast({ id: 1, variant: 'success', message: 'Saved successfully' });

    expect((fixture.nativeElement as HTMLElement).textContent).toContain('Saved successfully');
  });

  it.each([
    ['success', 'status'],
    ['info', 'status'],
    ['error', 'alert'],
  ] as const)('uses role "%s" -> "%s" depending on the variant', (variant, role) => {
    setToast({ id: 1, variant, message: 'Message' });

    expect((fixture.nativeElement as HTMLElement).querySelector(`[role="${role}"]`)).not.toBeNull();
  });

  it('emits dismissed with the toast id when closed', () => {
    setToast({ id: 42, variant: 'info', message: 'Message' });
    const dismissed = vi.fn();
    component.dismissed.subscribe(dismissed);

    (fixture.nativeElement as HTMLElement)
      .querySelector('button')
      ?.dispatchEvent(new Event('click'));

    expect(dismissed).toHaveBeenCalledWith(42);
  });

  it('emits paused and resumed on hover in/out', () => {
    setToast({ id: 7, variant: 'success', message: 'Message' });
    const paused = vi.fn();
    const resumed = vi.fn();
    component.paused.subscribe(paused);
    component.resumed.subscribe(resumed);

    const root = (fixture.nativeElement as HTMLElement).firstElementChild as HTMLElement;
    root.dispatchEvent(new Event('mouseenter'));
    root.dispatchEvent(new Event('mouseleave'));

    expect(paused).toHaveBeenCalledWith(7);
    expect(resumed).toHaveBeenCalledWith(7);
  });
});
