import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BrePlSqlComponent } from './breplsql.component';
import { BrePlSqlModule } from './breplsql.module';

describe('BreComponent', () => {
  let component:  BrePlSqlComponent;
  let fixture: ComponentFixture<BrePlSqlComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BrePlSqlModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BrePlSqlComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
