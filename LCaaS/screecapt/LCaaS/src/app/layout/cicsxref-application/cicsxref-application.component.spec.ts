import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CICSXrefAppComponent } from './cicsxref-application.component';

describe('CICSXrefAppComponent', () => {
    let component: CICSXrefAppComponent;
    let fixture: ComponentFixture<CICSXrefAppComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [CICSXrefAppComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(CICSXrefAppComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
