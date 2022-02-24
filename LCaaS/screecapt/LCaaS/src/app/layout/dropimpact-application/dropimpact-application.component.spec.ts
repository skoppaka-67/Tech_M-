import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { DropImpactAppComponent } from './dropimpact-application.component';
import { DropImpactAppModule } from './dropimpact-application.module';

describe('DropImpactComponent', () => {
  let component: DropImpactAppComponent;
  let fixture: ComponentFixture<DropImpactAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        DropImpactAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DropImpactAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
