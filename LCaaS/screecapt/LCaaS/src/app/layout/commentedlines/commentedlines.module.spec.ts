import { CommentedLinesModule } from './commentedlines.module';

describe('OrphanModule', () => {
  let commentedLinesModule: CommentedLinesModule;

  beforeEach(() => {
    commentedLinesModule = new CommentedLinesModule();
  });

  it('should create an instance', () => {
    expect(commentedLinesModule).toBeTruthy();
  });
});
