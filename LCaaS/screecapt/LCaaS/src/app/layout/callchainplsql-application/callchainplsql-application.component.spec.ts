import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CallChainPLSQLAppComponent } from './callchainplsql-application.component';
import { CallChainPLSQLAppModule } from './callchainplsql-application.module';

describe('CallChainComponent', () => {
  let component:  CallChainPLSQLAppComponent;
  let fixture: ComponentFixture<CallChainPLSQLAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CallChainPLSQLAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CallChainPLSQLAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
