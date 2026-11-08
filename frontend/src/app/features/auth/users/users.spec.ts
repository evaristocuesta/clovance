import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { Users } from './users';
import { AuthService } from '@core/services/auth.service';

describe('Users', () => {
  let component: Users;
  let fixture: ComponentFixture<Users>;
  let getUsers: ReturnType<typeof vi.fn>;

  beforeEach(async () => {
    getUsers = vi.fn(() => of([]));

    await TestBed.configureTestingModule({
      imports: [Users],
      providers: [
        {
          provide: AuthService,
          useValue: {
            getUsers,
            getCurrentUser: () => null,
            deleteUser: () => of(void 0),
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(Users);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('loads users through the AuthService stub instead of the network', () => {
    expect(getUsers).toHaveBeenCalledTimes(1);
  });
});
