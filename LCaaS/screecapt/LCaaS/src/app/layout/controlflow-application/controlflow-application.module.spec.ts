import { ControlFlowAppModule } from './controlflow-application.module';

describe('SpiderModule', () => {
  let controlFlowModule: ControlFlowAppModule;

  beforeEach(() => {
    controlFlowModule = new ControlFlowAppModule();
  });

  it('should create an instance', () => {
    expect(controlFlowModule).toBeTruthy();
  });
});
