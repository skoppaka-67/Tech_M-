import { TechSpecModule } from './techspec.module';

describe('TechSpecModule', () => {
    let techSpecModule: TechSpecModule;

    beforeEach(() => {
        techSpecModule = new TechSpecModule();
    });

    it('should create an instance', () => {
        expect(TechSpecModule).toBeTruthy();
    });
});
