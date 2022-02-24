import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { MasterinvComponent } from './masterinv.component';

const routes: Routes = [
    {
        path: '', component: MasterinvComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class MasterinvRoutingModule {
}
