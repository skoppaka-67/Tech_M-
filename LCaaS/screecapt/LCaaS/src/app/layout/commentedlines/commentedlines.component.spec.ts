import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CommentedLinesComponent } from './commentedlines.component';
import { CommentedLinesModule } from './commentedlines.module';

describe('OrphanComponent', () => {
  let component: CommentedLinesComponent;
  let fixture: ComponentFixture<CommentedLinesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CommentedLinesModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CommentedLinesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
