import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { UserGuideComponent } from './userguide.component';
import { UserGuideModule } from './userguide.module';

describe('UserGuideComponent', () => {
  let component: UserGuideComponent;
  let fixture: ComponentFixture<UserGuideComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [
          UserGuideModule,
          RouterTestingModule,
          BrowserAnimationsModule,
        ],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(UserGuideComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
