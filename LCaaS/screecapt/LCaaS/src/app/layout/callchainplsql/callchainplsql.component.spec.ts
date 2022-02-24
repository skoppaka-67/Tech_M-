import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CallChainPLSQLComponent } from './callchainplsql.component';
import { CallChainPLSQLModule } from './callchainplsql.module';

describe('CallChainComponent', () => {
  let component:  CallChainPLSQLComponent;
  let fixture: ComponentFixture<CallChainPLSQLComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CallChainPLSQLModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CallChainPLSQLComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
