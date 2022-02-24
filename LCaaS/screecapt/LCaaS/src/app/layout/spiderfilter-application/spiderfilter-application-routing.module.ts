import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { SpiderFilterAppComponent } from './spiderfilter-application.component';

const routes: Routes = [
    {
        path: '', component: SpiderFilterAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class SpiderFilterAppRoutingModule { }
