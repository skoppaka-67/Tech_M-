import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { MissingcompComponent } from './missingcomp.component';
import { MissingcompModule } from './missingcomp.module';

describe('MissingcompComponent', () => {
  let component: MissingcompComponent;
  let fixture: ComponentFixture<MissingcompComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [MissingcompModule, RouterTestingModule, BrowserAnimationsModule]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MissingcompComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
