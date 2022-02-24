import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { CicsRulesComponent } from './cicsrules.component';
import { CicsRulesModule } from './cicsrules.module';

describe('CicsRulesComponent', () => {
  let component:  CicsRulesComponent;
  let fixture: ComponentFixture<CicsRulesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        CicsRulesModule,
        RouterTestingModule,
        BrowserAnimationsModule,
      ],
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CicsRulesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
