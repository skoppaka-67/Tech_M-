import { async, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { CicsScreenAppComponent } from './cicsscreenreport-application.component';
import { CicsScreenAppModule } from './cicsscreenreport-application.module';

describe('CicsScreenAppComponent', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ CicsScreenAppModule, RouterTestingModule ],
    })
    .compileComponents();
  }));

  it('should create', () => {
    const fixture = TestBed.createComponent(CicsScreenAppComponent);
    const component = fixture.componentInstance;
    expect(component).toBeTruthy();
  });
});
