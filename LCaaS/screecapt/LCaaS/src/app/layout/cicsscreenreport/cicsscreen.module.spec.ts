import { CicsScreenModule } from './cicsscreen.module';

describe('CicsScreenModule', () => {
  let cicsScreenModule: CicsScreenModule;

  beforeEach(() => {
    cicsScreenModule = new CicsScreenModule();
  });

  it('should create an instance', () => {
    expect(cicsScreenModule).toBeTruthy();
  });
});
