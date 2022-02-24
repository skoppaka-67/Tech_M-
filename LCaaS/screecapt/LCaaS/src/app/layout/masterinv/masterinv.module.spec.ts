import { MasterinvModule } from './masterinv.module';

describe('MasterinvModule', () => {
  let masterinvModule: MasterinvModule;

  beforeEach(() => {
    masterinvModule = new MasterinvModule();
  });

  it('should create an instance', () => {
    expect(masterinvModule).toBeTruthy();
  });
});
