import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DeadparaComponent } from './deadpara.component';

const routes: Routes = [
    {
        path: '', component: DeadparaComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DeadparaRoutingModule { }
