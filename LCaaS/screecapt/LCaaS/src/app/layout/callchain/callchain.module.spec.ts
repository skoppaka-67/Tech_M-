import { CallChainModule } from './callchain.module';

describe('SpiderModule', () => {
  let callChainModule: CallChainModule;

  beforeEach(() => {
    callChainModule = new CallChainModule();
  });

  it('should create an instance', () => {
    expect(callChainModule).toBeTruthy();
  });
});
