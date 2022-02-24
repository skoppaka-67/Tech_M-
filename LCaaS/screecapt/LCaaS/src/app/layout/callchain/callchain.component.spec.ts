import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CallChainComponent } from './callchain.component';
import { CallChainModule } from './callchain.module';

describe('CallChainComponent', () => {
  let component:  CallChainComponent;
  let fixture: ComponentFixture<CallChainComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CallChainModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CallChainComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
