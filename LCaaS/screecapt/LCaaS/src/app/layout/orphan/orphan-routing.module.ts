import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { OrphanComponent } from './orphan.component';

const routes: Routes = [
    {
        path: '', component: OrphanComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class OrphanRoutingModule { }
