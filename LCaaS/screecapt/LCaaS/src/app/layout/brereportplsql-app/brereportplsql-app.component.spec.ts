import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreReportPlSqlAppComponent } from './brereportplsql-app.component';
import { BreReportPlSqlAppModule } from './brereportplsql-app.module';

describe('BreComponent', () => {
  let component:  BreReportPlSqlAppComponent;
  let fixture: ComponentFixture<BreReportPlSqlAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreReportPlSqlAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreReportPlSqlAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
