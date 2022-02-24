import { UserGuideModule } from './userguide.module';

describe('ChartsModule', () => {
    let userGuideModule: UserGuideModule;

    beforeEach(() => {
        userGuideModule = new UserGuideModule();
    });

    it('should create an instance', () => {
        expect(UserGuideModule).toBeTruthy();
    });
});
