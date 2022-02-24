import { DeadparaAppModule } from './deadpara-application.module';

describe('DeadparaModule', () => {
  let deadparaModule: DeadparaAppModule;

  beforeEach(() => {
    deadparaModule = new DeadparaAppModule();
  });

  it('should create an instance', () => {
    expect(deadparaModule).toBeTruthy();
  });
});
