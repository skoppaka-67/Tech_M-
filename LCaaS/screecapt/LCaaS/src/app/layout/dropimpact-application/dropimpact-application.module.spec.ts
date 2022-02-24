import { DropImpactAppModule } from './dropimpact-application.module';

describe('DropImpactModule', () => {
  let dropImpactModule: DropImpactAppModule;

  beforeEach(() => {
    dropImpactModule = new DropImpactAppModule();
  });

  it('should create an instance', () => {
    expect(dropImpactModule).toBeTruthy();
  });
});
