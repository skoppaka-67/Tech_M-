import { MissingcompModule } from './missingcomp.module';

describe('MissingcompModule', () => {
    let missingcompModule: MissingcompModule;

    beforeEach(() => {
        missingcompModule = new MissingcompModule();
    });

    it('should create an instance', () => {
        expect(missingcompModule).toBeTruthy();
    });
});
