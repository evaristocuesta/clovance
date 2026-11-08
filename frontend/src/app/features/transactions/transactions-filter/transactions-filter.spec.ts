import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TransactionsFilter } from './transactions-filter';

describe('TransactionsFilter', () => {
  let component: TransactionsFilter;
  let fixture: ComponentFixture<TransactionsFilter>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TransactionsFilter],
    }).compileComponents();

    fixture = TestBed.createComponent(TransactionsFilter);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('shows a validation error when the description search exceeds the maximum length', () => {
    const descriptionInput: HTMLInputElement = fixture.nativeElement.querySelector(
      '#transaction-description',
    );
    descriptionInput.value = 'a'.repeat(251);
    descriptionInput.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain(
      'Search text must be 250 characters or fewer',
    );
  });
});
