import { OrphanModule } from './orphan.module';

describe('OrphanModule', () => {
  let orphanModule: OrphanModule;

  beforeEach(() => {
    orphanModule = new OrphanModule();
  });

  it('should create an instance', () => {
    expect(orphanModule).toBeTruthy();
  });
});
