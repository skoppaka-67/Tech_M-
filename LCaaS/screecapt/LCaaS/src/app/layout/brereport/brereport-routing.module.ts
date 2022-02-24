import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreReportComponent } from './brereport.component';

const routes: Routes = [
    {
        path: '', component: BreReportComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreReportRoutingModule { }
