import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CallChainPLSQLComponent } from './callchainplsql.component';

const routes: Routes = [
    {
        path: '', component: CallChainPLSQLComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CallChainPLSQLRoutingModule { }
