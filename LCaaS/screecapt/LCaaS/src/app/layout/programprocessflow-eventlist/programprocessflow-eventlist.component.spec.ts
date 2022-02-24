import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';

import { BsComponentEventComponent } from './programprocessflow-eventlist.component';
import { BsComponentEventModule } from './programprocessflow-eventlist.module';

describe('BsComponentComponent', () => {
  let component: BsComponentEventComponent;
  let fixture: ComponentFixture<BsComponentEventComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [BsComponentEventModule, RouterTestingModule],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(BsComponentEventComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
