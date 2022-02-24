import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { DeadparaComponent } from './deadpara.component';
import { DeadparaModule } from './deadpara.module';

describe('DeadparaComponent', () => {
  let component:  DeadparaComponent;
  let fixture: ComponentFixture<DeadparaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        DeadparaModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DeadparaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
