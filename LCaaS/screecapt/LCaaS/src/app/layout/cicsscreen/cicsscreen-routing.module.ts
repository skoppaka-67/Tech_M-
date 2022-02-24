import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CicsScreenNatComponent } from './cicsscreen.component';

const routes: Routes = [
    {
        path: '', component: CicsScreenNatComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class CicsScreenNatRoutingModule {
}
