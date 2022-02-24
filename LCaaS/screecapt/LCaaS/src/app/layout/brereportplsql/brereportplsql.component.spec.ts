import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreReportPlSqlComponent } from './brereportplsql.component';
import { BreReportPlSqlModule } from './brereportplsql.module';

describe('BreComponent', () => {
  let component:  BreReportPlSqlComponent;
  let fixture: ComponentFixture<BreReportPlSqlComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreReportPlSqlModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreReportPlSqlComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
