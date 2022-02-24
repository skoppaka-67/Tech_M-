import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { SpiderFilterComponent } from './spiderfilter.component';
import { SpiderFilterModule } from './spiderfilter.module';

describe('SpiderComponent', () => {
  let component:  SpiderFilterComponent;
  let fixture: ComponentFixture<SpiderFilterComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        SpiderFilterModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SpiderFilterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
