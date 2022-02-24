import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { TechSpecComponent } from './techspec.component';

const routes: Routes = [
    {
        path: '',
        component: TechSpecComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class TechSpecRoutingModule {}
