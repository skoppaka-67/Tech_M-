import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { ImpactComponent } from './impact.component';

const routes: Routes = [
    {
        path: '',
        component: ImpactComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class ImpactRoutingModule {}
