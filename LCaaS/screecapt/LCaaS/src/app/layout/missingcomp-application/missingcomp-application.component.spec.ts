import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { MissingcompAppComponent } from './missingcomp-application.component';
import { MissingcompAppModule } from './missingcomp-application.module';

describe('MissingcompComponent', () => {
  let component: MissingcompAppComponent;
  let fixture: ComponentFixture<MissingcompAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [MissingcompAppModule, RouterTestingModule, BrowserAnimationsModule]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MissingcompAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
