import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { SpiderFilterAppComponent } from './spiderfilter-application.component';
import { SpiderFilterAppModule } from './spiderfilter-application.module';

describe('SpiderComponent', () => {
  let component:  SpiderFilterAppComponent;
  let fixture: ComponentFixture<SpiderFilterAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        SpiderFilterAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SpiderFilterAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
