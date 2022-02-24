import { ControlFlowModule } from './controlflow.module';

describe('SpiderModule', () => {
  let controlFlowModule: ControlFlowModule;

  beforeEach(() => {
    controlFlowModule = new ControlFlowModule();
  });

  it('should create an instance', () => {
    expect(controlFlowModule).toBeTruthy();
  });
});
