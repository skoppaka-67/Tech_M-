import { GlossaryModule } from './glossary.module';

describe('BreModule', () => {
  let glossaryModule: GlossaryModule;

  beforeEach(() => {
    glossaryModule = new GlossaryModule();
  });

  it('should create an instance', () => {
  expect(glossaryModule).toBeTruthy();
  });
});
