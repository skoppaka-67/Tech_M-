import { DeadparaModule } from './deadpara.module';

describe('DeadparaModule', () => {
  let deadparaModule: DeadparaModule;

  beforeEach(() => {
    deadparaModule = new DeadparaModule();
  });

  it('should create an instance', () => {
    expect(deadparaModule).toBeTruthy();
  });
});
