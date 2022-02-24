import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { GlossaryAppComponent } from './glossary-application.component';
import { GlossaryAppModule } from './glossary-application.module';

describe('BreReportComponent', () => {
  let component:  GlossaryAppComponent;
  let fixture: ComponentFixture<GlossaryAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        GlossaryAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GlossaryAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
