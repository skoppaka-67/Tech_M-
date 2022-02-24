import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { OrphanAppComponent } from './orphan-application.component';

const routes: Routes = [
    {
        path: '', component: OrphanAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class OrphanAppRoutingModule { }
