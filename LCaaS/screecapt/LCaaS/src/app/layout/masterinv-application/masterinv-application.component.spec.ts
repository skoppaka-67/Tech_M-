import { async, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { MasterinvAppComponent } from './masterinv-application.component';
import { MasterinvAppModule } from './masterinv-application.module';

describe('MasterinvComponent', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ MasterinvAppModule, RouterTestingModule ],
    })
    .compileComponents();
  }));

  it('should create', () => {
    const fixture = TestBed.createComponent(MasterinvAppComponent);
    const component = fixture.componentInstance;
    expect(component).toBeTruthy();
  });
});
