import { Component, inject, OnInit, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { Account } from '../models/account.model';
import { form, FormField, FormRoot, maxLength, minLength, required } from '@angular/forms/signals';
import { firstValueFrom, map } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';
import { AccountService } from '../services/account.service';
import { TranslocoDirective, TranslocoService } from '@jsverse/transloco';
import { ToastService } from '@shared/ui/toast/toast.service';
import { DIALOG_DATA, DialogRef } from '@angular/cdk/dialog';
import { Icon } from '@shared/ui/icon/icon';
import { Currency } from '../models/currency.model';
import { AccountOpeningBalance } from '../models/accountOpeningBalance';
import { toDateOnlyString } from '@shared/utils/date-utils';
import { Dialog } from '@shared/ui/dialog/dialog';

@Component({
  selector: 'app-account-form',
  imports: [TranslocoDirective, FormField, FormRoot, Icon, Dialog],
  templateUrl: './account-form.html',
  styleUrl: './account-form.css',
})
export class AccountForm implements OnInit {
  errorMessage = signal('');
  private readonly priorityCurrencyCodes = ['EUR', 'USD', 'JPY', 'GBP'];

  private readonly accountService = inject(AccountService);
  private readonly translocoService = inject(TranslocoService);
  private readonly toastService = inject(ToastService);

  account = signal<AccountOpeningBalance>({
    id: '',
    name: '',
    type: '',
    currency: '',
    openingBalance: 0,
    openingDate: toDateOnlyString(new Date()),
    openingDescription: this.translocoService.translate('accounts.openingBalanceDescription'),
    version: 0,
  });

  readonly accountTypes = [
    'Checking',
    'Savings',
    'Cash',
    'CreditCard',
    'Loan',
    'Mortgage',
    'Investment',
  ];

  readonly currencies = toSignal(
    this.accountService.getCurrencies().pipe(map((currencies) => this.sortCurrencies(currencies))),
    { initialValue: [] as Currency[] },
  );

  dialogRef = inject<DialogRef>(DialogRef);
  data = inject<Account | undefined>(DIALOG_DATA);

  ngOnInit(): void {
    if (this.data?.id) {
      firstValueFrom(this.accountService.getAccountById(this.data.id)).then((account) => {
        this.account.set({
          ...account,
          openingBalance: 0,
          openingDate: toDateOnlyString(new Date()),
          openingDescription: this.translocoService.translate('accounts.openingBalanceDescription'),
        });
      });
    }
  }

  close() {
    this.dialogRef.close();
  }

  private sortCurrencies(currencies: Currency[]): Currency[] {
    return [...currencies].sort((first, second) => {
      const firstCode = first.code.toUpperCase();
      const secondCode = second.code.toUpperCase();
      const firstPriority = this.priorityCurrencyCodes.indexOf(firstCode);
      const secondPriority = this.priorityCurrencyCodes.indexOf(secondCode);

      if (firstPriority !== -1 && secondPriority !== -1) {
        return firstPriority - secondPriority;
      }

      if (firstPriority !== -1) {
        return -1;
      }

      if (secondPriority !== -1) {
        return 1;
      }

      return first.code.localeCompare(second.code, undefined, { sensitivity: 'base' });
    });
  }

  accountForm = form(
    this.account,
    (schemaPath) => {
      maxLength(schemaPath.name, 100, { message: 'accounts.nameMaxLength' });
      required(schemaPath.name, { message: 'accounts.nameRequired' });
      required(schemaPath.type, { message: 'accounts.typeRequired' });
      maxLength(schemaPath.currency, 3, { message: 'accounts.currencyLength' });
      minLength(schemaPath.currency, 3, { message: 'accounts.currencyLength' });
      required(schemaPath.currency, { message: 'accounts.currencyRequired' });
      required(schemaPath.openingBalance, { message: 'accounts.openingBalanceRequired' });
      required(schemaPath.openingDate, { message: 'accounts.openingDateRequired' });
    },
    {
      submission: {
        action: async (field) => {
          this.errorMessage.set('');

          try {
            if (this.data?.id) {
              await firstValueFrom(this.accountService.updateAccount(field().value()));
            } else {
              var accountToCreate: AccountOpeningBalance = field().value();
              if (accountToCreate.openingBalance !== null) {
                accountToCreate.openingDescription = this.translocoService.translate(
                  'accounts.openingBalanceDescription',
                );
                accountToCreate.openingDate = toDateOnlyString(accountToCreate.openingDate);
              }

              await firstValueFrom(this.accountService.createAccount(accountToCreate));
            }
            this.toastService.success(this.translocoService.translate('accounts.saved'));
            this.dialogRef.close(true);
          } catch (err: HttpErrorResponse | any) {
            const errorCode = (err as { error: { errorCode?: string } })?.error?.errorCode;
            const key = errorCode ? errorCode : 'accounts.serverError';
            this.errorMessage.set(key);
          }
        },
      },
    },
  );
}
