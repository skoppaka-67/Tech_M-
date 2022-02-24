import { CicsScreenAppModule } from './cicsscreenreport-application.module';

describe('CicsScreenAppModule', () => {
  let cicsScreenAppModule: CicsScreenAppModule;

  beforeEach(() => {
    cicsScreenAppModule = new CicsScreenAppModule();
  });

  it('should create an instance', () => {
    expect(cicsScreenAppModule).toBeTruthy();
  });
});
