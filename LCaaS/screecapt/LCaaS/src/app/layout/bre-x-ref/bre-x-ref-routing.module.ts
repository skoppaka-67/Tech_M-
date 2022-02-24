import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreXRefComponent } from './bre-x-ref.component';

const routes: Routes = [
    {
        path: '', component: BreXRefComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreXRefRoutingModule { }
