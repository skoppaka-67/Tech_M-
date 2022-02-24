import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { DropImpactComponent } from './dropimpact.component';
import { DropImpactModule } from './dropimpact.module';

describe('DropImpactComponent', () => {
  let component: DropImpactComponent;
  let fixture: ComponentFixture<DropImpactComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        DropImpactModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DropImpactComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
