import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BreReportPlSqlAppComponent } from './brereportplsql-app.component';

const routes: Routes = [
    {
        path: '', component: BreReportPlSqlAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BreReportPlSqlAppRoutingModule { }
