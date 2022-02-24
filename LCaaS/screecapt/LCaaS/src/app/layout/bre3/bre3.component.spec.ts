import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { Bre3Component } from './bre3.component';

describe('XrefApplicationComponent', () => {
    let component: Bre3Component;
    let fixture: ComponentFixture<Bre3Component>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [Bre3Component]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(Bre3Component);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
