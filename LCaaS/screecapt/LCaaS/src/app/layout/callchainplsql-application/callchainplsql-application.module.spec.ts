import { CallChainPLSQLAppModule } from './callchainplsql-application.module';

describe('SpiderModule', () => {
  let callChainModule: CallChainPLSQLAppModule;

  beforeEach(() => {
    callChainModule = new CallChainPLSQLAppModule();
  });

  it('should create an instance', () => {
    expect(callChainModule).toBeTruthy();
  });
});
