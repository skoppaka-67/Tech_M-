import { SpiderFilterAppModule } from './spiderfilter-application.module';

describe('SpiderModule', () => {
  let spiderFilterModule: SpiderFilterAppModule;

  beforeEach(() => {
    spiderFilterModule = new SpiderFilterAppModule();
  });

  it('should create an instance', () => {
    expect(spiderFilterModule).toBeTruthy();
  });
});
