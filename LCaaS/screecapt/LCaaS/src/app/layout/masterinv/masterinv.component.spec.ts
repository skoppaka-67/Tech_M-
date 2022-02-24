import { async, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { MasterinvComponent } from './masterinv.component';
import { MasterinvModule } from './masterinv.module';

describe('MasterinvComponent', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ MasterinvModule, RouterTestingModule ],
    })
    .compileComponents();
  }));

  it('should create', () => {
    const fixture = TestBed.createComponent(MasterinvComponent);
    const component = fixture.componentInstance;
    expect(component).toBeTruthy();
  });
});
