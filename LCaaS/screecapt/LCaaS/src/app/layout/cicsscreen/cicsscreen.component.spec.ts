import { async, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { CicsScreenNatComponent } from './cicsscreen.component';
import { CicsScreenNatModule } from './cicsscreen.module';

describe('CicsScreenAppComponent', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ CicsScreenNatModule, RouterTestingModule ],
    })
    .compileComponents();
  }));

  it('should create', () => {
    const fixture = TestBed.createComponent(CicsScreenNatComponent);
    const component = fixture.componentInstance;
    expect(component).toBeTruthy();
  });
});
