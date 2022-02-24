import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GlossaryXrefComponent } from './glossary-x-ref.component';

describe('GlossaryXrefComponent', () => {
    let component: GlossaryXrefComponent;
    let fixture: ComponentFixture<GlossaryXrefComponent>;

    beforeEach(
        async(() => {
            TestBed.configureTestingModule({
                declarations: [GlossaryXrefComponent]
            }).compileComponents();
        })
    );

    beforeEach(() => {
        fixture = TestBed.createComponent(GlossaryXrefComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
