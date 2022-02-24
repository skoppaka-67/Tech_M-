import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { ControlFlowAppComponent } from './controlflow-application.component';
import { ControlFlowAppModule } from './controlflow-application.module';

describe('SpiderComponent', () => {
  let component:  ControlFlowAppComponent;
  let fixture: ComponentFixture<ControlFlowAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        ControlFlowAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ControlFlowAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
