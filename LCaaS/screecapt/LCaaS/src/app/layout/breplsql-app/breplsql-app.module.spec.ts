import { BrePlSqlAppModule } from './breplsql-app.module';

describe('BrePlSqlModule', () => {
  let brebreplsqlModule: BrePlSqlAppModule;

  beforeEach(() => {
    brebreplsqlModule = new BrePlSqlAppModule();
  });

  it('should create an instance', () => {
    expect(brebreplsqlModule).toBeTruthy();
  });
});
