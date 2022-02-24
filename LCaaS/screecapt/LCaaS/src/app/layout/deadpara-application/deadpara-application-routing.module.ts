import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DeadparaAppComponent } from './deadpara-application.component';

const routes: Routes = [
    {
        path: '', component: DeadparaAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DeadparaAppRoutingModule { }
