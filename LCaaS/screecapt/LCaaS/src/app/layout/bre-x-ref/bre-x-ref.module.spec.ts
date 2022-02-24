import { BreXRefModule } from './bre-x-ref.module';

describe('BreModule', () => {
  let breModule: BreXRefModule;

  beforeEach(() => {
    breModule = new BreXRefModule();
  });

  it('should create an instance', () => {
    expect(breModule).toBeTruthy();
  });
});
