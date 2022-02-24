import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CallChainFilterComponent } from './callchainfilter.component';

const routes: Routes = [
    {
        path: '', component: CallChainFilterComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CallChainFilterRoutingModule { }
