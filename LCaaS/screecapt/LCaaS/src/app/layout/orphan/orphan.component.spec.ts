import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { OrphanComponent } from './orphan.component';
import { OrphanModule } from './orphan.module';

describe('OrphanComponent', () => {
  let component: OrphanComponent;
  let fixture: ComponentFixture<OrphanComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        OrphanModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OrphanComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
