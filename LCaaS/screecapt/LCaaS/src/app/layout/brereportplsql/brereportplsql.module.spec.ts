import { BreReportPlSqlModule } from './brereportplsql.module';

describe('BrePlSqlModule', () => {
  let brereportplsqlModule: BreReportPlSqlModule;

  beforeEach(() => {
    brereportplsqlModule = new BreReportPlSqlModule();
  });

  it('should create an instance', () => {
    expect(brereportplsqlModule).toBeTruthy();
  });
});
