import { CallChainAppModule } from './callchain-application.module';

describe('SpiderModule', () => {
  let callChainModule: CallChainAppModule;

  beforeEach(() => {
    callChainModule = new CallChainAppModule();
  });

  it('should create an instance', () => {
    expect(callChainModule).toBeTruthy();
  });
});
