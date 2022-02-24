import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CommentedLinesAppComponent } from './commentedlines-application.component';
import { CommentedLinesAppModule } from './commentedlines-application.module';

describe('OrphanComponent', () => {
  let component: CommentedLinesAppComponent;
  let fixture: ComponentFixture<CommentedLinesAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CommentedLinesAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CommentedLinesAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
