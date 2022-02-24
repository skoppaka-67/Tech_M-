import { CicsScreenNatModule } from './cicsscreen.module';

describe('CicsScreenAppModule', () => {
  let cicsScreenAppModule: CicsScreenNatModule;

  beforeEach(() => {
    cicsScreenAppModule = new CicsScreenNatModule();
  });

  it('should create an instance', () => {
    expect(cicsScreenAppModule).toBeTruthy();
  });
});
