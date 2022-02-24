import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { XrefComponent } from './x-ref.component';

describe('XrefComponent', () => {
    let component: XrefComponent;
    let fixture: ComponentFixture<XrefComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [XrefComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(XrefComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
