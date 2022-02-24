import { DropImpactModule } from './dropimpact.module';

describe('DropImpactModule', () => {
  let dropImpactModule: DropImpactModule;

  beforeEach(() => {
    dropImpactModule = new DropImpactModule();
  });

  it('should create an instance', () => {
    expect(dropImpactModule).toBeTruthy();
  });
});
