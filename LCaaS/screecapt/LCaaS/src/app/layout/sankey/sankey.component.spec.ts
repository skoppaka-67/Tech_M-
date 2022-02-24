import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { SankeyComponent } from './sankey.component';
import { SankeyModule } from './sankey.module';

describe('SankeyComponent', () => {
  let component: SankeyComponent;
  let fixture: ComponentFixture<SankeyComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [
          SankeyModule,
          RouterTestingModule,
          BrowserAnimationsModule,
        ],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(SankeyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
