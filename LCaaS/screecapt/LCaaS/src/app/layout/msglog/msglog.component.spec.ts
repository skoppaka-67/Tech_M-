import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { MsgLogComponent } from './msglog.component';
import { MsgLogModule } from './msglog.module';

describe('MsgLogComponent', () => {
  let component: MsgLogComponent;
  let fixture: ComponentFixture<MsgLogComponent>;

  beforeEach(
    async(() => {
      TestBed.configureTestingModule({
        imports: [
          MsgLogModule,
          RouterTestingModule,
          BrowserAnimationsModule,
        ],
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(MsgLogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
