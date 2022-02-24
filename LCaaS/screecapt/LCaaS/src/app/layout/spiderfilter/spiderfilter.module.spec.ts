import { SpiderFilterModule } from './spiderfilter.module';

describe('SpiderModule', () => {
  let spiderFilterModule: SpiderFilterModule;

  beforeEach(() => {
    spiderFilterModule = new SpiderFilterModule();
  });

  it('should create an instance', () => {
    expect(spiderFilterModule).toBeTruthy();
  });
});
