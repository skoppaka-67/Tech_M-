import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CallChainComponent } from './callchain.component';

const routes: Routes = [
    {
        path: '', component: CallChainComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SpiderRoutingModule { }
