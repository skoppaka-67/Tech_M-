import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { BrePlSqlAppComponent } from './breplsql-app.component';
import { BrePlSqlAppModule } from './breplsql-app.module';

describe('BreComponent', () => {
  let component:  BrePlSqlAppComponent;
  let fixture: ComponentFixture<BrePlSqlAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        BrePlSqlAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BrePlSqlAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
