import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { DeadparaAppComponent } from './deadpara-application.component';
import { DeadparaAppModule } from './deadpara-application.module';

describe('DeadparaComponent', () => {
  let component:  DeadparaAppComponent;
  let fixture: ComponentFixture<DeadparaAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        DeadparaAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DeadparaAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
