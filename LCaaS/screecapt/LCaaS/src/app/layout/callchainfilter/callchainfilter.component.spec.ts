import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CallChainFilterComponent } from './callchainfilter.component';
import { CallChainFilterModule } from './callchainfilter.module';

describe('CallChainComponent', () => {
  let component:  CallChainFilterComponent;
  let fixture: ComponentFixture<CallChainFilterComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CallChainFilterModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CallChainFilterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
