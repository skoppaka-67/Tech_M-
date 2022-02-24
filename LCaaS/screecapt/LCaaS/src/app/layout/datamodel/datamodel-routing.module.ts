import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DatamodelComponent } from './datamodel.component';

const routes: Routes = [
    {
        path: '', component: DatamodelComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DatamodelRoutingModule { }
