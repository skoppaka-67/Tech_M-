import { BreReportPlSqlAppModule } from './brereportplsql-app.module';

describe('BrePlSqlModule', () => {
  let brereportplsqlModule: BreReportPlSqlAppModule;

  beforeEach(() => {
    brereportplsqlModule = new BreReportPlSqlAppModule();
  });

  it('should create an instance', () => {
    expect(brereportplsqlModule).toBeTruthy();
  });
});
