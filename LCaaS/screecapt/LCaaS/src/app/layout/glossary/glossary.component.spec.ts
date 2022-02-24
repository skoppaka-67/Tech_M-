import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { GlossaryComponent } from './glossary.component';
import { GlossaryModule } from './glossary.module';

describe('BreReportComponent', () => {
  let component:  GlossaryComponent;
  let fixture: ComponentFixture<GlossaryComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        GlossaryModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GlossaryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
