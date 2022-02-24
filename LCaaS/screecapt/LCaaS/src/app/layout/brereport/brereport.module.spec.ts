import { BreReportModule } from './brereport.module';

describe('BreModule', () => {
  let breReportModule: BreReportModule;

  beforeEach(() => {
    breReportModule = new BreReportModule();
  });

  it('should create an instance', () => {
    expect(breReportModule).toBeTruthy();
  });
});
