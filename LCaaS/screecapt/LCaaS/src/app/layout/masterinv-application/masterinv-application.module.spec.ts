import { MasterinvAppModule } from './masterinv-application.module';

describe('MasterinvModule', () => {
  let masterinvAppModule: MasterinvAppModule;

  beforeEach(() => {
    masterinvAppModule = new MasterinvAppModule();
  });

  it('should create an instance', () => {
    expect(masterinvAppModule).toBeTruthy();
  });
});
