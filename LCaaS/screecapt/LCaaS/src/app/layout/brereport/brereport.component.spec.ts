import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreReportComponent } from './brereport.component';
import { BreReportModule } from './brereport.module';

describe('BreReportComponent', () => {
  let component:  BreReportComponent;
  let fixture: ComponentFixture<BreReportComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreReportModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreReportComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
