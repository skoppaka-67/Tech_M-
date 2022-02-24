import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { ProgressComponent } from './progress.component';
import { ProgressModule } from './progress.module';

describe('ProgressComponent', () => {
  let component:  ProgressComponent;
  let fixture: ComponentFixture<ProgressComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        ProgressModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ProgressComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
