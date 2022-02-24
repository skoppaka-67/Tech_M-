import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CallChainAppComponent } from './callchain-application.component';
import { CallChainAppModule } from './callchain-application.module';

describe('CallChainComponent', () => {
  let component:  CallChainAppComponent;
  let fixture: ComponentFixture<CallChainAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CallChainAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CallChainAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
