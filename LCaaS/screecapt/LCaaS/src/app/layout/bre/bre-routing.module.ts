import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreComponent } from './bre.component';

const routes: Routes = [
    {
        path: '', component: BreComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreRoutingModule { }
