import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CallChainAppComponent } from './callchain-application.component';

const routes: Routes = [
    {
        path: '', component: CallChainAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SpiderAppRoutingModule { }
