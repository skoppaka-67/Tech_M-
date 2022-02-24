import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { SpiderComponent } from './spider.component';
import { SpiderModule } from './spider.module';

describe('SpiderComponent', () => {
  let component:  SpiderComponent;
  let fixture: ComponentFixture<SpiderComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        SpiderModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SpiderComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
