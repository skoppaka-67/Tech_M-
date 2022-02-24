import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BrePlSqlComponent } from './breplsql.component';

const routes: Routes = [
    {
        path: '', component: BrePlSqlComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BrePlSqlRoutingModule { }
