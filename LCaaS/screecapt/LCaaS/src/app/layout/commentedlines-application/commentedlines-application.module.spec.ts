import { CommentedLinesAppModule } from './commentedlines-application.module';

describe('OrphanModule', () => {
  let commentedLinesModule: CommentedLinesAppModule;

  beforeEach(() => {
    commentedLinesModule = new CommentedLinesAppModule();
  });

  it('should create an instance', () => {
    expect(commentedLinesModule).toBeTruthy();
  });
});
