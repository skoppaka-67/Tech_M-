import { async, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { CicsScreenComponent } from './cicsscreen.component';
import { CicsScreenModule } from './cicsscreen.module';

describe('CicsScreenComponent', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ CicsScreenModule, RouterTestingModule ],
    })
    .compileComponents();
  }));

  it('should create', () => {
    const fixture = TestBed.createComponent(CicsScreenComponent);
    const component = fixture.componentInstance;
    expect(component).toBeTruthy();
  });
});
