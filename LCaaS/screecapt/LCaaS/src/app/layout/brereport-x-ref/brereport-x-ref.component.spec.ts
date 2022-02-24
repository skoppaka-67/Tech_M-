import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreReportXRefComponent } from './brereport-x-ref.component';
import { BreReportXRefModule } from './brereport-x-ref.module';

describe('BreReportComponent', () => {
  let component:  BreReportXRefComponent;
  let fixture: ComponentFixture<BreReportXRefComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreReportXRefModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreReportXRefComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
