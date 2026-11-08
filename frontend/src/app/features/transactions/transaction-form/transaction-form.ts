import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { Transaction } from '../models/transaction.model';
import { DIALOG_DATA, DialogRef } from '@angular/cdk/dialog';
import { SaveTransactionDto, TransactionService } from '../services/transaction.service';
import { firstValueFrom } from 'rxjs';
import { form, FormField, FormRoot, required, validate } from '@angular/forms/signals';
import { HttpErrorResponse } from '@angular/common/http';
import { Icon } from '@shared/ui/icon/icon';
import { TranslocoDirective, TranslocoService } from '@jsverse/transloco';
import { ToastService } from '@shared/ui/toast/toast.service';
import { Account } from '@features/accounts/models/account.model';
import { toDateOnlyString } from '@shared/utils/date-utils';
import { Dialog } from '@shared/ui/dialog/dialog';

export interface TransactionFormData {
  transaction?: Transaction;
  type: 'Income' | 'Expense' | 'Transfer' | 'OpeningBalance' | 'LoanPayment';
  accounts: Account[];
}

@Component({
  selector: 'app-transaction-form',
  imports: [TranslocoDirective, FormField, FormRoot, Icon, Dialog],
  templateUrl: './transaction-form.html',
  styleUrl: './transaction-form.css',
})
export class TransactionForm implements OnInit {
  errorMessage = signal('');

  transaction = signal<Transaction>({
    id: '',
    date: new Date(),
    description: '',
    amount: 0,
    accountId: '',
    type: 'Income',
    accountName: '',
    currency: '',
    version: 0,
  });

  accounts = computed(() =>
    this.data?.type === 'OpeningBalance' && this.transaction().id
      ? (this.data?.accounts?.filter((a) => a.id === this.transaction().accountId) ?? [])
      : (this.data?.accounts?.filter(
          (a) =>
            (Account.canBeUsedForIncomeOrExpense(a) && !a.isDeleted) ||
            (a.id === this.transaction().accountId && a.isDeleted),
        ) ?? []),
  );

  private readonly transactionService = inject(TransactionService);
  private readonly toastService = inject(ToastService);
  private readonly translocoService = inject(TranslocoService);

  dialogRef = inject<DialogRef>(DialogRef);
  data = inject<TransactionFormData | undefined>(DIALOG_DATA);

  ngOnInit(): void {
    const dataType = this.data?.type;

    if (dataType) {
      this.transaction.update((t) => ({ ...t, type: dataType }));
    }

    if (this.data?.transaction) {
      this.transaction.set(this.data.transaction);

      if (this.data?.type === 'Expense') {
        this.transaction.update((t) => ({ ...t, amount: Math.abs(t.amount) }));
      }

      if (dataType) {
        this.transaction.update((t) => ({ ...t, type: dataType }));
      }

      // Re-read the transaction so the version sent on save is the one the user is
      // looking at, not whatever the in-memory list last held. Without this a stale
      // list makes the save fail permanently: reopening the dialog would reuse the
      // same outdated version and hit the same 409 again.
      firstValueFrom(this.transactionService.getTransactionById(this.data.transaction.id))
        .then((transaction) => {
          this.transaction.set({
            ...transaction,
            // Keep showing the amounts and type this dialog edits with, which for an
            // expense are the absolute value of what the list stores.
            amount:
              this.data?.type === 'Expense' ? Math.abs(transaction.amount) : transaction.amount,
            type: dataType ?? transaction.type,
          });
        })
        .catch(() => {
          // Fall back to the data the dialog was opened with; the save is still refused
          // if that turns out to be stale.
        });
    }
  }

  close() {
    this.dialogRef.close();
  }

  transactionForm = form(
    this.transaction,
    (schemaPath) => {
      required(schemaPath.date, { message: 'transactions.dateRequired' });
      required(schemaPath.description, { message: 'transactions.descriptionRequired' });
      required(schemaPath.amount, { message: 'transactions.amountRequired' });
      validate(schemaPath.amount, ({ value, valueOf }) => {
        const type = valueOf(schemaPath.type);

        if (type === 'OpeningBalance') {
          return null;
        }

        const amount = value();
        if (amount <= 0) {
          return {
            kind: 'amountGreaterThanZero',
            message: 'transactions.amountGreaterThanZero',
          };
        }
        return null;
      });
      required(schemaPath.accountId, { message: 'transactions.accountRequired' });
      required(schemaPath.type, { message: 'transactions.typeRequired' });
    },
    {
      submission: {
        action: async (field) => {
          this.errorMessage.set('');

          try {
            const formValue = field().value();

            const dto: SaveTransactionDto = {
              date: toDateOnlyString(formValue.date),
              description: formValue.description,
              amount: formValue.amount,
              type: formValue.type,
              accountId: formValue.accountId,
            };

            if (dto.type === 'Expense') {
              dto.amount = -Math.abs(dto.amount);
            }

            if (this.data?.transaction?.id) {
              // Send back the version the form was filled from so the API can refuse the
              // save if someone else changed the transaction in the meantime.
              await firstValueFrom(
                this.transactionService.updateTransaction(this.data.transaction.id, {
                  ...dto,
                  version: this.transaction().version,
                }),
              );
            } else {
              await firstValueFrom(this.transactionService.createTransaction(dto));
            }
            this.toastService.success(this.translocoService.translate('transactions.saved'));
            this.dialogRef.close(true);
          } catch (err: HttpErrorResponse | any) {
            const errorCode = (err as { error: { errorCode?: string } })?.error?.errorCode;
            const key = errorCode ? errorCode : 'transactions.serverError';
            this.errorMessage.set(key);
          }
        },
      },
    },
  );
}
