import { CicsRulesModule } from './cicsrules.module';

describe('CicsRulesModule', () => {
  let cicsRulesModule: CicsRulesModule;

  beforeEach(() => {
    cicsRulesModule = new CicsRulesModule();
  });

  it('should create an instance', () => {
    expect(cicsRulesModule).toBeTruthy();
  });
});
