import { BrePlSqlModule } from './breplsql.module';

describe('BrePlSqlModule', () => {
  let breplsqlModule: BrePlSqlModule;

  beforeEach(() => {
    brebreplsqlModule = new BrePlSqlModule();
  });

  it('should create an instance', () => {
    expect(brebreplsqlModule).toBeTruthy();
  });
});
