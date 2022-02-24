import { BreModule } from './bre.module';

describe('BreModule', () => {
  let breModule: BreModule;

  beforeEach(() => {
    breModule = new BreModule();
  });

  it('should create an instance', () => {
    expect(breModule).toBeTruthy();
  });
});
