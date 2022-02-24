import { CallChainFilterModule } from './callchainfilter.module';

describe('SpiderModule', () => {
  let callChainFilterModule: CallChainFilterModule;

  beforeEach(() => {
    callChainFilterModule = new CallChainFilterModule();
  });

  it('should create an instance', () => {
    expect(callChainFilterModule).toBeTruthy();
  });
});
