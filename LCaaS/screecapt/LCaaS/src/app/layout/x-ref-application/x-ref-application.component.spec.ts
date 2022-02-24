import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { XrefApplicationComponent } from './x-ref-application.component';

describe('XrefApplicationComponent', () => {
    let component: XrefApplicationComponent;
    let fixture: ComponentFixture<XrefApplicationComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [XrefApplicationComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(XrefApplicationComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
