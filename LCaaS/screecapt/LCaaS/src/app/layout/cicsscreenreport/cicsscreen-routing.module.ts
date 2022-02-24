import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CicsScreenComponent } from './cicsscreen.component';

const routes: Routes = [
    {
        path: '', component: CicsScreenComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class CicsScreenRoutingModule {
}
