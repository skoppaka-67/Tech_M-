import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { TechSpecComponent } from './techspec.component';
import { TechSpecModule } from './techspec.module';

describe('TechSpecComponent', () => {
  let component: TechSpecComponent;
  let fixture: ComponentFixture<TechSpecComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [
          TechSpecModule,
          RouterTestingModule,
          BrowserAnimationsModule,
        ],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(TechSpecComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
