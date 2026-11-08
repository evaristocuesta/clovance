import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject, of, throwError } from 'rxjs';

import { TransactionList } from './transaction-list';
import { AccountService } from '@features/accounts/services/account.service';
import { TransactionService } from '../services/transaction.service';
import { DialogService } from '@shared/ui/dialog/dialog.service';
import { ToastService } from '@shared/ui/toast/toast.service';

describe('TransactionList', () => {
  let component: TransactionList;
  let fixture: ComponentFixture<TransactionList>;
  let deleteTransaction: ReturnType<typeof vi.fn>;
  let dialogClosed$: Subject<boolean>;

  const sampleTransaction = {
    id: 'tx-1',
    accountId: 'acc-1',
    accountName: 'Main account',
    currency: 'EUR',
    amount: -20,
    date: new Date(),
    description: 'Groceries',
    type: 'Expense',
    version: 0,
  };

  beforeEach(async () => {
    dialogClosed$ = new Subject<boolean>();
    deleteTransaction = vi.fn(() => of(void 0));

    await TestBed.configureTestingModule({
      imports: [TransactionList],
      providers: [
        {
          provide: AccountService,
          useValue: {
            getCurrencies: () => of([]),
            getAccounts: () => of([]),
          },
        },
        {
          provide: TransactionService,
          useValue: {
            getTransactionsPage: () =>
              of({
                items: [sampleTransaction],
                hasMore: false,
                nextCursorDate: null,
                nextCursorId: null,
              }),
            getTransactionById: () => of(sampleTransaction),
            deleteTransaction,
          },
        },
        {
          provide: DialogService,
          useValue: {
            open: () => ({ closed: dialogClosed$.asObservable() }),
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(TransactionList);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('does not delete the transaction when the confirmation dialog is dismissed', () => {
    component.onDelete('tx-1');

    dialogClosed$.next(false);

    expect(deleteTransaction).not.toHaveBeenCalled();
  });

  it('shows a success toast after confirming the delete', () => {
    const toastService = TestBed.inject(ToastService);

    component.onDelete('tx-1');
    dialogClosed$.next(true);

    expect(deleteTransaction).toHaveBeenCalledWith('tx-1');
    expect(toastService.toasts()).toEqual([
      { id: 0, variant: 'success', message: 'Transaction deleted' },
    ]);
  });

  it('does not show a toast when the delete fails (the global HTTP interceptor already shows one)', () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {});
    deleteTransaction.mockReturnValue(throwError(() => new Error('boom')));
    const toastService = TestBed.inject(ToastService);

    component.onDelete('tx-1');
    dialogClosed$.next(true);

    expect(toastService.toasts()).toEqual([]);
    // The failure is logged for debugging; keep the assertion so the spy cannot be
    // removed without the test noticing.
    expect(consoleError).toHaveBeenCalledWith('Error deleting transaction:', expect.any(Error));
    consoleError.mockRestore();
  });
});
