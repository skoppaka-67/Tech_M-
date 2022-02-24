import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BreComponent } from './bre.component';
import { BreModule } from './bre.module';

describe('BreComponent', () => {
  let component:  BreComponent;
  let fixture: ComponentFixture<BreComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BreModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BreComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
