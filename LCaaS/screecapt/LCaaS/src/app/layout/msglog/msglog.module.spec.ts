import { MsgLogModule } from './msglog.module';

describe('MsgLogModule', () => {
    let msgLogModule: MsgLogModule;

    beforeEach(() => {
        msgLogModule = new MsgLogModule();
    });

    it('should create an instance', () => {
        expect(msgLogModule).toBeTruthy();
    });
});
