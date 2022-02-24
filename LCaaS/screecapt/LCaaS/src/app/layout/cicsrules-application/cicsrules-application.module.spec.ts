import { CicsRulesAppModule } from './cicsrules-application.module';

describe('CicsRulesAppModule', () => {
  let cicsRulesModule: CicsRulesAppModule;

  beforeEach(() => {
    cicsRulesModule = new CicsRulesAppModule();
  });

  it('should create an instance', () => {
    expect(cicsRulesModule).toBeTruthy();
  });
});
