import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreReportXRefComponent } from './brereport-x-ref.component';

const routes: Routes = [
    {
        path: '', component: BreReportXRefComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreReportXRefRoutingModule { }
