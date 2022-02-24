import { OrphanAppModule } from './orphan-application.module';

describe('OrphanModule', () => {
  let orphanModule: OrphanAppModule;

  beforeEach(() => {
    orphanModule = new OrphanAppModule();
  });

  it('should create an instance', () => {
    expect(orphanModule).toBeTruthy();
  });
});
