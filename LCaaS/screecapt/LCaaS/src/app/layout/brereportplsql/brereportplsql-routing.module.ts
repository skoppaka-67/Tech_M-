import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreReportPlSqlComponent } from './brereportplsql.component';

const routes: Routes = [
    {
        path: '', component: BreReportPlSqlComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreReportPlSqlRoutingModule { }
