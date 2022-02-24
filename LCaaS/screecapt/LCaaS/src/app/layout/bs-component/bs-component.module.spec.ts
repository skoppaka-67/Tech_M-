import { BsComponentModule } from './bs-component.module';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';

describe('BsComponentModule', () => {
    let bsComponentModule: BsComponentModule;

    beforeEach(() => {
        bsComponentModule = new BsComponentModule();
    });

    it('should create an instance', () => {
        expect(bsComponentModule).toBeTruthy();
    });
});
