import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { BsComponentExtComponent } from './programprocessflow-external.component';
import { BsComponentExtModule } from './programprocessflow-external.module';

describe('BsComponentComponent', () => {
  let component: BsComponentExtComponent;
  let fixture: ComponentFixture<BsComponentExtComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [BsComponentExtModule, RouterTestingModule],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(BsComponentExtComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
