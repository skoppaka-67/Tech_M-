import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { MsgLogComponent } from './msglog.component';

const routes: Routes = [
    {
        path: '',
        component: MsgLogComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class MsgLogRoutingModule {}
