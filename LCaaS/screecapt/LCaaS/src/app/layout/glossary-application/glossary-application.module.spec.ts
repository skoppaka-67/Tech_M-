import { GlossaryAppModule } from './glossary-application.module';

describe('BreModule', () => {
  let glossaryModule: GlossaryAppModule;

  beforeEach(() => {
    glossaryModule = new GlossaryAppModule();
  });

  it('should create an instance', () => {
  expect(glossaryModule).toBeTruthy();
  });
});
