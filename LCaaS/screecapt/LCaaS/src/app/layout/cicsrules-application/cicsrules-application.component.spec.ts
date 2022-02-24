import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CicsRulesAppComponent } from './cicsrules-application.component';
import { CicsRulesAppModule } from './cicsrules-application.module';

describe('CicsRulesComponent', () => {
  let component:  CicsRulesAppComponent;
  let fixture: ComponentFixture<CicsRulesAppComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CicsRulesAppModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CicsRulesAppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
