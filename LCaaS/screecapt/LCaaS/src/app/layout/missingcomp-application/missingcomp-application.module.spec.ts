import { MissingcompAppModule } from './missingcomp-application.module';

describe('MissingcompModule', () => {
    let missingcompModule: MissingcompAppModule;

    beforeEach(() => {
        missingcompModule = new MissingcompAppModule();
    });

    it('should create an instance', () => {
        expect(missingcompModule).toBeTruthy();
    });
});
