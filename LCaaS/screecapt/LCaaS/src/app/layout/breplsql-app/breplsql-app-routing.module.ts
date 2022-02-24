import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BrePlSqlAppComponent } from './breplsql-app.component';

const routes: Routes = [
    {
        path: '', component: BrePlSqlAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BrePlSqlRoutingAppModule { }
