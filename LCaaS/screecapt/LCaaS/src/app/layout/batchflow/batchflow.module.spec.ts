import { BatchFlowModule } from './batchflow.module';

describe('SpiderModule', () => {
  let batchFlowModule: BatchFlowModule;

  beforeEach(() => {
    batchFlowModule = new BatchFlowModule();
  });

  it('should create an instance', () => {
    expect(batchFlowModule).toBeTruthy();
  });
});
