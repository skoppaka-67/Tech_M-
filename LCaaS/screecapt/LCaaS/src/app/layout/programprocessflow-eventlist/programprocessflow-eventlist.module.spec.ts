import { BsComponentEventModule } from './programprocessflow-eventlist.module';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';

describe('BsComponentModule', () => {
    let bsComponentModule: BsComponentEventModule;

    beforeEach(() => {
        bsComponentModule = new BsComponentEventModule();
    });

    it('should create an instance', () => {
        expect(bsComponentModule).toBeTruthy();
    });
});
