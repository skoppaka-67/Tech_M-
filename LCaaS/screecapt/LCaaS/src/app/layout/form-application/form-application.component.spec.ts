import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { FormAppComponent } from './form-application.component';
import { FormAppModule } from './form-application.module';

describe('FormComponent', () => {
  let component: FormAppComponent;
  let fixture: ComponentFixture<FormAppComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [
          FormAppModule,
          BrowserAnimationsModule,
          RouterTestingModule,
         ],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(FormAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
