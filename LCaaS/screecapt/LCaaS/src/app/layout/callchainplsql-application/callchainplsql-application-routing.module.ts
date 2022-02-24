import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CallChainPLSQLAppComponent } from './callchainplsql-application.component';

const routes: Routes = [
    {
        path: '', component: CallChainPLSQLAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CallChainPLSQLAppRoutingModule { }
