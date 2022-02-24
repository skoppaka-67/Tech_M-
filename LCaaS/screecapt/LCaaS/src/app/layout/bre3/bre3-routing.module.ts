import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { Bre3Component } from './bre3.component';

const routes: Routes = [
    {
        path: '',
        component: Bre3Component
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class Bre3RoutingModule {}
