import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { OrphanAppComponent } from './orphan-application.component';
import { OrphanAppModule } from './orphan-application.module';

describe('OrphanComponent', () => {
  let component: OrphanAppComponent;
  let fixture: ComponentFixture<OrphanAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        OrphanAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OrphanAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
