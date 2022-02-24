import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { ControlFlowComponent } from './controlflow.component';
import { ControlFlowModule } from './controlflow.module';

describe('SpiderComponent', () => {
  let component:  ControlFlowComponent;
  let fixture: ComponentFixture<ControlFlowComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        ControlFlowModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ControlFlowComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
