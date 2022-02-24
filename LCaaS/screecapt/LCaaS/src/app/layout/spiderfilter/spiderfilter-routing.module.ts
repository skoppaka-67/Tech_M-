import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { SpiderFilterComponent } from './spiderfilter.component';

const routes: Routes = [
    {
        path: '', component: SpiderFilterComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SpiderFilterRoutingModule { }
