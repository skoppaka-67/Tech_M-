import { CallChainPLSQLModule } from './callchainplsql.module';

describe('SpiderModule', () => {
  let callChainModule: CallChainPLSQLModule;

  beforeEach(() => {
    callChainModule = new CallChainPLSQLModule();
  });

  it('should create an instance', () => {
    expect(callChainModule).toBeTruthy();
  });
});
