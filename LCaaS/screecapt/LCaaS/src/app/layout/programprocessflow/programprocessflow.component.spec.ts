import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { BsComponentComponent } from './programprocessflow.component';
import { BsComponentModule } from './programprocessflow.module';

describe('BsComponentComponent', () => {
  let component: BsComponentComponent;
  let fixture: ComponentFixture<BsComponentComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [BsComponentModule, RouterTestingModule],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(BsComponentComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
