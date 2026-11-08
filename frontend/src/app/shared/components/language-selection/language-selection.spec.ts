import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';

import { LanguageSelection } from './language-selection';
import { provideTestTransloco } from '@testing/test-transloco';

describe('LanguageSelection', () => {
  let component: LanguageSelection;
  let fixture: ComponentFixture<LanguageSelection>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LanguageSelection],
      providers: [provideTestTransloco()],
    }).compileComponents();

    fixture = TestBed.createComponent(LanguageSelection);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('ignores a language that is not available', () => {
    const translocoService = TestBed.inject(TranslocoService);
    localStorage.removeItem('clovance-lang');

    component.changeLanguage('fr');

    expect(translocoService.getActiveLang()).toBe('en');
    expect(localStorage.getItem('clovance-lang')).toBeNull();
  });
});
