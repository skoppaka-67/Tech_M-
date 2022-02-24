import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BatchFlowComponent } from './batchflow.component';
import { BatchFlowModule } from './batchflow.module';

describe('SpiderComponent', () => {
  let component:  BatchFlowComponent;
  let fixture: ComponentFixture<BatchFlowComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BatchFlowModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BatchFlowComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
