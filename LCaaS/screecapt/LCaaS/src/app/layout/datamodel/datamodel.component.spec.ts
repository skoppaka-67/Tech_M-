import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { DatamodelComponent } from './datamodel.component';
import { DatamodelModule } from './datamodel.module';

describe('DatamodelComponent', () => {
  let component:  DatamodelComponent;
  let fixture: ComponentFixture<DatamodelComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        DatamodelModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DatamodelComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
