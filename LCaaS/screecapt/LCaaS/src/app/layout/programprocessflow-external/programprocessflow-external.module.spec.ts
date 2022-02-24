import { BsComponentExtModule } from './programprocessflow-external.module';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';

describe('BsComponentModule', () => {
    let bsComponentModule: BsComponentExtModule;

    beforeEach(() => {
        bsComponentModule = new BsComponentExtModule();
    });

    it('should create an instance', () => {
        expect(bsComponentModule).toBeTruthy();
    });
});
