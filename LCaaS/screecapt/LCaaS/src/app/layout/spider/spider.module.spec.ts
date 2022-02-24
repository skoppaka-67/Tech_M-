import { SpiderModule } from './spider.module';

describe('SpiderModule', () => {
  let spiderModule: SpiderModule;

  beforeEach(() => {
    spiderModule = new SpiderModule();
  });

  it('should create an instance', () => {
    expect(spiderModule).toBeTruthy();
  });
});
