import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreXRefComponent } from './bre-x-ref.component';
import { BreXRefModule } from './bre-x-ref.module';

describe('BreComponent', () => {
  let component:  BreXRefComponent;
  let fixture: ComponentFixture<BreXRefComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreXRefModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreXRefComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
