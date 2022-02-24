import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BatchFlowComponent } from './batchflow.component';

const routes: Routes = [
    {
        path: '', component: BatchFlowComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BatchFlowRoutingModule { }
