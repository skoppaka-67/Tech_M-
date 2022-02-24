import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CICSXrefComponent } from './cics-x-ref.component';

describe('CICSXrefComponent', () => {
    let component: CICSXrefComponent;
    let fixture: ComponentFixture<CICSXrefComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [CICSXrefComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(CICSXrefComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
