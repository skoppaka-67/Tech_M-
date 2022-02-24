import { FormAppModule } from './form-application.module';

describe('FormModule', () => {
    let formModule: FormAppModule;

    beforeEach(() => {
        formModule = new FormAppModule();
    });

    it('should create an instance', () => {
        expect(formModule).toBeTruthy();
    });
});
