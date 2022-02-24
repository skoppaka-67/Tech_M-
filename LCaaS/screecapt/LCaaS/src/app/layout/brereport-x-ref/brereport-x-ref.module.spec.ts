import { BreReportXRefModule } from './brereport-x-ref.module';

describe('BreModule', () => {
  let breReportModule: BreReportXRefModule;

  beforeEach(() => {
    breReportModule = new BreReportXRefModule();
  });

  it('should create an instance', () => {
    expect(breReportModule).toBeTruthy();
  });
});
