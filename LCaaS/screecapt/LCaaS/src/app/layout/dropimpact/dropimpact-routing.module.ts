import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DropImpactComponent } from './dropimpact.component';

const routes: Routes = [
    {
        path: '', component: DropImpactComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DropImpactRoutingModule { }
