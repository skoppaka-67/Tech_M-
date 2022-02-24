import { SankeyModule } from './sankey.module';

describe('SankeyModule', () => {
    let sankeyModule: SankeyModule;

    beforeEach(() => {
        sankeyModule = new SankeyModule();
    });

    it('should create an instance', () => {
        expect(sankeyModule).toBeTruthy();
    });
});
