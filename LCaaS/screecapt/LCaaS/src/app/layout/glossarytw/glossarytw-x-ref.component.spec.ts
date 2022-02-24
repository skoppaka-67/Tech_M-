import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GlossaryTWXrefComponent } from './glossarytw-x-ref.component';

describe('GlossaryTWXrefComponent', () => {
    let component: GlossaryTWXrefComponent;
    let fixture: ComponentFixture<GlossaryTWXrefComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [GlossaryTWXrefComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(GlossaryTWXrefComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
