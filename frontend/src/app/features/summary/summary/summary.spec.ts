import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { Summary } from './summary';
import { AccountRanking } from '../account-ranking/account-ranking';
import { BalanceChart } from '../balance-chart/balance-chart';
import { CashflowChart } from '../cashflow-chart/cashflow-chart';
import { AccountService } from '@features/accounts/services/account.service';
import { SummaryService } from '../services/summary.service';

describe('Summary', () => {
  let component: Summary;
  let fixture: ComponentFixture<Summary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Summary],
      providers: [
        {
          provide: AccountService,
          useValue: {
            getAccounts: () => of([]),
            getCurrencies: () => of([]),
          },
        },
        {
          provide: SummaryService,
          useValue: {
            getMonthlyBalance: () => of({ points: [] }),
            getMonthlyCashflow: () => of({ points: [] }),
            getDailyBalance: () => of({ dailyBalance: [] }),
            getDailyCashflow: () => of({ dailyClashFlow: [] }),
          },
        },
      ],
    })
      // Stub the chart children: rendering them would instantiate EChart, which needs
      // ResizeObserver (not available in the test environment) and a canvas.
      .overrideComponent(BalanceChart, { set: { template: '', imports: [] } })
      .overrideComponent(CashflowChart, { set: { template: '', imports: [] } })
      .overrideComponent(AccountRanking, { set: { template: '', imports: [] } })
      .compileComponents();

    fixture = TestBed.createComponent(Summary);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('does not render the charts (EChart needs ResizeObserver and a canvas, unavailable in tests)', () => {
    expect(fixture.nativeElement.querySelector('app-echart')).toBeNull();
  });
});
