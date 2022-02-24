import { DatamodelModule } from './datamodel.module';

describe('DeadparaModule', () => {
  let datamodelModule: DatamodelModule;

  beforeEach(() => {
    datamodelModule = new DatamodelModule();
  });

  it('should create an instance', () => {
    expect(datamodelModule).toBeTruthy();
  });
});
